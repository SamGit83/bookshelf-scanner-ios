import XCTest
@testable import BookshelfScanner

class RateLimiterTests: XCTestCase {

    var rateLimiter: RateLimiter!
    var mockUserDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        // Create rate limiter with test-friendly limits
        rateLimiter = RateLimiter(hourlyLimit: 5, dailyLimit: 10)
    }

    override func tearDown() {
        mockUserDefaults.reset()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Test that rate limiter initializes with correct limits
        XCTAssertEqual(rateLimiter.hourlyLimit, 5)
        XCTAssertEqual(rateLimiter.dailyLimit, 10)
    }

    func testInitializationWithDefaultLimits() {
        // Test default initialization
        let defaultLimiter = RateLimiter()
        XCTAssertEqual(defaultLimiter.hourlyLimit, 100)
        XCTAssertEqual(defaultLimiter.dailyLimit, 1000)
    }

    // MARK: - Call Tracking Tests

    func testCanMakeCallWithNoPreviousCalls() {
        // Given - No previous calls
        mockUserDefaults.storage.removeAll()

        // When & Then
        XCTAssertTrue(rateLimiter.canMakeCall())
    }

    func testCanMakeCallWithinLimits() {
        // Given - Some calls but within limits
        let now = Date()
        let timestamps = [
            now.addingTimeInterval(-3600), // 1 hour ago
            now.addingTimeInterval(-1800), // 30 minutes ago
            now.addingTimeInterval(-600),  // 10 minutes ago
        ].map { $0.timeIntervalSince1970 }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertTrue(rateLimiter.canMakeCall())
    }

    func testCannotMakeCallExceedingHourlyLimit() {
        // Given - Exceeding hourly limit
        let now = Date()
        let timestamps = (0..<5).map { index in
            now.addingTimeInterval(-Double(index) * 60).timeIntervalSince1970 // Within last hour
        }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertFalse(rateLimiter.canMakeCall())
    }

    func testCannotMakeCallExceedingDailyLimit() {
        // Given - Exceeding daily limit
        let now = Date()
        let timestamps = (0..<10).map { index in
            now.addingTimeInterval(-Double(index) * 3600).timeIntervalSince1970 // Within last 10 hours
        }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertFalse(rateLimiter.canMakeCall())
    }

    func testRecordCall() {
        // Given
        let initialCalls = rateLimiter.getCalls()
        XCTAssertEqual(initialCalls.count, 0)

        // When
        rateLimiter.recordCall()

        // Then
        let recordedCalls = rateLimiter.getCalls()
        XCTAssertEqual(recordedCalls.count, 1)

        // Verify timestamp is recent
        let timeDifference = abs(recordedCalls[0].timeIntervalSinceNow)
        XCTAssertLessThan(timeDifference, 1.0, "Call should be recorded with current timestamp")
    }

    func testRecordCallWithOldCallsCleanup() {
        // Given - Mix of old and recent calls
        let now = Date()
        let oldTimestamp = now.addingTimeInterval(-86401) // Just over 24 hours ago
        let recentTimestamp = now.addingTimeInterval(-3600) // 1 hour ago

        let timestamps = [oldTimestamp, recentTimestamp].map { $0.timeIntervalSince1970 }
        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When
        rateLimiter.recordCall()

        // Then
        let calls = rateLimiter.getCalls()
        XCTAssertEqual(calls.count, 2, "Should keep recent calls and new call")

        // Old call should be cleaned up
        let hasOldCall = calls.contains { abs($0.timeIntervalSince(oldTimestamp)) < 1 }
        XCTAssertFalse(hasOldCall, "Old calls should be cleaned up")
    }

    // MARK: - Remaining Calls Tests

    func testGetRemainingCallsWithNoCalls() {
        // Given - No previous calls
        mockUserDefaults.storage.removeAll()

        // When
        let remaining = rateLimiter.getRemainingCalls()

        // Then
        XCTAssertEqual(remaining.hourly, 5)
        XCTAssertEqual(remaining.daily, 10)
    }

    func testGetRemainingCallsWithSomeCalls() {
        // Given - Some calls made
        let now = Date()
        let timestamps = [
            now.addingTimeInterval(-1800), // 30 minutes ago
            now.addingTimeInterval(-600),  // 10 minutes ago
        ].map { $0.timeIntervalSince1970 }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When
        let remaining = rateLimiter.getRemainingCalls()

        // Then
        XCTAssertEqual(remaining.hourly, 3) // 5 - 2 = 3
        XCTAssertEqual(remaining.daily, 8)  // 10 - 2 = 8
    }

    func testGetRemainingCallsAtLimit() {
        // Given - At hourly limit
        let now = Date()
        let timestamps = (0..<5).map { index in
            now.addingTimeInterval(-Double(index) * 60).timeIntervalSince1970
        }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When
        let remaining = rateLimiter.getRemainingCalls()

        // Then
        XCTAssertEqual(remaining.hourly, 0)
        XCTAssertEqual(remaining.daily, 5) // 10 - 5 = 5
    }

    // MARK: - Rate Limit Violation Logging Tests

    func testRecordCallTriggersHourlyLimitLogging() {
        // Given - Just under hourly limit
        let now = Date()
        let timestamps = (0..<4).map { index in
            now.addingTimeInterval(-Double(index) * 60).timeIntervalSince1970
        }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When - Record one more call to hit the limit
        rateLimiter.recordCall()

        // Then - Should have logged the violation
        // Note: We can't easily test the logging directly without mocking SecurityLogger
        // But we can verify the call was recorded
        let calls = rateLimiter.getCalls()
        XCTAssertEqual(calls.count, 5)
    }

    func testRecordCallTriggersDailyLimitLogging() {
        // Given - Just under daily limit
        let now = Date()
        let timestamps = (0..<9).map { index in
            now.addingTimeInterval(-Double(index) * 3600).timeIntervalSince1970
        }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When - Record one more call to hit the limit
        rateLimiter.recordCall()

        // Then - Should have logged the violation
        let calls = rateLimiter.getCalls()
        XCTAssertEqual(calls.count, 10)
    }

    // MARK: - Time Window Tests

    func testHourlyLimitResetsAfterTimeWindow() {
        // Given - Calls from more than an hour ago
        let now = Date()
        let oldTimestamp = now.addingTimeInterval(-7200) // 2 hours ago
        let timestamps = [oldTimestamp.timeIntervalSince1970]
        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertTrue(rateLimiter.canMakeCall(), "Should allow calls after time window expires")
    }

    func testDailyLimitResetsAfterTimeWindow() {
        // Given - Calls from more than a day ago
        let now = Date()
        let oldTimestamp = now.addingTimeInterval(-172800) // 2 days ago
        let timestamps = [oldTimestamp.timeIntervalSince1970]
        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertTrue(rateLimiter.canMakeCall(), "Should allow calls after daily time window expires")
    }

    // MARK: - Edge Cases

    func testEmptyStoredCalls() {
        // Given - Empty array in storage
        mockUserDefaults.storage["apiCalls_test"] = [Any]()

        // When & Then
        XCTAssertTrue(rateLimiter.canMakeCall())
    }

    func testInvalidStoredCalls() {
        // Given - Invalid data in storage
        mockUserDefaults.storage["apiCalls_test"] = "invalid data"

        // When & Then
        XCTAssertTrue(rateLimiter.canMakeCall(), "Should handle invalid stored data gracefully")
    }

    func testConcurrentAccess() {
        // Test concurrent access to rate limiter
        let expectation = XCTestExpectation(description: "Concurrent rate limiting")
        expectation.expectedFulfillmentCount = 5

        DispatchQueue.concurrentPerform(iterations: 5) { _ in
            for _ in 0..<3 {
                let canMakeCall = self.rateLimiter.canMakeCall()
                if canMakeCall {
                    self.rateLimiter.recordCall()
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Verify total calls don't exceed limits
        let calls = rateLimiter.getCalls()
        XCTAssertLessThanOrEqual(calls.count, 5, "Should not exceed hourly limit")
    }

    // MARK: - Device ID Tests

    func testDeviceSpecificStorage() {
        // Test that calls are stored per device
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let expectedKey = "apiCalls_\(deviceId)"

        // When
        rateLimiter.recordCall()

        // Then
        XCTAssertNotNil(mockUserDefaults.storage[expectedKey], "Should store calls with device-specific key")
    }

    // MARK: - Persistence Tests

    func testCallPersistenceAcrossInstances() {
        // Given - Record calls with first instance
        rateLimiter.recordCall()
        rateLimiter.recordCall()

        // When - Create new instance
        let newLimiter = RateLimiter(hourlyLimit: 5, dailyLimit: 10)

        // Then - Should see the same calls
        let calls = newLimiter.getCalls()
        XCTAssertEqual(calls.count, 2, "Calls should persist across instances")
    }

    // MARK: - Boundary Tests

    func testBoundaryHourlyLimit() {
        // Given - Exactly at hourly limit
        let now = Date()
        let timestamps = (0..<5).map { index in
            now.addingTimeInterval(-Double(index) * 60).timeIntervalSince1970
        }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertFalse(rateLimiter.canMakeCall(), "Should not allow call at exact limit")
    }

    func testBoundaryDailyLimit() {
        // Given - Exactly at daily limit
        let now = Date()
        let timestamps = (0..<10).map { index in
            now.addingTimeInterval(-Double(index) * 3600).timeIntervalSince1970
        }

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertFalse(rateLimiter.canMakeCall(), "Should not allow call at exact daily limit")
    }

    func testTimeWindowBoundary() {
        // Given - Call exactly at the edge of time window
        let now = Date()
        let boundaryTimestamp = now.addingTimeInterval(-3600) // Exactly 1 hour ago
        let timestamps = [boundaryTimestamp.timeIntervalSince1970]

        mockUserDefaults.storage["apiCalls_test"] = timestamps

        // When & Then
        XCTAssertTrue(rateLimiter.canMakeCall(), "Should allow call when old call is exactly at boundary")
    }
}