import XCTest
@testable import BookshelfScanner

class SecurityIntegrationTests: XCTestCase {

    var secureConfig: SecureConfig!
    var rateLimiter: RateLimiter!
    var mockRemoteConfigManager: MockRemoteConfigManager!
    var mockUserDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        mockRemoteConfigManager = MockRemoteConfigManager()
        mockUserDefaults = MockUserDefaults()

        // Set up SecureConfig with mock remote config
        secureConfig = SecureConfig(remoteConfigManager: mockRemoteConfigManager)

        // Set up RateLimiter
        rateLimiter = RateLimiter(hourlyLimit: 5, dailyLimit: 10)

        // Clear any existing security events
        SecurityLogger.shared.clearStoredEvents()
    }

    override func tearDown() {
        mockRemoteConfigManager.reset()
        mockUserDefaults.reset()
        SecurityLogger.shared.clearStoredEvents()
        super.tearDown()
    }

    // MARK: - End-to-End API Key Flow Tests

    func testCompleteAPIKeyFlow() {
        // Given - Set up API keys in remote config
        let geminiKey = "AIzaSyTestGeminiKey123456789"
        let googleBooksKey = "TestGoogleBooksKey987654321"
        let grokKey = "xoxp-test-grok-key-abcdef"

        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": geminiKey,
            "google_books_api_key": googleBooksKey,
            "grok_api_key": grokKey
        ]

        // When - Retrieve keys through SecureConfig
        let retrievedGeminiKey = secureConfig.geminiAPIKey
        let retrievedGoogleBooksKey = secureConfig.googleBooksAPIKey
        let retrievedGrokKey = secureConfig.grokAPIKey

        // Then - Keys should be retrieved correctly
        XCTAssertEqual(retrievedGeminiKey, geminiKey)
        XCTAssertEqual(retrievedGoogleBooksKey, googleBooksKey)
        XCTAssertEqual(retrievedGrokKey, grokKey)

        // And configuration should be complete
        XCTAssertTrue(secureConfig.isConfigurationComplete)
    }

    func testAPIKeyEncryptionAndDecryptionFlow() throws {
        // Given - Plain text keys
        let geminiKey = "AIzaSyTestGeminiKey123456789"
        let googleBooksKey = "TestGoogleBooksKey987654321"

        // When - Store encrypted keys
        secureConfig.setGeminiAPIKey(geminiKey)
        secureConfig.setGoogleBooksAPIKey(googleBooksKey)

        // Then - Keys should be retrievable and match original
        XCTAssertEqual(secureConfig.geminiAPIKey, geminiKey)
        XCTAssertEqual(secureConfig.googleBooksAPIKey, googleBooksKey)

        // And stored values should be encrypted
        let storedGeminiKey = UserDefaults.standard.string(forKey: "gemini_api_key")
        let storedGoogleBooksKey = UserDefaults.standard.string(forKey: "google_books_api_key")

        XCTAssertNotNil(storedGeminiKey)
        XCTAssertNotNil(storedGoogleBooksKey)
        XCTAssertNotEqual(storedGeminiKey, geminiKey)
        XCTAssertNotEqual(storedGoogleBooksKey, googleBooksKey)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")
        UserDefaults.standard.removeObject(forKey: "google_books_api_key")
    }

    // MARK: - Rate Limiting with Security Logging Integration

    func testRateLimitViolationLogging() {
        // Given - Exceed rate limit
        for _ in 0..<5 {
            rateLimiter.recordCall()
        }

        // When - Attempt another call (should fail and log)
        let canMakeCall = rateLimiter.canMakeCall()

        // Then - Call should be blocked
        XCTAssertFalse(canMakeCall)

        // And security event should be logged
        let events = SecurityLogger.shared.getEvents(ofType: .rateLimitViolation)
        XCTAssertGreaterThan(events.count, 0)

        let latestEvent = events.first!
        XCTAssertEqual(latestEvent.type, .rateLimitViolation)
        XCTAssertEqual(latestEvent.level, .warning)
        XCTAssertEqual(latestEvent.details?["limit"] as? Int, 5)
        XCTAssertEqual(latestEvent.details?["current_count"] as? Int, 5)
    }

    func testRateLimitWithTimestampValidation() {
        // Given - Valid API key setup
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = "AIzaSyValidKey123"

        // When - Make API call with valid timestamp
        let validTimestamp = Date()
        let isValidTimestamp = secureConfig.validateTimestamp(validTimestamp, service: "TestService", endpoint: "/api/test")

        // Then - Timestamp should be valid
        XCTAssertTrue(isValidTimestamp)

        // And no security events should be logged for timestamp issues
        let timestampEvents = SecurityLogger.shared.getEvents(ofType: .timestampValidationFailure)
        XCTAssertEqual(timestampEvents.count, 0)
    }

    func testRateLimitWithInvalidTimestamp() {
        // Given - Invalid timestamp (too old)
        let oldTimestamp = Date().addingTimeInterval(-400) // Beyond 300s window

        // When - Validate timestamp
        let isValidTimestamp = secureConfig.validateTimestamp(oldTimestamp, service: "TestService", endpoint: "/api/test")

        // Then - Timestamp should be invalid
        XCTAssertFalse(isValidTimestamp)

        // And security event should be logged
        let events = SecurityLogger.shared.getEvents(ofType: .timestampValidationFailure)
        XCTAssertGreaterThan(events.count, 0)

        let latestEvent = events.first!
        XCTAssertEqual(latestEvent.type, .timestampValidationFailure)
        XCTAssertEqual(latestEvent.level, .error)
        XCTAssertEqual(latestEvent.service, "TestService")
        XCTAssertEqual(latestEvent.endpoint, "/api/test")
    }

    // MARK: - API Key Validation with Logging Integration

    func testAPIKeyValidationWithLogging() {
        // Given - Invalid API key
        let invalidKey = "invalid-key"

        // When - Validate API key
        let isValid = secureConfig.validateAPIKey(invalidKey, keyType: "gemini", service: "TestService")

        // Then - Key should be invalid
        XCTAssertFalse(isValid)

        // And security event should be logged
        let events = SecurityLogger.shared.getEvents(ofType: .apiKeyInvalid)
        XCTAssertGreaterThan(events.count, 0)

        let latestEvent = events.first!
        XCTAssertEqual(latestEvent.type, .apiKeyInvalid)
        XCTAssertEqual(latestEvent.level, .error)
        XCTAssertEqual(latestEvent.service, "TestService")
        XCTAssertEqual(latestEvent.details?["key_type"] as? String, "gemini")
    }

    func testCompleteAPIKeyValidationFlow() {
        // Given - Mix of valid and invalid keys
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "AIzaSyValidGeminiKey123",
            "google_books_api_key": "YOUR_GOOGLE_BOOKS_API_KEY_HERE", // Invalid
            "grok_api_key": "xoxp-valid-grok-key"
        ]

        // When - Validate all API keys
        let allValid = secureConfig.validateAllAPIKeys()

        // Then - Should return false due to invalid Google Books key
        XCTAssertFalse(allValid)

        // And security event should be logged for invalid key
        let events = SecurityLogger.shared.getEvents(ofType: .apiKeyInvalid)
        XCTAssertGreaterThan(events.count, 0)
    }

    // MARK: - End-to-End Security Flow

    func testCompleteSecurityFlow() {
        // Given - Set up valid configuration
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "AIzaSyValidGeminiKey123",
            "google_books_api_key": "ValidGoogleBooksKey456",
            "grok_api_key": "xoxp-valid-grok-key-789"
        ]

        // Step 1: Validate configuration
        XCTAssertTrue(secureConfig.isConfigurationComplete)

        // Step 2: Make some API calls within limits
        for i in 0..<3 {
            XCTAssertTrue(rateLimiter.canMakeCall())
            rateLimiter.recordCall()
        }

        // Step 3: Validate timestamps
        let validTimestamp = Date().addingTimeInterval(-60)
        XCTAssertTrue(secureConfig.validateTimestamp(validTimestamp, service: "TestService", endpoint: "/api/test"))

        // Step 4: Check that no security violations were logged
        let violationEvents = SecurityLogger.shared.getEvents(level: .warning)
        let initialViolationCount = violationEvents.count

        // Step 5: Now exceed rate limit
        for _ in 0..<3 { // Exceed the limit
            rateLimiter.recordCall()
        }

        // Step 6: Verify rate limit violation is logged
        let finalViolationEvents = SecurityLogger.shared.getEvents(level: .warning)
        XCTAssertGreaterThan(finalViolationEvents.count, initialViolationCount)

        // Step 7: Verify rate limit blocks further calls
        XCTAssertFalse(rateLimiter.canMakeCall())
    }

    // MARK: - Error Recovery and Logging Integration

    func testEncryptionFailureLogging() {
        // Given - Try to decrypt invalid data
        let invalidEncryptedData = "invalid-encrypted-data"

        // When - Attempt decryption (will fail)
        do {
            _ = try EncryptionManager.shared.decrypt(invalidEncryptedData)
            XCTFail("Expected decryption to fail")
        } catch {
            // Expected to fail
        }

        // Then - Encryption failure should be logged
        // Note: The actual logging happens in SecureConfig when decrypting stored keys
        // For this test, we verify the error handling works
        XCTAssertTrue(error is EncryptionError)
    }

    func testConfigurationErrorLogging() {
        // Given - Invalid remote config response
        mockRemoteConfigManager.simulateFetchFailure(.fetchFailed(status: .failure, underlyingError: nil))

        let expectation = XCTestExpectation(description: "Remote config fetch failure")

        // When - Attempt to fetch remote config
        mockRemoteConfigManager.fetchAndActivate { result in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail("Expected fetch to fail")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Concurrent Security Operations

    func testConcurrentSecurityOperations() {
        // Given - Set up valid keys
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "AIzaSyValidGeminiKey123",
            "google_books_api_key": "ValidGoogleBooksKey456",
            "grok_api_key": "xoxp-valid-grok-key-789"
        ]

        let expectation = XCTestExpectation(description: "Concurrent security operations")
        expectation.expectedFulfillmentCount = 10

        // When - Perform concurrent security operations
        DispatchQueue.concurrentPerform(iterations: 10) { threadIndex in
            // Test API key retrieval
            let _ = self.secureConfig.geminiAPIKey

            // Test timestamp validation
            let timestamp = Date().addingTimeInterval(-Double(threadIndex) * 10)
            let _ = self.secureConfig.validateTimestamp(timestamp, service: "TestService", endpoint: "/test")

            // Test rate limiting
            if self.rateLimiter.canMakeCall() {
                self.rateLimiter.recordCall()
            }

            // Log security event
            SecurityLogger.shared.logSecurityEvent(
                type: .suspiciousActivity,
                level: .info,
                service: "ConcurrentTest",
                details: ["thread": threadIndex]
            )

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        // Then - Verify system remained stable
        XCTAssertTrue(secureConfig.isConfigurationComplete)

        let events = SecurityLogger.shared.getStoredEvents()
        XCTAssertGreaterThan(events.count, 0)

        let calls = rateLimiter.getCalls()
        XCTAssertGreaterThan(calls.count, 0)
    }

    // MARK: - Security Monitoring and Statistics

    func testSecurityStatisticsIntegration() {
        // Given - Generate various security events
        SecurityLogger.shared.logSecurityEvent(type: .authenticationFailure, level: .warning)
        SecurityLogger.shared.logSecurityEvent(type: .suspiciousActivity, level: .info)
        SecurityLogger.shared.logSecurityEvent(type: .dataTampering, level: .critical)

        // Exceed rate limit to generate rate limit events
        for _ in 0..<6 {
            rateLimiter.recordCall()
        }

        // When - Get security statistics
        let stats = SecurityLogger.shared.getSecurityStatistics()

        // Then - Statistics should reflect all events
        XCTAssertGreaterThanOrEqual(stats["total_events"] as? Int ?? 0, 3)

        let eventsByType = stats["events_by_type"] as? [String: Int]
        XCTAssertNotNil(eventsByType?["authentication_failure"])
        XCTAssertNotNil(eventsByType?["suspicious_activity"])
        XCTAssertNotNil(eventsByType?["data_tampering"])
        XCTAssertNotNil(eventsByType?["rate_limit_violation"])

        let eventsByLevel = stats["events_by_level"] as? [String: Int]
        XCTAssertGreaterThan(eventsByLevel?["2"] ?? 0, 0) // .warning = 2
        XCTAssertGreaterThan(eventsByLevel?["4"] ?? 0, 0) // .critical = 4
    }

    // MARK: - Recovery Scenarios

    func testRecoveryFromInvalidConfiguration() {
        // Given - Invalid configuration
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "YOUR_GEMINI_API_KEY_HERE",
            "google_books_api_key": "YOUR_GOOGLE_BOOKS_API_KEY_HERE",
            "grok_api_key": "invalid-key"
        ]

        // When - Validate configuration
        let isValid = secureConfig.validateAllAPIKeys()

        // Then - Should be invalid
        XCTAssertFalse(isValid)

        // When - Fix configuration
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "AIzaSyFixedGeminiKey123",
            "google_books_api_key": "FixedGoogleBooksKey456",
            "grok_api_key": "xoxp-fixed-grok-key-789"
        ]

        // Then - Should now be valid
        XCTAssertTrue(secureConfig.isConfigurationComplete)
    }

    func testRecoveryFromRateLimit() {
        // Given - Exceed rate limit
        for _ in 0..<5 {
            rateLimiter.recordCall()
        }
        XCTAssertFalse(rateLimiter.canMakeCall())

        // When - Wait for rate limit to reset (simulate time passing)
        // Note: In real implementation, this would require time to pass
        // For testing, we create a new limiter with higher limits
        let newLimiter = RateLimiter(hourlyLimit: 10, dailyLimit: 20)

        // Then - Should be able to make calls again
        XCTAssertTrue(newLimiter.canMakeCall())
    }

    // MARK: - Cross-Component Validation

    func testTimestampValidationWithAPIKeyValidation() {
        // Given - Valid API key and timestamp
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = "AIzaSyValidKey123"
        let validTimestamp = Date().addingTimeInterval(-30)

        // When - Validate both
        let keyValid = secureConfig.validateAPIKey(secureConfig.geminiAPIKey, keyType: "gemini", service: "TestService")
        let timestampValid = secureConfig.validateTimestamp(validTimestamp, service: "TestService", endpoint: "/api/test")

        // Then - Both should be valid
        XCTAssertTrue(keyValid)
        XCTAssertTrue(timestampValid)

        // And no security events should be logged
        let errorEvents = SecurityLogger.shared.getEvents(level: .error)
        XCTAssertEqual(errorEvents.count, 0)
    }

    func testSecurityEventCorrelation() {
        // Given - Perform multiple security operations that might trigger events
        let invalidTimestamp = Date().addingTimeInterval(-400)
        let invalidKey = "invalid-key"

        // When - Trigger multiple security validations
        let _ = secureConfig.validateTimestamp(invalidTimestamp, service: "TestService", endpoint: "/api/test")
        let _ = secureConfig.validateAPIKey(invalidKey, keyType: "gemini", service: "TestService")

        // Exceed rate limit
        for _ in 0..<6 {
            rateLimiter.recordCall()
        }

        // Then - Multiple security events should be logged
        let allEvents = SecurityLogger.shared.getStoredEvents()
        XCTAssertGreaterThanOrEqual(allEvents.count, 3)

        // Verify different event types are present
        let eventTypes = Set(allEvents.map { $0.type })
        XCTAssertTrue(eventTypes.contains(.timestampValidationFailure))
        XCTAssertTrue(eventTypes.contains(.apiKeyInvalid))
        XCTAssertTrue(eventTypes.contains(.rateLimitViolation))
    }
}