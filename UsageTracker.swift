import Foundation
import Combine

// Analytics integration
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

class UsageTracker: ObservableObject {
    static let shared = UsageTracker()

    @Published private(set) var monthlyScans: Int = 0
    @Published private(set) var totalBooks: Int = 0
    @Published private(set) var monthlyRecommendations: Int = 0

    private let userDefaults = UserDefaults.standard
    private let scansKey = "monthlyScans"
    private let booksKey = "totalBooks"
    private let recommendationsKey = "monthlyRecommendations"
    private let lastResetKey = "lastResetDate"

    public init() {
        loadUsageData()
        checkAndResetMonthlyUsage()
        // Refresh variant limits asynchronously
        Task {
            await refreshVariantLimits()
        }
    }

    // Default free tier limits (fallback)
    private let defaultScanLimit = 20
    private let defaultBookLimit = 25
    private let defaultRecommendationLimit = 5

    // Cached variant-specific limits
    @Published var variantScanLimit: Int = 20
    @Published var variantBookLimit: Int = 25
    @Published var variantRecommendationLimit: Int = 5

    func canPerformScan() -> Bool {
        guard let tier = AuthService.shared.currentUser?.tier else { return false }
        if tier == .premium { return true }
        return monthlyScans < variantScanLimit
    }

    func canAddBook() -> Bool {
        guard let tier = AuthService.shared.currentUser?.tier else { return false }
        if tier == .premium { return true }
        return totalBooks < variantBookLimit
    }

    func canGetRecommendation() -> Bool {
        guard let tier = AuthService.shared.currentUser?.tier else { return false }
        if tier == .premium { return true }
        return monthlyRecommendations < variantRecommendationLimit
    }

    func incrementScans() {
        monthlyScans += 1
        saveUsageData()
        // Update analytics user properties
        #if canImport(FirebaseAnalytics)
        AnalyticsManager.shared.updateDynamicUserProperties(totalBooks: totalBooks, monthlyScans: monthlyScans, monthlyRecommendations: monthlyRecommendations)
        #endif

        // Track analytics
        #if canImport(FirebaseAnalytics)
        if monthlyScans == scanLimit {
            AnalyticsManager.shared.trackLimitHit(limitType: "scan", currentValue: monthlyScans, limitValue: scanLimit)
            ABTestingService.shared.trackExperimentEvent(
                experimentId: "usage_limits_experiment",
                variantId: "current_variant", // Would need to get actual variant
                event: "limit_reached",
                parameters: ["limit_type": "scan", "current": monthlyScans, "limit": scanLimit]
            )
        }
        #endif

        // Trigger usage limit survey
        if monthlyScans == scanLimit {
            NotificationCenter.default.post(
                name: Notification.Name("LimitHit"),
                object: nil,
                userInfo: ["limit_type": "scan", "current_value": monthlyScans, "limit_value": scanLimit]
            )
        }
    }

    func incrementBooks() {
        totalBooks += 1
        saveUsageData()
        // Update analytics user properties
        #if canImport(FirebaseAnalytics)
        AnalyticsManager.shared.updateDynamicUserProperties(totalBooks: totalBooks, monthlyScans: monthlyScans, monthlyRecommendations: monthlyRecommendations)
        #endif

        #if canImport(FirebaseAnalytics)
        if totalBooks == bookLimit {
            AnalyticsManager.shared.trackLimitHit(limitType: "book", currentValue: totalBooks, limitValue: bookLimit)
            ABTestingService.shared.trackExperimentEvent(
                experimentId: "usage_limits_experiment",
                variantId: "current_variant",
                event: "limit_reached",
                parameters: ["limit_type": "book", "current": totalBooks, "limit": bookLimit]
            )
        }
        #endif

        // Trigger usage limit survey
        if totalBooks == bookLimit {
            NotificationCenter.default.post(
                name: Notification.Name("LimitHit"),
                object: nil,
                userInfo: ["limit_type": "book", "current_value": totalBooks, "limit_value": bookLimit]
            )
        }
    }

    func incrementRecommendations() {
        monthlyRecommendations += 1
        saveUsageData()
        // Update analytics user properties
        #if canImport(FirebaseAnalytics)
        AnalyticsManager.shared.updateDynamicUserProperties(totalBooks: totalBooks, monthlyScans: monthlyScans, monthlyRecommendations: monthlyRecommendations)
        #endif

        #if canImport(FirebaseAnalytics)
        if monthlyRecommendations == recommendationLimit {
            AnalyticsManager.shared.trackLimitHit(limitType: "recommendation", currentValue: monthlyRecommendations, limitValue: recommendationLimit)
            ABTestingService.shared.trackExperimentEvent(
                experimentId: "usage_limits_experiment",
                variantId: "current_variant",
                event: "limit_reached",
                parameters: ["limit_type": "recommendation", "current": monthlyRecommendations, "limit": recommendationLimit]
            )
        }
        #endif

        // Trigger usage limit survey
        if monthlyRecommendations == recommendationLimit {
            NotificationCenter.default.post(
                name: Notification.Name("LimitHit"),
                object: nil,
                userInfo: ["limit_type": "recommendation", "current_value": monthlyRecommendations, "limit_value": recommendationLimit]
            )
        }
    }

    private func loadUsageData() {
        monthlyScans = userDefaults.integer(forKey: scansKey)
        totalBooks = userDefaults.integer(forKey: booksKey)
        monthlyRecommendations = userDefaults.integer(forKey: recommendationsKey)
    }

    private func saveUsageData() {
        userDefaults.set(monthlyScans, forKey: scansKey)
        userDefaults.set(totalBooks, forKey: booksKey)
        userDefaults.set(monthlyRecommendations, forKey: recommendationsKey)
    }

    private func checkAndResetMonthlyUsage() {
        let calendar = Calendar.current
        let now = Date()
        let lastReset = userDefaults.object(forKey: lastResetKey) as? Date ?? now

        if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
            // New month, reset monthly counters
            monthlyScans = 0
            monthlyRecommendations = 0
            userDefaults.set(now, forKey: lastResetKey)
            saveUsageData()
        }
    }

    func resetAllUsage() {
        monthlyScans = 0
        totalBooks = 0
        monthlyRecommendations = 0
        userDefaults.removeObject(forKey: lastResetKey)
        saveUsageData()
    }

    func syncBookCount(_ count: Int) {
        totalBooks = count
        saveUsageData()
        // Update analytics user properties
        #if canImport(FirebaseAnalytics)
        AnalyticsManager.shared.updateDynamicUserProperties(totalBooks: totalBooks, monthlyScans: monthlyScans, monthlyRecommendations: monthlyRecommendations)
        #endif
    }

    // MARK: - A/B Testing Integration

    func refreshVariantLimits() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        do {
            let scanLimit = try await ABTestingService.shared.getScanLimit(for: userId)
            let bookLimit = try await ABTestingService.shared.getBookLimit(for: userId)
            let recommendationLimit = try await ABTestingService.shared.getRecommendationLimit(for: userId)

            await MainActor.run {
                self.variantScanLimit = scanLimit
                self.variantBookLimit = bookLimit
                self.variantRecommendationLimit = recommendationLimit
            }
        } catch {
            print("Failed to refresh variant limits: \(error)")
            // Keep default values
        }
    }

    func refreshOnUserChange() {
        Task {
            await refreshVariantLimits()
        }
    }

    // For premium users, these limits don't apply
    var scanLimit: Int {
        guard let tier = AuthService.shared.currentUser?.tier else { return variantScanLimit }
        return tier == .premium ? Int.max : variantScanLimit
    }

    var bookLimit: Int {
        guard let tier = AuthService.shared.currentUser?.tier else { return variantBookLimit }
        return tier == .premium ? Int.max : variantBookLimit
    }

    var recommendationLimit: Int {
        guard let tier = AuthService.shared.currentUser?.tier else { return variantRecommendationLimit }
        return tier == .premium ? Int.max : variantRecommendationLimit
    }
}