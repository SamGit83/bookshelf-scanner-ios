import XCTest
@testable import BookshelfScanner

class MockRemoteConfigManager: RemoteConfigManagerProtocol {
    var mockStrings: [String: String] = [:]
    var fetchAndActivateResult: Result<Void, RemoteConfigError> = .success(())

    func getString(forKey key: String) -> String {
        return mockStrings[key] ?? ""
    }

    func fetchAndActivate(completion: @escaping (Result<Void, RemoteConfigError>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            completion(self.fetchAndActivateResult)
        }
    }
}

class SecureConfigTests: XCTestCase {

    var mockRemoteConfigManager: MockRemoteConfigManager!
    var secureConfig: SecureConfig!

    override func setUp() {
        super.setUp()
        mockRemoteConfigManager = MockRemoteConfigManager()
        secureConfig = SecureConfig(remoteConfigManager: mockRemoteConfigManager)

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")
        UserDefaults.standard.removeObject(forKey: "google_books_api_key")
        UserDefaults.standard.removeObject(forKey: "grok_api_key")
        UserDefaults.standard.removeObject(forKey: "revenuecat_api_key")
        UserDefaults.standard.synchronize()
    }

    override func tearDown() {
        mockRemoteConfigManager = nil
        secureConfig = nil
        super.tearDown()
    }

    // MARK: - API Key Retrieval Tests

    func testGeminiAPIKeyFromRemoteConfig() {
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "remote_gemini_key"
        XCTAssertEqual(secureConfig.geminiAPIKey, "remote_gemini_key")
    }

    func testGeminiAPIKeyFromUserDefaults() {
        UserDefaults.standard.set("userdefaults_gemini_key", forKey: "gemini_api_key")
        XCTAssertEqual(secureConfig.geminiAPIKey, "userdefaults_gemini_key")
    }

    func testGeminiAPIKeyFromEnvironment() {
        setenv("GEMINI_API_KEY", "env_gemini_key", 1)
        XCTAssertEqual(secureConfig.geminiAPIKey, "env_gemini_key")
        unsetenv("GEMINI_API_KEY")
    }

    func testGeminiAPIKeyFallbackToPlaceholder() {
        XCTAssertEqual(secureConfig.geminiAPIKey, "YOUR_GEMINI_API_KEY_HERE")
    }

    func testGoogleBooksAPIKeyFromRemoteConfig() {
        mockRemoteConfigManager.mockStrings["google_books_api_key"] = "remote_google_key"
        XCTAssertEqual(secureConfig.googleBooksAPIKey, "remote_google_key")
    }

    func testGoogleBooksAPIKeyFromUserDefaults() {
        UserDefaults.standard.set("userdefaults_google_key", forKey: "google_books_api_key")
        XCTAssertEqual(secureConfig.googleBooksAPIKey, "userdefaults_google_key")
    }

    func testGoogleBooksAPIKeyFromEnvironment() {
        setenv("GOOGLE_BOOKS_API_KEY", "env_google_key", 1)
        XCTAssertEqual(secureConfig.googleBooksAPIKey, "env_google_key")
        unsetenv("GOOGLE_BOOKS_API_KEY")
    }

    func testGoogleBooksAPIKeyFallbackToPlaceholder() {
        XCTAssertEqual(secureConfig.googleBooksAPIKey, "YOUR_GOOGLE_BOOKS_API_KEY_HERE")
    }

    func testGrokAPIKeyFromRemoteConfig() {
        mockRemoteConfigManager.mockStrings["grok_api_key"] = "remote_grok_key"
        XCTAssertEqual(secureConfig.grokAPIKey, "remote_grok_key")
    }

    func testGrokAPIKeyFromUserDefaults() {
        UserDefaults.standard.set("userdefaults_grok_key", forKey: "grok_api_key")
        XCTAssertEqual(secureConfig.grokAPIKey, "userdefaults_grok_key")
    }

    func testGrokAPIKeyFromEnvironment() {
        setenv("GROK_API_KEY", "env_grok_key", 1)
        XCTAssertEqual(secureConfig.grokAPIKey, "env_grok_key")
        unsetenv("GROK_API_KEY")
    }

    func testGrokAPIKeyFallbackToPlaceholder() {
        XCTAssertEqual(secureConfig.grokAPIKey, "YOUR_GROK_API_KEY_HERE")
    }

    func testRevenueCatAPIKeyFromRemoteConfig() {
        mockRemoteConfigManager.mockStrings["revenuecat_api_key"] = "remote_revenuecat_key"
        XCTAssertEqual(secureConfig.revenueCatAPIKey, "remote_revenuecat_key")
    }

    func testRevenueCatAPIKeyFromUserDefaults() {
        UserDefaults.standard.set("userdefaults_revenuecat_key", forKey: "revenuecat_api_key")
        XCTAssertEqual(secureConfig.revenueCatAPIKey, "userdefaults_revenuecat_key")
    }

    func testRevenueCatAPIKeyFromEnvironment() {
        setenv("REVENUECAT_API_KEY", "env_revenuecat_key", 1)
        XCTAssertEqual(secureConfig.revenueCatAPIKey, "env_revenuecat_key")
        unsetenv("REVENUECAT_API_KEY")
    }

    func testRevenueCatAPIKeyNoFallback() {
        XCTAssertNil(secureConfig.revenueCatAPIKey)
    }

    // MARK: - Async API Key Retrieval Tests

    func testGetGeminiAPIKeyAsync() {
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "async_gemini_key"

        let expectation = self.expectation(description: "Async Gemini key retrieval")

        secureConfig.getGeminiAPIKeyAsync { key in
            XCTAssertEqual(key, "async_gemini_key")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testGetGoogleBooksAPIKeyAsync() {
        mockRemoteConfigManager.mockStrings["google_books_api_key"] = "async_google_key"

        let expectation = self.expectation(description: "Async Google Books key retrieval")

        secureConfig.getGoogleBooksAPIKeyAsync { key in
            XCTAssertEqual(key, "async_google_key")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testGetGrokAPIKeyAsync() {
        mockRemoteConfigManager.mockStrings["grok_api_key"] = "async_grok_key"

        let expectation = self.expectation(description: "Async Grok key retrieval")

        secureConfig.getGrokAPIKeyAsync { key in
            XCTAssertEqual(key, "async_grok_key")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testGetRevenueCatAPIKeyAsync() {
        mockRemoteConfigManager.mockStrings["revenuecat_api_key"] = "async_revenuecat_key"

        let expectation = self.expectation(description: "Async RevenueCat key retrieval")

        secureConfig.getRevenueCatAPIKeyAsync { key in
            XCTAssertEqual(key, "async_revenuecat_key")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - Validation Tests

    func testHasValidGeminiKey() {
        // Valid key
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "AIzaSyD1234567890abcdefghijklmnopqrstuvw"
        XCTAssertTrue(secureConfig.hasValidGeminiKey)

        // Invalid: too short
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "short"
        XCTAssertFalse(secureConfig.hasValidGeminiKey)

        // Invalid: contains placeholder
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "YOUR_GEMINI_API_KEY_HERE"
        XCTAssertFalse(secureConfig.hasValidGeminiKey)
    }

    func testHasValidGoogleBooksKey() {
        // Valid key
        mockRemoteConfigManager.mockStrings["google_books_api_key"] = "AIzaSyD1234567890abcdefghijklmnopqrstuvw"
        XCTAssertTrue(secureConfig.hasValidGoogleBooksKey)

        // Invalid
        mockRemoteConfigManager.mockStrings["google_books_api_key"] = "YOUR_GOOGLE_BOOKS_API_KEY_HERE"
        XCTAssertFalse(secureConfig.hasValidGoogleBooksKey)
    }

    func testHasValidGrokKey() {
        // Valid key
        mockRemoteConfigManager.mockStrings["grok_api_key"] = "xai-1234567890abcdefghijklmnopqrstuvw"
        XCTAssertTrue(secureConfig.hasValidGrokKey)

        // Invalid
        mockRemoteConfigManager.mockStrings["grok_api_key"] = "YOUR_GROK_API_KEY_HERE"
        XCTAssertFalse(secureConfig.hasValidGrokKey)
    }

    func testIsConfigurationComplete() {
        // All valid
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "AIzaSyD1234567890abcdefghijklmnopqrstuvw"
        mockRemoteConfigManager.mockStrings["google_books_api_key"] = "AIzaSyD1234567890abcdefghijklmnopqrstuvw"
        mockRemoteConfigManager.mockStrings["grok_api_key"] = "xai-1234567890abcdefghijklmnopqrstuvw"
        XCTAssertTrue(secureConfig.isConfigurationComplete)

        // One invalid
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "invalid"
        XCTAssertFalse(secureConfig.isConfigurationComplete)
    }

    // MARK: - Configuration Management Tests

    func testSetAndClearKeys() {
        secureConfig.setGeminiAPIKey("test_gemini")
        secureConfig.setGoogleBooksAPIKey("test_google")
        secureConfig.setGrokAPIKey("test_grok")

        XCTAssertEqual(UserDefaults.standard.string(forKey: "gemini_api_key"), "test_gemini")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "google_books_api_key"), "test_google")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "grok_api_key"), "test_grok")

        secureConfig.clearAllKeys()

        XCTAssertNil(UserDefaults.standard.string(forKey: "gemini_api_key"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "google_books_api_key"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "grok_api_key"))
    }

    // MARK: - Environment Detection Tests

    func testIsDevelopment() {
        #if DEBUG
        XCTAssertTrue(secureConfig.isDevelopment)
        #else
        XCTAssertFalse(secureConfig.isDevelopment)
        #endif
    }

    func testIsTestFlight() {
        // Hard to test without mocking bundle, but basic check
        XCTAssertNotNil(secureConfig.isTestFlight) // Just ensure it doesn't crash
    }

    func testIsProduction() {
        #if DEBUG
        XCTAssertFalse(secureConfig.isProduction)
        #else
        XCTAssertTrue(secureConfig.isProduction)
        #endif
    }
}