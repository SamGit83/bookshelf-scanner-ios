import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI

/**
 * FeedbackManager - Central service for survey lifecycle management
 *
 * Manages the creation, scheduling, triggering, and completion of user feedback surveys.
 * Integrates with AnalyticsManager for event tracking and ABTestingService for variant-specific feedback.
 */
class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var surveyQueue: [Survey] = []
    private var activeSurvey: Survey?

    // Published properties for SwiftUI integration
    @Published var shouldShowSurvey = false
    @Published var currentSurvey: Survey?

    private init() {
        setupSurveyTriggers()
        loadPendingSurveys()
    }

    // MARK: - Survey Types and Triggers

    enum SurveyType: String, Codable {
        case onboarding = "onboarding"
        case usageLimit = "usage_limit"
        case pricingValue = "pricing_value"
        case featureRequest = "feature_request"
        case nps = "nps"
        case exitCancellation = "exit_cancellation"
    }

    enum SurveyTrigger: String, Codable {
        case appLaunch = "app_launch"
        case onboardingComplete = "onboarding_complete"
        case limitHit = "limit_hit"
        case upgradePromptShown = "upgrade_prompt_shown"
        case featureUsage = "feature_usage"
        case sessionEnd = "session_end"
        case appBackground = "app_background"
        case timeBased = "time_based"
    }

    // MARK: - Survey Management

    func triggerSurvey(type: SurveyType, context: [String: Any] = [:]) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Check if survey should be shown based on user state and history
        guard await shouldShowSurvey(type: type, userId: userId, context: context) else { return }

        // Create or retrieve survey
        let survey = await createSurvey(type: type, userId: userId, context: context)

        // Check A/B testing variant
        if let variantSurvey = await applyABTestingVariant(survey: survey, userId: userId) {
            await MainActor.run {
                self.currentSurvey = variantSurvey
                self.shouldShowSurvey = true
            }

            // Track survey shown
            AnalyticsManager.shared.trackFeatureUsage(feature: "survey_shown", context: type.rawValue)
        }
    }

    private func shouldShowSurvey(type: SurveyType, userId: String, context: [String: Any]) async -> Bool {
        // Check if user has already completed this survey type recently
        let lastCompletion = await getLastSurveyCompletion(type: type, userId: userId)
        let cooldownPeriod = getCooldownPeriod(for: type)

        if let lastCompletion = lastCompletion,
           Date().timeIntervalSince(lastCompletion) < cooldownPeriod {
            return false
        }

        // Check user eligibility based on survey type
        switch type {
        case .onboarding:
            return await checkOnboardingEligibility(userId: userId)
        case .usageLimit:
            return await checkUsageLimitEligibility(userId: userId, context: context)
        case .pricingValue:
            return await checkPricingValueEligibility(userId: userId)
        case .featureRequest:
            return await checkFeatureRequestEligibility(userId: userId)
        case .nps:
            return await checkNPSEligibility(userId: userId)
        case .exitCancellation:
            return await checkExitCancellationEligibility(userId: userId, context: context)
        }
    }

    private func getCooldownPeriod(for type: SurveyType) -> TimeInterval {
        switch type {
        case .onboarding: return 0 // Only once
        case .usageLimit: return 30 * 24 * 3600 // 30 days
        case .pricingValue: return 90 * 24 * 3600 // 90 days
        case .featureRequest: return 14 * 24 * 3600 // 14 days
        case .nps: return 60 * 24 * 3600 // 60 days
        case .exitCancellation: return 0 // Only on cancellation attempt
        }
    }

    // MARK: - Eligibility Checks

    private func checkOnboardingEligibility(userId: String) async -> Bool {
        guard let user = AuthService.shared.currentUser else { return false }
        return !user.hasCompletedOnboarding
    }

    private func checkUsageLimitEligibility(userId: String, context: [String: Any]) async -> Bool {
        guard let limitType = context["limit_type"] as? String else { return false }
        // Only show after hitting limit multiple times or based on usage patterns
        let limitHits = await getLimitHitCount(userId: userId, limitType: limitType)
        return limitHits >= 2 // Show after 2nd limit hit
    }

    private func checkPricingValueEligibility(userId: String) async -> Bool {
        guard let user = AuthService.shared.currentUser else { return false }
        return user.tier == .free // Only for free users
    }

    private func checkFeatureRequestEligibility(userId: String) async -> Bool {
        // Show to engaged users who have used multiple features
        let featureUsageCount = await getFeatureUsageCount(userId: userId)
        return featureUsageCount >= 3
    }

    private func checkNPSEligibility(userId: String) async -> Bool {
        // Show to users who have been active for at least 7 days
        guard let user = AuthService.shared.currentUser,
              let creationDate = user.creationDate else { return false }
        let daysSinceSignup = Date().timeIntervalSince(creationDate) / (24 * 3600)
        return daysSinceSignup >= 7
    }

    private func checkExitCancellationEligibility(userId: String, context: [String: Any]) async -> Bool {
        // Only show during cancellation flow
        return context["is_cancellation_flow"] as? Bool == true
    }

    // MARK: - Survey Creation

    private func createSurvey(type: SurveyType, userId: String, context: [String: Any]) async -> Survey {
        let surveyId = UUID().uuidString
        let questions = getQuestionsForSurveyType(type, context: context)

        let survey = Survey(
            id: surveyId,
            type: type,
            userId: userId,
            questions: questions,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 3600), // 24 hours
            context: context,
            variantId: nil
        )

        // Save to Firestore
        try? await saveSurvey(survey)

        return survey
    }

    private func getQuestionsForSurveyType(_ type: SurveyType, context: [String: Any]) -> [SurveyQuestion] {
        switch type {
        case .onboarding:
            return [
                SurveyQuestion(
                    id: "onboarding_satisfaction",
                    type: .rating,
                    question: "How satisfied are you with your onboarding experience?",
                    required: true,
                    options: ["1", "2", "3", "4", "5"]
                ),
                SurveyQuestion(
                    id: "onboarding_improvements",
                    type: .text,
                    question: "What could we improve about the onboarding process?",
                    required: false
                )
            ]

        case .usageLimit:
            let limitType = context["limit_type"] as? String ?? "feature"
            return [
                SurveyQuestion(
                    id: "limit_frustration",
                    type: .rating,
                    question: "How frustrated are you by the \(limitType) limit?",
                    required: true,
                    options: ["1", "2", "3", "4", "5"]
                ),
                SurveyQuestion(
                    id: "upgrade_interest",
                    type: .singleChoice,
                    question: "Would you consider upgrading to remove limits?",
                    required: true,
                    options: ["Yes, definitely", "Maybe later", "No, not interested"]
                )
            ]

        case .pricingValue:
            return [
                SurveyQuestion(
                    id: "current_value",
                    type: .rating,
                    question: "How valuable do you find the current free features?",
                    required: true,
                    options: ["1", "2", "3", "4", "5"]
                ),
                SurveyQuestion(
                    id: "premium_interest",
                    type: .singleChoice,
                    question: "Which premium features interest you most?",
                    required: false,
                    options: ["Unlimited scans", "More books", "Advanced analytics", "Priority support", "All of the above"]
                )
            ]

        case .featureRequest:
            return [
                SurveyQuestion(
                    id: "feature_importance",
                    type: .rating,
                    question: "How important is this feature to you?",
                    required: true,
                    options: ["1", "2", "3", "4", "5"]
                ),
                SurveyQuestion(
                    id: "feature_description",
                    type: .text,
                    question: "Please describe the feature you'd like to see:",
                    required: true
                )
            ]

        case .nps:
            return [
                SurveyQuestion(
                    id: "nps_score",
                    type: .nps,
                    question: "How likely are you to recommend Bookshelf Scanner to a friend?",
                    required: true,
                    options: Array(0...10).map { "\($0)" }
                ),
                SurveyQuestion(
                    id: "nps_reason",
                    type: .text,
                    question: "What's the main reason for your score?",
                    required: false
                )
            ]

        case .exitCancellation:
            return [
                SurveyQuestion(
                    id: "cancellation_reason",
                    type: .singleChoice,
                    question: "What's your main reason for cancelling?",
                    required: true,
                    options: ["Too expensive", "Not using enough", "Found better alternative", "Technical issues", "Other"]
                ),
                SurveyQuestion(
                    id: "cancellation_feedback",
                    type: .text,
                    question: "How can we improve to win you back?",
                    required: false
                )
            ]
        }
    }

    // MARK: - A/B Testing Integration

    private func applyABTestingVariant(survey: Survey, userId: String) async -> Survey? {
        // Check if there's an active experiment for this survey type
        let experimentId = "survey_\(survey.type.rawValue)_experiment"

        do {
            if let variant = try await ABTestingService.shared.getVariant(for: experimentId, userId: userId) {
                var modifiedSurvey = survey
                modifiedSurvey.variantId = variant.id

                // Apply variant modifications
                if let headline = variant.config["headline"] as? [String: Any],
                   let text = headline["value"] as? String {
                    modifiedSurvey.headline = text
                }

                if let questions = variant.config["questions"] as? [[String: Any]] {
                    modifiedSurvey.questions = questions.compactMap { SurveyQuestion.fromDict($0) }
                }

                return modifiedSurvey
            }
        } catch {
            print("Failed to apply A/B testing variant: \(error)")
        }

        return survey
    }

    // MARK: - Survey Response Handling

    func submitSurveyResponse(_ response: SurveyResponse) async {
        do {
            // Save response to Firestore
            try await saveSurveyResponse(response)

            // Mark survey as completed
            await markSurveyCompleted(surveyId: response.surveyId, userId: response.userId)

            // Track completion
            AnalyticsManager.shared.trackFeatureUsage(feature: "survey_completed", context: response.surveyType)

            // Queue for processing
            await FeedbackProcessor.shared.processSurveyResponse(response)

            // Hide survey
            await MainActor.run {
                self.shouldShowSurvey = false
                self.currentSurvey = nil
            }

        } catch {
            print("Failed to submit survey response: \(error)")
        }
    }

    func dismissSurvey() {
        Task {
            await MainActor.run {
                self.shouldShowSurvey = false
                self.currentSurvey = nil
            }

            if let survey = currentSurvey {
                AnalyticsManager.shared.trackFeatureUsage(feature: "survey_dismissed", context: survey.type.rawValue)
            }
        }
    }

    // MARK: - Trigger Setup

    private func setupSurveyTriggers() {
        // Onboarding completion trigger
        AuthService.shared.$hasCompletedOnboarding
            .filter { $0 }
            .sink { [weak self] _ in
                Task {
                    await self?.triggerSurvey(type: .onboarding)
                }
            }
            .store(in: &cancellables)

        // Usage limit hit trigger
        NotificationCenter.default.publisher(for: Notification.Name("LimitHit"))
            .sink { [weak self] notification in
                Task {
                    let context = notification.userInfo as? [String: Any] ?? [:]
                    await self?.triggerSurvey(type: .usageLimit, context: context)
                }
            }
            .store(in: &cancellables)

        // Upgrade prompt shown trigger
        NotificationCenter.default.publisher(for: Notification.Name("UpgradePromptShown"))
            .sink { [weak self] notification in
                Task {
                    let context = notification.userInfo as? [String: Any] ?? [:]
                    await self?.triggerSurvey(type: .pricingValue, context: context)
                }
            }
            .store(in: &cancellables)

        // Feature usage trigger (for feature request surveys)
        NotificationCenter.default.publisher(for: Notification.Name("FeatureUsed"))
            .sink { [weak self] notification in
                Task {
                    let context = notification.userInfo as? [String: Any] ?? [:]
                    await self?.triggerSurvey(type: .featureRequest, context: context)
                }
            }
            .store(in: &cancellables)

        // Time-based triggers
        setupTimeBasedTriggers()
    }

    private func setupTimeBasedTriggers() {
        // NPS survey trigger (every 60 days for eligible users)
        Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.triggerSurvey(type: .nps)
            }
        }
    }

    // MARK: - Firestore Operations

    private func saveSurvey(_ survey: Survey) async throws {
        let docRef = db.collection("surveys").document(survey.id)
        try await docRef.setData(survey.toDictionary())
    }

    private func saveSurveyResponse(_ response: SurveyResponse) async throws {
        let docRef = db.collection("surveyResponses").document(response.id)
        try await docRef.setData(response.toDictionary())
    }

    private func markSurveyCompleted(surveyId: String, userId: String) async {
        do {
            let docRef = db.collection("surveys").document(surveyId)
            try await docRef.updateData([
                "completedAt": Timestamp(date: Date()),
                "status": "completed"
            ])
        } catch {
            print("Failed to mark survey completed: \(error)")
        }
    }

    private func getLastSurveyCompletion(type: SurveyType, userId: String) async -> Date? {
        print("DEBUG FeedbackManager: Getting last survey completion for type: \(type.rawValue), userId: \(userId)")
        do {
            let snapshot = try await db.collection("surveyResponses")
                .whereField("userId", isEqualTo: userId)
                .whereField("surveyType", isEqualTo: type.rawValue)
                .order(by: "completedAt", descending: true)
                .limit(to: 1)
                .getDocuments()

            print("DEBUG FeedbackManager: Found \(snapshot.documents.count) survey responses for type \(type.rawValue)")
            if let doc = snapshot.documents.first {
                print("DEBUG FeedbackManager: Latest response data: \(doc.data())")
                if let response = SurveyResponse.fromDictionary(doc.data()) {
                    print("DEBUG FeedbackManager: Successfully decoded response, completedAt: \(response.completedAt)")
                    return response.completedAt
                } else {
                    print("DEBUG FeedbackManager: Failed to decode SurveyResponse from document")
                }
            } else {
                print("DEBUG FeedbackManager: No documents found for survey type \(type.rawValue)")
            }
        } catch let error as NSError {
            print("DEBUG FeedbackManager: Failed to get last survey completion: \(error)")
            print("DEBUG FeedbackManager: Error details - domain: \(error.domain), code: \(error.code)")

            // Handle index errors gracefully - return nil, allowing survey to be shown
            if error.domain == "FIRFirestoreErrorDomain" && error.code == 9 {
                print("DEBUG FeedbackManager: Index error detected - assuming no previous completion")
                return nil // Allow survey to be shown
            } else {
                // For other errors, return nil to be safe
                print("DEBUG FeedbackManager: Non-index error - returning nil for safety")
                return nil
            }
        }
        return nil
    }

    private func loadPendingSurveys() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG FeedbackManager: No userId available for loading pending surveys")
            return
        }

        print("DEBUG FeedbackManager: Loading pending surveys for userId: \(userId)")

        Task {
            do {
                let snapshot = try await db.collection("surveys")
                    .whereField("userId", isEqualTo: userId)
                    .whereField("status", isEqualTo: "pending")
                    .whereField("expiresAt", isGreaterThan: Timestamp(date: Date()))
                    .getDocuments()

                print("DEBUG FeedbackManager: Found \(snapshot.documents.count) pending surveys")
                self.surveyQueue = snapshot.documents.compactMap { Survey.fromDictionary($0.data()) }
                print("DEBUG FeedbackManager: Successfully loaded \(self.surveyQueue.count) surveys")
            } catch let error as NSError {
                print("DEBUG FeedbackManager: Failed to load pending surveys: \(error)")
                print("DEBUG FeedbackManager: Error details - domain: \(error.domain), code: \(error.code)")

                // Handle index errors gracefully - continue with empty queue
                if error.domain == "FIRFirestoreErrorDomain" && error.code == 9 {
                    print("DEBUG FeedbackManager: Index error detected - surveys may not load until indexes are created")
                    // Keep surveyQueue empty, app continues to function
                } else {
                    // For other errors, could retry or show user-friendly message
                    print("DEBUG FeedbackManager: Non-index error - may affect survey functionality")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func getLimitHitCount(userId: String, limitType: String) async -> Int {
        // This would query analytics or a dedicated collection
        // For now, return a mock value
        return 0
    }

    private func getFeatureUsageCount(userId: String) async -> Int {
        // This would query analytics data
        // For now, return a mock value
        return 5
    }
}

// MARK: - Supporting Types

struct Survey: Identifiable {
    var id: String
    var type: FeedbackManager.SurveyType
    var userId: String
    var questions: [SurveyQuestion]
    var createdAt: Date
    var expiresAt: Date
    var context: [String: Any]
    var variantId: String?
    var headline: String?
    var status: String = "pending"
    var completedAt: Date?

    // Custom encoding/decoding to handle [String: Any]
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "userId": userId,
            "questions": questions.map { $0.toDictionary() },
            "createdAt": Timestamp(date: createdAt),
            "expiresAt": Timestamp(date: expiresAt),
            "context": context,
            "variantId": variantId as Any,
            "headline": headline as Any,
            "status": status,
            "completedAt": completedAt.map { Timestamp(date: $0) } as Any
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> Survey? {
        guard let id = dict["id"] as? String,
              let typeString = dict["type"] as? String,
              let type = FeedbackManager.SurveyType(rawValue: typeString),
              let userId = dict["userId"] as? String,
              let questionsDicts = dict["questions"] as? [[String: Any]],
              let createdAtTimestamp = dict["createdAt"] as? Timestamp,
              let expiresAtTimestamp = dict["expiresAt"] as? Timestamp else { return nil }

        let questions = questionsDicts.compactMap { SurveyQuestion.fromDict($0) }
        let context = dict["context"] as? [String: Any] ?? [:]

        return Survey(
            id: id,
            type: type,
            userId: userId,
            questions: questions,
            createdAt: createdAtTimestamp.dateValue(),
            expiresAt: expiresAtTimestamp.dateValue(),
            context: context,
            variantId: dict["variantId"] as? String,
            headline: dict["headline"] as? String,
            status: dict["status"] as? String ?? "pending",
            completedAt: (dict["completedAt"] as? Timestamp)?.dateValue()
        )
    }

    var title: String {
        switch type {
        case .onboarding: return "Welcome Survey"
        case .usageLimit: return "Usage Feedback"
        case .pricingValue: return "Value Assessment"
        case .featureRequest: return "Feature Request"
        case .nps: return "Quick Feedback"
        case .exitCancellation: return "Cancellation Survey"
        }
    }
}

struct SurveyQuestion: Codable, Identifiable {
    var id: String
    var type: QuestionType
    var question: String
    var required: Bool
    var options: [String]?

    enum QuestionType: String, Codable {
        case rating
        case singleChoice
        case multipleChoice
        case text
        case nps
    }

    static func fromDict(_ dict: [String: Any]) -> SurveyQuestion? {
        guard let id = dict["id"] as? String,
              let typeString = dict["type"] as? String,
              let type = QuestionType(rawValue: typeString),
              let question = dict["question"] as? String,
              let required = dict["required"] as? Bool else { return nil }

        return SurveyQuestion(
            id: id,
            type: type,
            question: question,
            required: required,
            options: dict["options"] as? [String]
        )
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "question": question,
            "required": required,
            "options": options as Any
        ]
    }
}

struct SurveyResponse: Identifiable {
    var id: String
    var surveyId: String
    var surveyType: String
    var userId: String
    var responses: [String: Any]
    var completedAt: Date
    var variantId: String?
    var context: [String: Any]

    // Custom encoding/decoding to handle [String: Any]
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "surveyId": surveyId,
            "surveyType": surveyType,
            "userId": userId,
            "responses": responses,
            "completedAt": Timestamp(date: completedAt),
            "variantId": variantId as Any,
            "context": context
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> SurveyResponse? {
        guard let id = dict["id"] as? String,
              let surveyId = dict["surveyId"] as? String,
              let surveyType = dict["surveyType"] as? String,
              let userId = dict["userId"] as? String,
              let completedAtTimestamp = dict["completedAt"] as? Timestamp else { return nil }

        return SurveyResponse(
            id: id,
            surveyId: surveyId,
            surveyType: surveyType,
            userId: userId,
            responses: dict["responses"] as? [String: Any] ?? [:],
            completedAt: completedAtTimestamp.dateValue(),
            variantId: dict["variantId"] as? String,
            context: dict["context"] as? [String: Any] ?? [:]
        )
    }
}