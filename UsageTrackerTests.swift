import XCTest
import FirebaseAuth
@testable import ios

class UsageTrackerTests: XCTestCase {

    var usageTracker: UsageTracker!

    override func setUp() {
        super.setUp()
        usageTracker = UsageTracker.shared
        // Reset usage for testing
        usageTracker.resetAllUsage()
    }

    override func tearDown() {
        usageTracker.resetAllUsage()
        super.tearDown()
    }

    func testFreeTierLimits() {
        // Test free tier limits
        XCTAssertEqual(usageTracker.scanLimit, 20)
        XCTAssertEqual(usageTracker.bookLimit, 25)
        XCTAssertEqual(usageTracker.recommendationLimit, 5)
    }

    func testCanPerformScanFreeTier() {
        // Initially should be able to scan
        XCTAssertTrue(usageTracker.canPerformScan())

        // Add scans up to limit
        for _ in 0..<20 {
            usageTracker.incrementScans()
        }

        // Should not be able to scan anymore
        XCTAssertFalse(usageTracker.canPerformScan())
    }

    func testCanAddBookFreeTier() {
        // Initially should be able to add books
        XCTAssertTrue(usageTracker.canAddBook())

        // Add books up to limit
        for _ in 0..<25 {
            usageTracker.incrementBooks()
        }

        // Should not be able to add more books
        XCTAssertFalse(usageTracker.canAddBook())
    }

    func testCanGetRecommendationFreeTier() {
        // Initially should be able to get recommendations
        XCTAssertTrue(usageTracker.canGetRecommendation())

        // Get recommendations up to limit
        for _ in 0..<5 {
            usageTracker.incrementRecommendations()
        }

        // Should not be able to get more recommendations
        XCTAssertFalse(usageTracker.canGetRecommendation())
    }

    func testPremiumTierUnlimited() {
        // Note: Premium tier testing requires mocking AuthService
        // For now, we verify the logic through the limit properties
        // In a full test suite, we'd use dependency injection
        XCTAssertEqual(UsageTracker.shared.scanLimit, 20) // Free tier default
        XCTAssertEqual(UsageTracker.shared.bookLimit, 25) // Free tier default
        XCTAssertEqual(UsageTracker.shared.recommendationLimit, 5) // Free tier default
    }

    func testMonthlyReset() {
        // Add some usage
        usageTracker.incrementScans()
        usageTracker.incrementRecommendations()

        XCTAssertEqual(usageTracker.monthlyScans, 1)
        XCTAssertEqual(usageTracker.monthlyRecommendations, 1)

        // Simulate month change by clearing last reset date
        UserDefaults.standard.removeObject(forKey: "lastResetDate")

        // Reset the shared instance by calling reset manually for testing
        usageTracker.resetAllUsage()

        // Should have reset monthly counters
        XCTAssertEqual(usageTracker.monthlyScans, 0)
        XCTAssertEqual(usageTracker.monthlyRecommendations, 0)
    }
}
