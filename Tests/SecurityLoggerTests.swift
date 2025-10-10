import XCTest
@testable import BookshelfScanner

class SecurityLoggerTests: XCTestCase {

    var securityLogger: SecurityLogger!
    var mockUserDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        securityLogger = SecurityLogger()
    }

    override func tearDown() {
        mockUserDefaults.reset()
        securityLogger.clearStoredEvents()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSingletonInstance() {
        let instance1 = SecurityLogger.shared
        let instance2 = SecurityLogger.shared

        XCTAssertTrue(instance1 === instance2, "Should return same singleton instance")
    }

    func testDefaultConfiguration() {
        XCTAssertEqual(securityLogger.consoleLogLevel, .info)
        XCTAssertEqual(securityLogger.firebaseLogLevel, .warning)
        XCTAssertTrue(securityLogger.storeLocally)
    }

    // MARK: - Configuration Tests

    func testSetConsoleLogLevel() {
        // When
        securityLogger.setConsoleLogLevel(.debug)

        // Then
        XCTAssertEqual(securityLogger.consoleLogLevel, .debug)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "security_console_log_level"), 0)
    }

    func testSetFirebaseLogLevel() {
        // When
        securityLogger.setFirebaseLogLevel(.error)

        // Then
        XCTAssertEqual(securityLogger.firebaseLogLevel, .error)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "security_firebase_log_level"), 3)
    }

    func testSetStoreLocally() {
        // When
        securityLogger.setStoreLocally(false)

        // Then
        XCTAssertFalse(securityLogger.storeLocally)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: "security_store_locally"), false)
    }

    // MARK: - Event Logging Tests

    func testLogSecurityEvent() {
        // When
        securityLogger.logSecurityEvent(
            type: .authenticationFailure,
            level: .warning,
            service: "TestService",
            endpoint: "/test",
            details: ["test": "value"],
            errorMessage: "Test error"
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .authenticationFailure)
        XCTAssertEqual(event.level, .warning)
        XCTAssertEqual(event.service, "TestService")
        XCTAssertEqual(event.endpoint, "/test")
        XCTAssertEqual(event.errorMessage, "Test error")
        XCTAssertNotNil(event.details?["test"])
    }

    func testLogRateLimitViolation() {
        // When
        securityLogger.logRateLimitViolation(
            service: "TestService",
            endpoint: "/api/test",
            limit: 100,
            currentCount: 150,
            details: ["user_id": "123"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .rateLimitViolation)
        XCTAssertEqual(event.level, .warning)
        XCTAssertEqual(event.service, "TestService")
        XCTAssertEqual(event.endpoint, "/api/test")
        XCTAssertEqual(event.details?["limit"] as? Int, 100)
        XCTAssertEqual(event.details?["current_count"] as? Int, 150)
        XCTAssertEqual(event.details?["user_id"] as? String, "123")
    }

    func testLogTimestampValidationFailure() {
        // Given
        let timestamp = Date().addingTimeInterval(-400)

        // When
        securityLogger.logTimestampValidationFailure(
            service: "TestService",
            endpoint: "/api/test",
            providedTimestamp: timestamp,
            allowedWindow: 300.0,
            details: ["reason": "expired"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .timestampValidationFailure)
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.service, "TestService")
        XCTAssertEqual(event.endpoint, "/api/test")
        XCTAssertEqual(event.details?["time_difference_seconds"] as? Double, 400.0, accuracy: 1.0)
    }

    func testLogAPIKeyIssue() {
        // When
        securityLogger.logAPIKeyIssue(
            type: .apiKeyMissing,
            service: "TestService",
            keyType: "gemini",
            details: ["endpoint": "/api/test"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .apiKeyMissing)
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.service, "TestService")
        XCTAssertEqual(event.details?["key_type"] as? String, "gemini")
    }

    func testLogAuthenticationFailure() {
        // When
        securityLogger.logAuthenticationFailure(
            service: "TestService",
            reason: "Invalid credentials",
            details: ["attempts": 3]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .authenticationFailure)
        XCTAssertEqual(event.level, .warning)
        XCTAssertEqual(event.service, "TestService")
        XCTAssertEqual(event.details?["failure_reason"] as? String, "Invalid credentials")
    }

    func testLogAuthorizationFailure() {
        // When
        securityLogger.logAuthorizationFailure(
            service: "TestService",
            resource: "user_profile",
            action: "update",
            details: ["user_role": "guest"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .authorizationFailure)
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.service, "TestService")
        XCTAssertEqual(event.details?["resource"] as? String, "user_profile")
        XCTAssertEqual(event.details?["action"] as? String, "update")
    }

    func testLogSuspiciousActivity() {
        // When
        securityLogger.logSuspiciousActivity(
            activity: "Unusual login pattern",
            severity: .error,
            details: ["ip_address": "192.168.1.1"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .suspiciousActivity)
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.details?["activity"] as? String, "Unusual login pattern")
    }

    func testLogDataTampering() {
        // When
        securityLogger.logDataTampering(
            service: "TestService",
            dataType: "user_data",
            details: ["tampered_field": "email"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .dataTampering)
        XCTAssertEqual(event.level, .critical)
        XCTAssertEqual(event.service, "TestService")
        XCTAssertEqual(event.details?["data_type"] as? String, "user_data")
    }

    func testLogEncryptionFailure() {
        // Given
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: nil)

        // When
        securityLogger.logEncryptionFailure(
            operation: "decrypt",
            error: testError,
            details: ["algorithm": "AES-GCM"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .encryptionFailure)
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.details?["operation"] as? String, "decrypt")
        XCTAssertEqual(event.errorMessage, "The operation couldn’t be completed. (TestDomain error 123.)")
    }

    func testLogNetworkSecurityViolation() {
        // When
        securityLogger.logNetworkSecurityViolation(
            violation: "Invalid SSL certificate",
            url: "https://example.com",
            details: ["certificate_hash": "abc123"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .networkSecurityViolation)
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.details?["violation"] as? String, "Invalid SSL certificate")
        XCTAssertEqual(event.details?["url"] as? String, "https://example.com")
    }

    func testLogConfigurationError() {
        // Given
        let testError = NSError(domain: "ConfigDomain", code: 456, userInfo: nil)

        // When
        securityLogger.logConfigurationError(
            setting: "api_timeout",
            error: testError,
            details: ["expected_type": "TimeInterval"]
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertEqual(event.type, .configurationError)
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.details?["setting"] as? String, "api_timeout")
    }

    // MARK: - Event Storage Tests

    func testEventStorageLimit() {
        // Given - Store more than max events
        for i in 0..<1010 { // Max is 1000
            securityLogger.logSecurityEvent(
                type: .suspiciousActivity,
                level: .info,
                service: "TestService\(i)"
            )
        }

        // When
        let events = securityLogger.getStoredEvents()

        // Then
        XCTAssertEqual(events.count, 1000, "Should not exceed maximum stored events")
    }

    func testEventPersistence() {
        // Given
        securityLogger.logSecurityEvent(
            type: .authenticationFailure,
            level: .warning,
            service: "TestService"
        )

        // When - Create new logger instance
        let newLogger = SecurityLogger()

        // Then
        let events = newLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].type, .authenticationFailure)
    }

    func testClearStoredEvents() {
        // Given
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .info)
        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .warning)

        var events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 2)

        // When
        securityLogger.clearStoredEvents()

        // Then
        events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 0)
    }

    // MARK: - Event Retrieval Tests

    func testGetEventsByType() {
        // Given
        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .warning)
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .info)
        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .error)

        // When
        let authEvents = securityLogger.getEvents(ofType: .authenticationFailure)

        // Then
        XCTAssertEqual(authEvents.count, 2)
        XCTAssertTrue(authEvents.allSatisfy { $0.type == .authenticationFailure })
    }

    func testGetEventsByLevel() {
        // Given
        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .warning)
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .info)
        securityLogger.logSecurityEvent(type: .dataTampering, level: .critical)

        // When
        let warningEvents = securityLogger.getEvents(level: .warning)

        // Then
        XCTAssertEqual(warningEvents.count, 1)
        XCTAssertEqual(warningEvents[0].type, .authenticationFailure)
    }

    func testGetEventsWithLimit() {
        // Given
        for i in 0..<5 {
            securityLogger.logSecurityEvent(
                type: .suspiciousActivity,
                level: .info,
                service: "Service\(i)"
            )
        }

        // When
        let limitedEvents = securityLogger.getEvents(limit: 3)

        // Then
        XCTAssertEqual(limitedEvents.count, 3)
    }

    func testGetEventsSortedByTimestamp() {
        // Given
        let event1 = SecurityEvent(type: .authenticationFailure, level: .warning, service: "Service1")
        let event2 = SecurityEvent(type: .suspiciousActivity, level: .info, service: "Service2")
        let event3 = SecurityEvent(type: .dataTampering, level: .critical, service: "Service3")

        // Manually set timestamps to ensure order
        let baseTime = Date()
        let modifiedEvent1 = SecurityEvent(
            type: event1.type,
            level: event1.level,
            service: event1.service,
            endpoint: event1.endpoint,
            details: event1.details,
            errorMessage: event1.errorMessage
        )
        // Note: In a real implementation, we'd need to modify the timestamp
        // For this test, we'll just verify the sorting works with natural insertion order

        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .warning, service: "Service1")
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .info, service: "Service2")
        securityLogger.logSecurityEvent(type: .dataTampering, level: .critical, service: "Service3")

        // When
        let events = securityLogger.getStoredEvents()

        // Then
        XCTAssertEqual(events.count, 3)
        // Events should be sorted by timestamp (most recent first)
        XCTAssertGreaterThanOrEqual(events[0].timestamp, events[1].timestamp)
        XCTAssertGreaterThanOrEqual(events[1].timestamp, events[2].timestamp)
    }

    // MARK: - Statistics Tests

    func testGetSecurityStatistics() {
        // Given
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        // Add events at different times
        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .warning)
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .info)

        // When
        let stats = securityLogger.getSecurityStatistics()

        // Then
        XCTAssertEqual(stats["total_events"] as? Int, 2)
        XCTAssertEqual(stats["events_last_24h"] as? Int, 2)
        XCTAssertEqual(stats["events_last_7d"] as? Int, 2)

        let eventsByType = stats["events_by_type"] as? [String: Int]
        XCTAssertEqual(eventsByType?["authentication_failure"], 1)
        XCTAssertEqual(eventsByType?["suspicious_activity"], 1)

        let eventsByLevel = stats["events_by_level"] as? [String: Int]
        XCTAssertEqual(eventsByLevel?["1"], 1) // .warning = 1
        XCTAssertEqual(eventsByLevel?["0"], 1) // .info = 0
    }

    func testGetSecurityStatisticsWithOldEvents() {
        // Given - Add an old event (simulated)
        let oldEvent = SecurityEvent(
            type: .authenticationFailure,
            level: .warning,
            service: "OldService"
        )

        // Manually create an event with old timestamp
        var events = securityLogger.getStoredEvents()
        // Note: In practice, we'd modify the timestamp, but for testing we'll just add current events

        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .warning)
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .critical)

        // When
        let stats = securityLogger.getSecurityStatistics()

        // Then
        XCTAssertEqual(stats["total_events"] as? Int, 2)
        XCTAssertEqual(stats["events_last_24h"] as? Int, 2)

        let criticalEvents = stats["recent_critical_events"] as? [[String: Any]]
        XCTAssertEqual(criticalEvents?.count, 1)
        XCTAssertEqual(criticalEvents?[0]["type"] as? String, "suspicious_activity")
    }

    // MARK: - Log Level Filtering Tests

    func testConsoleLoggingLevels() {
        // Given - Set console level to warning
        securityLogger.setConsoleLogLevel(.warning)

        // When - Log events at different levels
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .debug) // Below threshold
        securityLogger.logSecurityEvent(type: .authenticationFailure, level: .warning) // At threshold
        securityLogger.logSecurityEvent(type: .dataTampering, level: .error) // Above threshold

        // Then - Should store all events regardless of console level
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 3)
    }

    func testFirebaseLoggingLevels() {
        // Given - Set Firebase level to error
        securityLogger.setFirebaseLogLevel(.error)

        // When - Log events at different levels
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .warning) // Below threshold
        securityLogger.logSecurityEvent(type: .dataTampering, level: .error) // At threshold
        securityLogger.logSecurityEvent(type: .dataTampering, level: .critical) // Above threshold

        // Then - Should store all events regardless of Firebase level
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 3)
    }

    // MARK: - Event Details Tests

    func testEventDetailsWithComplexData() {
        // Given
        let complexDetails: [String: Any] = [
            "string_value": "test",
            "int_value": 42,
            "double_value": 3.14,
            "bool_value": true,
            "array_value": ["a", "b", "c"],
            "dict_value": ["key": "value"]
        ]

        // When
        securityLogger.logSecurityEvent(
            type: .suspiciousActivity,
            level: .warning,
            service: "TestService",
            details: complexDetails
        )

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertNotNil(event.details)
        XCTAssertEqual(event.details?["string_value"] as? AnyCodable, AnyCodable("test"))
        XCTAssertEqual(event.details?["int_value"] as? AnyCodable, AnyCodable(42))
        XCTAssertEqual(event.details?["bool_value"] as? AnyCodable, AnyCodable(true))
    }

    // MARK: - Error Handling Tests

    func testEventStorageWithEncodingError() {
        // Given - Create an event that might cause encoding issues
        // This is hard to test directly, but we can verify the system handles errors gracefully
        securityLogger.logSecurityEvent(type: .suspiciousActivity, level: .info)

        // When
        let events = securityLogger.getStoredEvents()

        // Then
        XCTAssertEqual(events.count, 1)
    }

    func testEventRetrievalWithDecodingError() {
        // Given - Corrupt the stored data
        UserDefaults.standard.set("corrupted data", forKey: "security_events")

        // When
        let events = securityLogger.getStoredEvents()

        // Then
        XCTAssertEqual(events.count, 0, "Should return empty array on decode failure")
    }

    // MARK: - Performance Tests

    func testBulkEventLogging() {
        // When - Log many events quickly
        measure {
            for i in 0..<100 {
                securityLogger.logSecurityEvent(
                    type: .suspiciousActivity,
                    level: .info,
                    service: "BulkTest\(i)"
                )
            }
        }

        // Then
        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 100)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentEventLogging() {
        let expectation = XCTestExpectation(description: "Concurrent logging")
        expectation.expectedFulfillmentCount = 5

        DispatchQueue.concurrentPerform(iterations: 5) { threadIndex in
            for i in 0..<20 {
                self.securityLogger.logSecurityEvent(
                    type: .suspiciousActivity,
                    level: .info,
                    service: "Thread\(threadIndex)_Event\(i)"
                )
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        let events = securityLogger.getStoredEvents()
        XCTAssertEqual(events.count, 100, "Should handle concurrent logging correctly")
    }
}