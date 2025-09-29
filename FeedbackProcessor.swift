import Foundation
import FirebaseFirestore
import Combine

/**
 * FeedbackProcessor - Automated analysis, sentiment analysis, and routing
 *
 * Uses Gemini API for intelligent analysis of survey responses, sentiment detection,
 * and automatic routing to appropriate processing pipelines.
 */
class FeedbackProcessor {
    static let shared = FeedbackProcessor()

    private let db = Firestore.firestore()
    private let geminiService = GeminiAPIService()
    private var processingQueue: [String] = []
    private var isProcessing = false

    private init() {}

    // MARK: - Main Processing Entry Point

    func processSurveyResponse(_ response: SurveyResponse) async {
        do {
            // Save processing metadata
            let processingId = UUID().uuidString
            let metadata = ProcessingMetadata(
                id: processingId,
                responseId: response.id,
                surveyType: response.surveyType,
                userId: response.userId,
                status: .processing,
                startedAt: Date()
            )

            try await saveProcessingMetadata(metadata)

            // Perform analysis
            let analysis = try await analyzeResponse(response)

            // Update metadata with results
            var updatedMetadata = metadata
            updatedMetadata.analysis = analysis
            updatedMetadata.status = .completed
            updatedMetadata.completedAt = Date()

            try await saveProcessingMetadata(updatedMetadata)

            // Route based on analysis
            await routeAnalysis(analysis, for: response)

            // Track processing completion
            AnalyticsManager.shared.trackFeatureUsage(feature: "feedback_processed", context: response.surveyType)

        } catch {
            print("Failed to process survey response: \(error)")

            // Update metadata with error
            let errorMetadata = ProcessingMetadata(
                id: UUID().uuidString,
                responseId: response.id,
                surveyType: response.surveyType,
                userId: response.userId,
                status: .failed,
                error: error.localizedDescription,
                startedAt: Date(),
                completedAt: Date()
            )

            try? await saveProcessingMetadata(errorMetadata)
        }
    }

    // MARK: - Analysis Engine

    private func analyzeResponse(_ response: SurveyResponse) async throws -> FeedbackAnalysis {
        // Extract text responses for analysis
        let textContent = extractTextContent(from: response)

        guard !textContent.isEmpty else {
            return FeedbackAnalysis(
                sentiment: .neutral,
                priority: .low,
                categories: [],
                keyInsights: [],
                actionableItems: [],
                confidence: 0.0
            )
        }

        // Use Gemini for intelligent analysis
        let analysisPrompt = """
        Analyze this user feedback from a \(response.surveyType) survey. Provide a structured analysis with the following components:

        FEEDBACK CONTENT:
        \(textContent)

        SURVEY CONTEXT:
        Type: \(response.surveyType)
        User ID: \(response.userId)
        Variant: \(response.variantId ?? "default")

        ANALYSIS REQUIREMENTS:
        1. Sentiment: Classify as positive, negative, or neutral
        2. Priority: Rate as critical, high, medium, or low priority
        3. Categories: Identify main themes (e.g., usability, pricing, features, bugs)
        4. Key Insights: Extract the most important points
        5. Actionable Items: Suggest specific actions to address the feedback
        6. Confidence: Rate your confidence in this analysis (0.0-1.0)

        OUTPUT FORMAT: Return a JSON object with this exact structure:
        {
          "sentiment": "positive|negative|neutral",
          "priority": "critical|high|medium|low",
          "categories": ["category1", "category2"],
          "keyInsights": ["insight1", "insight2"],
          "actionableItems": ["action1", "action2"],
          "confidence": 0.85
        }

        Focus on accuracy and actionable insights. Be specific about user needs and potential improvements.
        """

        let analysisResult = try await analyzeTextWithGemini(analysisPrompt)

        // Parse the JSON response
        guard let data = analysisResult.data(using: .utf8),
              let json = try? JSONDecoder().decode(GeminiAnalysisResponse.self, from: data) else {
            throw FeedbackError.analysisFailed("Failed to parse analysis response")
        }

        return FeedbackAnalysis(
            sentiment: Sentiment(rawValue: json.sentiment) ?? .neutral,
            priority: Priority(rawValue: json.priority) ?? .low,
            categories: json.categories,
            keyInsights: json.keyInsights,
            actionableItems: json.actionableItems,
            confidence: json.confidence
        )
    }

    private func extractTextContent(from response: SurveyResponse) -> String {
        var textParts: [String] = []

        for (questionId, answer) in response.responses {
            if let textAnswer = answer as? String, !textAnswer.isEmpty {
                // Try to get the question text for context
                if let survey = try? getSurveyById(response.surveyId),
                   let question = survey.questions.first(where: { $0.id == questionId }) {
                    textParts.append("Q: \(question.question)")
                    textParts.append("A: \(textAnswer)")
                } else {
                    textParts.append("Answer: \(textAnswer)")
                }
            }
        }

        return textParts.joined(separator: "\n")
    }

    // MARK: - Gemini Integration

    private func analyzeTextWithGemini(_ prompt: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Create a text-only request to Gemini
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(SecureConfig.shared.geminiAPIKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody: [String: Any] = [
                "contents": [
                    [
                        "parts": [
                            ["text": prompt]
                        ]
                    ]
                ],
                "generationConfig": [
                    "temperature": 0.1,
                    "topK": 1,
                    "topP": 1,
                    "maxOutputTokens": 2048
                ]
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let candidates = json["candidates"] as? [[String: Any]],
                          let firstCandidate = candidates.first,
                          let content = firstCandidate["content"] as? [String: Any],
                          let parts = content["parts"] as? [[String: Any]],
                          let firstPart = parts.first,
                          let text = firstPart["text"] as? String else {
                        continuation.resume(throwing: FeedbackError.analysisFailed("Invalid response format"))
                        return
                    }

                    // Track API cost ($0.0005 per text analysis for Gemini 1.5 Flash)
                    CostTracker.shared.recordCost(service: "gemini_text", cost: 0.0005)

                    continuation.resume(returning: text)
                }.resume()

            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Routing Logic

    private func routeAnalysis(_ analysis: FeedbackAnalysis, for response: SurveyResponse) async {
        // Route based on priority and categories
        if analysis.priority == .critical {
            // High priority feedback goes to immediate attention
            await createUrgentTask(analysis, response)
        }

        // Route by category
        for category in analysis.categories {
            switch category.lowercased() {
            case "feature request", "features":
                await routeToIterationTracker(analysis, response, type: .featureRequest)
            case "bug", "bugs", "technical issues":
                await routeToIterationTracker(analysis, response, type: .bugFix)
            case "pricing", "value":
                await routeToOptimizationEngine(analysis, response)
            case "usability", "ux", "ui":
                await routeToIterationTracker(analysis, response, type: .uxImprovement)
            case "performance":
                await routeToIterationTracker(analysis, response, type: .performance)
            default:
                await routeToGeneralFeedback(analysis, response)
            }
        }

        // Always send insights to analytics
        await sendInsightsToAnalytics(analysis, response)
    }

    private func createUrgentTask(_ analysis: FeedbackAnalysis, _ response: SurveyResponse) async {
        // Create an urgent task in IterationTracker
        let task = IterationTask(
            id: UUID().uuidString,
            title: "Urgent: Critical User Feedback",
            description: analysis.keyInsights.joined(separator: "\n"),
            type: .urgent,
            priority: .critical,
            status: .pending,
            createdFrom: response.id,
            userId: response.userId,
            surveyType: response.surveyType,
            actionableItems: analysis.actionableItems,
            createdAt: Date()
        )

        await IterationTracker.shared.addTask(task)
    }

    private func routeToIterationTracker(_ analysis: FeedbackAnalysis, _ response: SurveyResponse, type: IterationTaskType) async {
        let task = IterationTask(
            id: UUID().uuidString,
            title: "User Feedback: \(type.displayName)",
            description: analysis.keyInsights.joined(separator: "\n"),
            type: type,
            priority: analysis.priority.toIterationPriority(),
            status: .pending,
            createdFrom: response.id,
            userId: response.userId,
            surveyType: response.surveyType,
            actionableItems: analysis.actionableItems,
            createdAt: Date()
        )

        await IterationTracker.shared.addTask(task)
    }

    private func routeToOptimizationEngine(_ analysis: FeedbackAnalysis, _ response: SurveyResponse) async {
        // Send pricing/value feedback to optimization engine for insights
        let insight = OptimizationInsight(
            id: UUID().uuidString,
            category: .business,
            title: "User Pricing Feedback",
            description: analysis.keyInsights.joined(separator: "\n"),
            confidence: analysis.confidence,
            data: [
                "sentiment": analysis.sentiment.rawValue,
                "user_id": response.userId,
                "survey_type": response.surveyType
            ]
        )

        await MainActor.run {
            OptimizationEngine.shared.insights.append(insight)
        }
    }

    private func routeToGeneralFeedback(_ analysis: FeedbackAnalysis, _ response: SurveyResponse) async {
        // Store in general feedback collection for review
        let feedback = ProcessedFeedback(
            id: UUID().uuidString,
            responseId: response.id,
            analysis: analysis,
            routedTo: "general",
            processedAt: Date()
        )

        try? await saveProcessedFeedback(feedback)
    }

    private func sendInsightsToAnalytics(_ analysis: FeedbackAnalysis, _ response: SurveyResponse) async {
        // Send key metrics to analytics
        AnalyticsManager.shared.trackFeatureUsage(feature: "feedback_sentiment", context: analysis.sentiment.rawValue)
        AnalyticsManager.shared.trackFeatureUsage(feature: "feedback_priority", context: analysis.priority.rawValue)

        for category in analysis.categories {
            AnalyticsManager.shared.trackFeatureUsage(feature: "feedback_category", context: category)
        }
    }

    // MARK: - Data Persistence

    private func saveProcessingMetadata(_ metadata: ProcessingMetadata) async throws {
        let docRef = db.collection("feedbackProcessing").document(metadata.id)
        try docRef.setData(from: metadata)
    }

    private func saveProcessedFeedback(_ feedback: ProcessedFeedback) async throws {
        let docRef = db.collection("processedFeedback").document(feedback.id)
        try docRef.setData(from: feedback)
    }

    private func getSurveyById(_ surveyId: String) throws -> Survey {
        // This would need to be implemented to fetch survey details
        // For now, return a placeholder
        throw FeedbackError.surveyNotFound
    }

    // MARK: - Batch Processing

    func processPendingFeedback() async {
        guard !isProcessing else { return }
        isProcessing = true

        defer { isProcessing = false }

        do {
            let snapshot = try await db.collection("surveyResponses")
                .whereField("processed", isEqualTo: false)
                .limit(to: 10)
                .getDocuments()

            for document in snapshot.documents {
                let response = try document.data(as: SurveyResponse.self)
                await processSurveyResponse(response)

                // Mark as processed
                try await db.collection("surveyResponses").document(response.id).updateData(["processed": true])
            }
        } catch {
            print("Failed to process pending feedback: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct FeedbackAnalysis: Codable {
    let sentiment: Sentiment
    let priority: Priority
    let categories: [String]
    let keyInsights: [String]
    let actionableItems: [String]
    let confidence: Double
}

enum Sentiment: String, Codable {
    case positive, negative, neutral
}

enum Priority: String, Codable {
    case critical, high, medium, low

    func toIterationPriority() -> IterationPriority {
        switch self {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
}

struct ProcessingMetadata: Codable, Identifiable {
    var id: String
    var responseId: String
    var surveyType: String
    var userId: String
    var status: ProcessingStatus
    var analysis: FeedbackAnalysis?
    var error: String?
    var startedAt: Date
    var completedAt: Date?
}

enum ProcessingStatus: String, Codable {
    case processing, completed, failed
}

struct ProcessedFeedback: Codable, Identifiable {
    var id: String
    var responseId: String
    var analysis: FeedbackAnalysis
    var routedTo: String
    var processedAt: Date
}

struct GeminiAnalysisResponse: Codable {
    let sentiment: String
    let priority: String
    let categories: [String]
    let keyInsights: [String]
    let actionableItems: [String]
    let confidence: Double
}

enum FeedbackError: Error {
    case analysisFailed(String)
    case surveyNotFound
    case invalidResponse
}

// MARK: - Integration with IterationTracker

extension FeedbackProcessor {
    // This will be implemented when IterationTracker is created
    // For now, these are placeholder calls
}