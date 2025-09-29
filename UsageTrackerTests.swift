import XCTest
@testable import BookshelfScanner

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
        // Mock premium user
        let mockUser = UserProfile(
            from: MockFirebaseUser(),
            firestoreData: ["tier": "premium", "hasCompletedOnboarding": true]
        )
        // Since we can't easily mock the AuthService, we'll test the logic directly
        // In a real test, we'd inject dependencies

        // For now, test that premium has unlimited
        // This would require mocking AuthService.currentUser?.tier
    }

    func testMonthlyReset() {
        // Add some usage
        usageTracker.incrementScans()
        usageTracker.incrementRecommendations()

        XCTAssertEqual(usageTracker.monthlyScans, 1)
        XCTAssertEqual(usageTracker.monthlyRecommendations, 1)

        // Simulate month change by clearing last reset date
        UserDefaults.standard.removeObject(forKey: "lastResetDate")

        // Create new instance to trigger reset check
        let newTracker = UsageTracker()

        // Should have reset monthly counters
        XCTAssertEqual(newTracker.monthlyScans, 0)
        XCTAssertEqual(newTracker.monthlyRecommendations, 0)
    }
}

// Mock Firebase User for testing
class MockFirebaseUser: NSObject {
    var uid: String = "testUserId"
    var email: String? = "test@example.com"
}

extension MockFirebaseUser: FirebaseAuth.User {
    // Implement required methods if needed
}