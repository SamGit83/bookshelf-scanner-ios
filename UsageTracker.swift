import Foundation
import Combine

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

    init() {
        loadUsageData()
        checkAndResetMonthlyUsage()
    }

    // Free tier limits
    let freeTierScanLimit = 20
    let freeTierBookLimit = 25
    let freeTierRecommendationLimit = 5

    func canPerformScan() -> Bool {
        guard let tier = AuthService.shared.currentUser?.tier else { return false }
        if tier == .premium { return true }
        return monthlyScans < freeTierScanLimit
    }

    func canAddBook() -> Bool {
        guard let tier = AuthService.shared.currentUser?.tier else { return false }
        if tier == .premium { return true }
        return totalBooks < freeTierBookLimit
    }

    func canGetRecommendation() -> Bool {
        guard let tier = AuthService.shared.currentUser?.tier else { return false }
        if tier == .premium { return true }
        return monthlyRecommendations < freeTierRecommendationLimit
    }

    func incrementScans() {
        monthlyScans += 1
        saveUsageData()
    }

    func incrementBooks() {
        totalBooks += 1
        saveUsageData()
    }

    func incrementRecommendations() {
        monthlyRecommendations += 1
        saveUsageData()
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
    }

    // For premium users, these limits don't apply
    var scanLimit: Int {
        guard let tier = AuthService.shared.currentUser?.tier else { return freeTierScanLimit }
        return tier == .premium ? Int.max : freeTierScanLimit
    }

    var bookLimit: Int {
        guard let tier = AuthService.shared.currentUser?.tier else { return freeTierBookLimit }
        return tier == .premium ? Int.max : freeTierBookLimit
    }

    var recommendationLimit: Int {
        guard let tier = AuthService.shared.currentUser?.tier else { return freeTierRecommendationLimit }
        return tier == .premium ? Int.max : freeTierRecommendationLimit
    }
}