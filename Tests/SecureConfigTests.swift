import XCTest
@testable import BookshelfScanner

class SecureConfigTests: XCTestCase {

    var secureConfig: SecureConfig!
    var mockRemoteConfigManager: MockRemoteConfigManager!
    var mockUserDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        mockRemoteConfigManager = MockRemoteConfigManager()
        mockUserDefaults = MockUserDefaults()
        secureConfig = SecureConfig(remoteConfigManager: mockRemoteConfigManager)
    }

    override func tearDown() {
        mockRemoteConfigManager.reset()
        mockUserDefaults.reset()
        super.tearDown()
    }

    // MARK: - API Key Retrieval Tests

    func testGeminiAPIKeyFromRemoteConfig() {
        // Given
        let expectedKey = "AIzaSyTestGeminiKey123"
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = expectedKey

        // When
        let actualKey = secureConfig.geminiAPIKey

        // Then
        XCTAssertEqual(actualKey, expectedKey)
        XCTAssertEqual(mockRemoteConfigManager.fetchAndActivateCallCount, 0, "Should not fetch for sync property")
    }

    func testGeminiAPIKeyFromUserDefaults() {
        // Given - Remote config returns empty, UserDefaults has encrypted key
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = ""
        let plainKey = "AIzaSyTestGeminiKey123"
        let encryptedKey = try! EncryptionManager.shared.encrypt(plainKey)
        UserDefaults.standard.set(encryptedKey, forKey: "gemini_api_key")

        // When
        let actualKey = secureConfig.geminiAPIKey

        // Then
        XCTAssertEqual(actualKey, plainKey)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")
    }

    func testGeminiAPIKeyFromEnvironment() {
        // Given - Remote config and UserDefaults empty, environment has key
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = ""
        let expectedKey = "AIzaSyTestGeminiKey123"
        setenv("GEMINI_API_KEY", expectedKey, 1)

        // When
        let actualKey = secureConfig.geminiAPIKey

        // Then
        XCTAssertEqual(actualKey, expectedKey)

        // Cleanup
        unsetenv("GEMINI_API_KEY")
    }

    func testGeminiAPIKeyFallback() {
        // Given - All sources empty
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = ""

        // When
        let actualKey = secureConfig.geminiAPIKey

        // Then
        XCTAssertEqual(actualKey, "YOUR_GEMINI_API_KEY_HERE")
    }

    func testGoogleBooksAPIKeyRetrieval() {
        // Given
        let expectedKey = "TestGoogleBooksKey123"
        mockRemoteConfigManager.mockStringValues["google_books_api_key"] = expectedKey

        // When
        let actualKey = secureConfig.googleBooksAPIKey

        // Then
        XCTAssertEqual(actualKey, expectedKey)
    }

    func testGrokAPIKeyRetrieval() {
        // Given
        let expectedKey = "xoxp-test-grok-key"
        mockRemoteConfigManager.mockStringValues["grok_api_key"] = expectedKey

        // When
        let actualKey = secureConfig.grokAPIKey

        // Then
        XCTAssertEqual(actualKey, expectedKey)
    }

    func testRevenueCatAPIKeyRetrieval() {
        // Given
        let expectedKey = "TestRevenueCatKey123"
        mockRemoteConfigManager.mockStringValues["revenuecat_api_key"] = expectedKey

        // When
        let actualKey = secureConfig.revenueCatAPIKey

        // Then
        XCTAssertEqual(actualKey, expectedKey)
    }

    func testRevenueCatAPIKeyNilWhenNotConfigured() {
        // Given - No key configured
        mockRemoteConfigManager.mockStringValues["revenuecat_api_key"] = ""

        // When
        let actualKey = secureConfig.revenueCatAPIKey

        // Then
        XCTAssertNil(actualKey)
    }

    // MARK: - Async API Key Retrieval Tests

    func testGetGeminiAPIKeyAsync() {
        // Given
        let expectedKey = "AIzaSyAsyncGeminiKey123"
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = expectedKey

        let expectation = XCTestExpectation(description: "Async key retrieval")

        // When
        secureConfig.getGeminiAPIKeyAsync { key in
            // Then
            XCTAssertEqual(key, expectedKey)
            XCTAssertEqual(self.mockRemoteConfigManager.fetchAndActivateCallCount, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetGoogleBooksAPIKeyAsync() {
        // Given
        let expectedKey = "AsyncGoogleBooksKey123"
        mockRemoteConfigManager.mockStringValues["google_books_api_key"] = expectedKey

        let expectation = XCTestExpectation(description: "Async Google Books key retrieval")

        // When
        secureConfig.getGoogleBooksAPIKeyAsync { key in
            // Then
            XCTAssertEqual(key, expectedKey)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetGrokAPIKeyAsync() {
        // Given
        let expectedKey = "xoxp-async-grok-key"
        mockRemoteConfigManager.mockStringValues["grok_api_key"] = expectedKey

        let expectation = XCTestExpectation(description: "Async Grok key retrieval")

        // When
        secureConfig.getGrokAPIKeyAsync { key in
            // Then
            XCTAssertEqual(key, expectedKey)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetRevenueCatAPIKeyAsync() {
        // Given
        let expectedKey = "AsyncRevenueCatKey123"
        mockRemoteConfigManager.mockStringValues["revenuecat_api_key"] = expectedKey

        let expectation = XCTestExpectation(description: "Async RevenueCat key retrieval")

        // When
        secureConfig.getRevenueCatAPIKeyAsync { key in
            // Then
            XCTAssertEqual(key, expectedKey)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - API Key Storage Tests

    func testSetGeminiAPIKey() {
        // Given
        let testKey = "AIzaSyNewGeminiKey123"

        // When
        secureConfig.setGeminiAPIKey(testKey)

        // Then
        let storedEncryptedKey = UserDefaults.standard.string(forKey: "gemini_api_key")
        XCTAssertNotNil(storedEncryptedKey)
        XCTAssertNotEqual(storedEncryptedKey, testKey, "Key should be encrypted")

        // Verify we can decrypt it back
        let decryptedKey = try! EncryptionManager.shared.decrypt(storedEncryptedKey!)
        XCTAssertEqual(decryptedKey, testKey)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")
    }

    func testSetGoogleBooksAPIKey() {
        // Given
        let testKey = "NewGoogleBooksKey123"

        // When
        secureConfig.setGoogleBooksAPIKey(testKey)

        // Then
        let storedEncryptedKey = UserDefaults.standard.string(forKey: "google_books_api_key")
        XCTAssertNotNil(storedEncryptedKey)

        let decryptedKey = try! EncryptionManager.shared.decrypt(storedEncryptedKey!)
        XCTAssertEqual(decryptedKey, testKey)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "google_books_api_key")
    }

    func testSetGrokAPIKey() {
        // Given
        let testKey = "xoxp-new-grok-key"

        // When
        secureConfig.setGrokAPIKey(testKey)

        // Then
        let storedEncryptedKey = UserDefaults.standard.string(forKey: "grok_api_key")
        XCTAssertNotNil(storedEncryptedKey)

        let decryptedKey = try! EncryptionManager.shared.decrypt(storedEncryptedKey!)
        XCTAssertEqual(decryptedKey, testKey)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "grok_api_key")
    }

    func testClearAllKeys() {
        // Given - Set some keys
        secureConfig.setGeminiAPIKey("test1")
        secureConfig.setGoogleBooksAPIKey("test2")
        secureConfig.setGrokAPIKey("test3")

        // Verify they're stored
        XCTAssertNotNil(UserDefaults.standard.string(forKey: "gemini_api_key"))
        XCTAssertNotNil(UserDefaults.standard.string(forKey: "google_books_api_key"))
        XCTAssertNotNil(UserDefaults.standard.string(forKey: "grok_api_key"))

        // When
        secureConfig.clearAllKeys()

        // Then
        XCTAssertNil(UserDefaults.standard.string(forKey: "gemini_api_key"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "google_books_api_key"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "grok_api_key"))
    }

    // MARK: - API Key Validation Tests

    func testHasValidGeminiKey() {
        // Valid key
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = "AIzaSyValidGeminiKey123"
        XCTAssertTrue(secureConfig.hasValidGeminiKey)

        // Invalid - placeholder
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = "YOUR_GEMINI_API_KEY_HERE"
        XCTAssertFalse(secureConfig.hasValidGeminiKey)

        // Invalid - too short
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = "short"
        XCTAssertFalse(secureConfig.hasValidGeminiKey)

        // Invalid - empty
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = ""
        XCTAssertFalse(secureConfig.hasValidGeminiKey)
    }

    func testHasValidGoogleBooksKey() {
        // Valid key
        mockRemoteConfigManager.mockStringValues["google_books_api_key"] = "ValidGoogleBooksKey123"
        XCTAssertTrue(secureConfig.hasValidGoogleBooksKey)

        // Invalid - placeholder
        mockRemoteConfigManager.mockStringValues["google_books_api_key"] = "YOUR_GOOGLE_BOOKS_API_KEY_HERE"
        XCTAssertFalse(secureConfig.hasValidGoogleBooksKey)
    }

    func testHasValidGrokKey() {
        // Valid key
        mockRemoteConfigManager.mockStringValues["grok_api_key"] = "xoxp-valid-grok-key"
        XCTAssertTrue(secureConfig.hasValidGrokKey)

        // Invalid - wrong prefix
        mockRemoteConfigManager.mockStringValues["grok_api_key"] = "invalid-grok-key"
        XCTAssertFalse(secureConfig.hasValidGrokKey)
    }

    func testIsConfigurationComplete() {
        // All valid
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "AIzaSyValidGeminiKey123",
            "google_books_api_key": "ValidGoogleBooksKey123",
            "grok_api_key": "xoxp-valid-grok-key"
        ]
        XCTAssertTrue(secureConfig.isConfigurationComplete)

        // One invalid
        mockRemoteConfigManager.mockStringValues["gemini_api_key"] = "YOUR_GEMINI_API_KEY_HERE"
        XCTAssertFalse(secureConfig.isConfigurationComplete)
    }

    // MARK: - Timestamp Validation Tests

    func testValidateTimestampWithinWindow() {
        // Given
        let now = Date()
        let recentTimestamp = now.addingTimeInterval(-60) // 1 minute ago

        // When
        let isValid = secureConfig.validateTimestamp(recentTimestamp, service: "TestService", endpoint: "/test")

        // Then
        XCTAssertTrue(isValid)
    }

    func testValidateTimestampOutsideWindow() {
        // Given
        let now = Date()
        let oldTimestamp = now.addingTimeInterval(-400) // 400 seconds ago (beyond 300s window)

        // When
        let isValid = secureConfig.validateTimestamp(oldTimestamp, service: "TestService", endpoint: "/test")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateTimestampNil() {
        // When
        let isValid = secureConfig.validateTimestamp(nil, service: "TestService", endpoint: "/test")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateTimestampStringValid() {
        // Given
        let now = Date()
        let recentTimestamp = now.addingTimeInterval(-60)
        let dateFormatter = ISO8601DateFormatter()
        let timestampString = dateFormatter.string(from: recentTimestamp)

        // When
        let isValid = secureConfig.validateTimestampString(timestampString, service: "TestService", endpoint: "/test")

        // Then
        XCTAssertTrue(isValid)
    }

    func testValidateTimestampStringInvalidFormat() {
        // Given
        let invalidTimestampString = "invalid-timestamp"

        // When
        let isValid = secureConfig.validateTimestampString(invalidTimestampString, service: "TestService", endpoint: "/test")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateTimestampStringNil() {
        // When
        let isValid = secureConfig.validateTimestampString(nil, service: "TestService", endpoint: "/test")

        // Then
        XCTAssertFalse(isValid)
    }

    // MARK: - Request Time Window Tests

    func testRequestTimeWindowSeconds() {
        // Default value should be 300 (5 minutes)
        XCTAssertEqual(secureConfig.requestTimeWindowSeconds, 300.0)
    }

    func testSetRequestTimeWindowSeconds() {
        // Given
        let newWindow: TimeInterval = 600.0 // 10 minutes

        // When
        secureConfig.setRequestTimeWindowSeconds(newWindow)

        // Then
        XCTAssertEqual(secureConfig.requestTimeWindowSeconds, newWindow)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "request_time_window_seconds")
    }

    // MARK: - API Key Validation with Logging Tests

    func testValidateAPIKeyValid() {
        // When
        let isValid = secureConfig.validateAPIKey("AIzaSyValidGeminiKey123", keyType: "gemini", service: "TestService")

        // Then
        XCTAssertTrue(isValid)
    }

    func testValidateAPIKeyNil() {
        // When
        let isValid = secureConfig.validateAPIKey(nil, keyType: "gemini", service: "TestService")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateAPIKeyEmpty() {
        // When
        let isValid = secureConfig.validateAPIKey("", keyType: "gemini", service: "TestService")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateAPIKeyPlaceholder() {
        // When
        let isValid = secureConfig.validateAPIKey("YOUR_GEMINI_API_KEY_HERE", keyType: "gemini", service: "TestService")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateAPIKeyTooShort() {
        // When
        let isValid = secureConfig.validateAPIKey("short", keyType: "gemini", service: "TestService")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateAPIKeyInvalidGeminiFormat() {
        // When
        let isValid = secureConfig.validateAPIKey("InvalidGeminiKey123", keyType: "gemini", service: "TestService")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateAPIKeyInvalidGrokFormat() {
        // When
        let isValid = secureConfig.validateAPIKey("invalid-grok-key", keyType: "grok", service: "TestService")

        // Then
        XCTAssertFalse(isValid)
    }

    func testValidateAllAPIKeys() {
        // Given - All valid keys
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "AIzaSyValidGeminiKey123",
            "google_books_api_key": "ValidGoogleBooksKey123",
            "grok_api_key": "xoxp-valid-grok-key"
        ]

        // When
        let allValid = secureConfig.validateAllAPIKeys()

        // Then
        XCTAssertTrue(allValid)
    }

    func testValidateAllAPIKeysWithInvalid() {
        // Given - One invalid key
        mockRemoteConfigManager.mockStringValues = [
            "gemini_api_key": "YOUR_GEMINI_API_KEY_HERE", // Invalid
            "google_books_api_key": "ValidGoogleBooksKey123",
            "grok_api_key": "xoxp-valid-grok-key"
        ]

        // When
        let allValid = secureConfig.validateAllAPIKeys()

        // Then
        XCTAssertFalse(allValid)
    }

    // MARK: - Environment Detection Tests

    func testIsDevelopment() {
        #if DEBUG
        XCTAssertTrue(secureConfig.isDevelopment)
        #else
        XCTAssertFalse(secureConfig.isDevelopment)
        #endif
    }

    func testIsProduction() {
        #if DEBUG
        XCTAssertFalse(secureConfig.isProduction)
        #else
        XCTAssertTrue(secureConfig.isProduction)
        #endif
    }
}