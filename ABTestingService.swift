import Foundation
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// Analytics integration
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

class ABTestingService {
    static let shared = ABTestingService()

    #if canImport(FirebaseRemoteConfig)
    private let remoteConfig = RemoteConfig.remoteConfig()
    #else
    private let remoteConfig: Any? = nil
    #endif
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #else
    private let db: Any? = nil
    #endif
    private var experiments: [Experiment] = []
    private var userAssignments: [String: UserExperimentAssignment] = [:] // experimentId -> assignment

    private init() {
        configureRemoteConfig()
    }

    private func configureRemoteConfig() {
        #if canImport(FirebaseRemoteConfig)
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development; set to 3600 in production
        remoteConfig.configSettings = settings
        #endif
    }

    // MARK: - Experiment Management

    func fetchExperiments() async throws {
        // Try Remote Config first
        try await fetchFromRemoteConfig()

        // Fallback to Firestore if needed
        if experiments.isEmpty {
            try await fetchFromFirestore()
        }
    }

    private func fetchFromRemoteConfig() async throws {
        #if canImport(FirebaseRemoteConfig)
        let status = try await remoteConfig.fetchAndActivate()
        if status != .successFetchedFromRemote {
            throw ABTestingError.fetchFailed("Failed to fetch remote config")
        }

        let experimentsJson = remoteConfig["experiments"].stringValue
        guard !experimentsJson.isEmpty else { return }

        let data = experimentsJson.data(using: .utf8)!
        experiments = try JSONDecoder().decode([Experiment].self, from: data)
        #endif
    }

    private func fetchFromFirestore() async throws {
        #if canImport(FirebaseFirestore)
        let snapshot = try await db.collection("experiments").getDocuments()
        experiments = snapshot.documents.compactMap { document in
            try? document.data(as: Experiment.self)
        }
        #endif
    }

    // MARK: - User Assignment

    func getVariant(for experimentId: String, userId: String) async throws -> Variant? {
        // Check if user is already assigned
        if let assignment = userAssignments[experimentId], assignment.userId == userId {
            return experiments.first(where: { $0.id == experimentId })?.variants.first(where: { $0.id == assignment.variantId })
        }

        // Check Firestore for existing assignment
        let assignment = try await fetchUserAssignment(experimentId: experimentId, userId: userId)
        if let assignment = assignment {
            userAssignments[experimentId] = assignment
            return experiments.first(where: { $0.id == experimentId })?.variants.first(where: { $0.id == assignment.variantId })
        }

        // Assign new variant
        guard let experiment = experiments.first(where: { $0.id == experimentId && $0.status == .active }) else {
            return nil
        }

        let variant = assignVariant(for: experiment)
        let assignment = UserExperimentAssignment(userId: userId, experimentId: experimentId, variantId: variant.id)

        // Save assignment
        try await saveUserAssignment(assignment)
        userAssignments[experimentId] = assignment

        // Track assignment event
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("experiment_assigned", parameters: [
            "experiment_id": experimentId,
            "variant_id": variant.id,
            "user_id": userId
        ])
        #endif

        // Set experiment variant in analytics
        AnalyticsManager.shared.setExperimentVariant(experimentId: experimentId, variantId: variant.id)

        return variant
    }

    private func assignVariant(for experiment: Experiment) -> Variant {
        let totalWeight = experiment.variants.reduce(0) { $0 + $1.weight }
        let random = Double.random(in: 0..<totalWeight)
        var cumulativeWeight = 0.0

        for variant in experiment.variants {
            cumulativeWeight += variant.weight
            if random < cumulativeWeight {
                return variant
            }
        }

        return experiment.variants.first! // Fallback
    }

    private func fetchUserAssignment(experimentId: String, userId: String) async throws -> UserExperimentAssignment? {
        #if canImport(FirebaseFirestore)
        let docRef = db.collection("userExperimentAssignments").document("\(userId)_\(experimentId)")
        let document = try await docRef.getDocument()
        return try document.data(as: UserExperimentAssignment.self)
        #else
        return nil
        #endif
    }

    private func saveUserAssignment(_ assignment: UserExperimentAssignment) async throws {
        #if canImport(FirebaseFirestore)
        let docRef = db.collection("userExperimentAssignments").document(assignment.id)
        try docRef.setData(from: assignment)
        #endif
    }

    // MARK: - Configuration Retrieval

    func getConfigValue<T>(for experimentId: String, userId: String, key: String) async throws -> T? {
        guard let variant = try await getVariant(for: experimentId, userId: userId) else { return nil }
        return variant.config[key]?.value as? T
    }

    func getScanLimit(for userId: String) async throws -> Int {
        let experimentId = "usage_limits_experiment" // Define experiment ID
        if let limit: Int = try await getConfigValue(for: experimentId, userId: userId, key: "scanLimit") {
            return limit
        }
        return 20 // Default
    }

    func getBookLimit(for userId: String) async throws -> Int {
        let experimentId = "usage_limits_experiment"
        if let limit: Int = try await getConfigValue(for: experimentId, userId: userId, key: "bookLimit") {
            return limit
        }
        return 25 // Default
    }

    func getRecommendationLimit(for userId: String) async throws -> Int {
        let experimentId = "usage_limits_experiment"
        if let limit: Int = try await getConfigValue(for: experimentId, userId: userId, key: "recommendationLimit") {
            return limit
        }
        return 5 // Default
    }

    // MARK: - Analytics Tracking

    func trackExperimentEvent(experimentId: String, variantId: String, event: String, parameters: [String: Any] = [:]) {
        #if canImport(FirebaseAnalytics)
        var params = parameters
        params["experiment_id"] = experimentId
        params["variant_id"] = variantId
        Analytics.logEvent(event, parameters: params)
        #endif
    }

    // MARK: - RevenueCat Integration Points

    // TODO: Integrate RevenueCat SDK for dynamic pricing based on A/B test variants
    // Use getPricingConfig to retrieve variant-specific prices and update RevenueCat products accordingly
    func getPricingConfig(for experimentId: String, userId: String) async throws -> (monthly: Double, annual: Double)? {
        guard let variant = try await getVariant(for: experimentId, userId: userId) else { return nil }
        guard let monthly = variant.monthlyPrice, let annual = variant.annualPrice else { return nil }
        return (monthly, annual)
    }

    func getCurrentVariantId(for experimentId: String, userId: String) async -> String? {
        do {
            return try await getVariant(for: experimentId, userId: userId)?.id
        } catch {
            return nil
        }
    }

    // MARK: - Error Handling

    enum ABTestingError: Error {
        case fetchFailed(String)
        case assignmentFailed(String)
        case configurationError(String)
    }
}