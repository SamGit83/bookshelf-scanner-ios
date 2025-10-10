import XCTest
@testable import BookshelfScanner

class RemoteConfigIntegrationTests: XCTestCase {

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

    // MARK: - Network Failure and Fallback Tests

    func testSecureConfigFallbackWhenRemoteConfigFails() {
        // Simulate Remote Config failure
        mockRemoteConfigManager.fetchAndActivateResult = .failure(.fetchFailed(status: .failure, underlyingError: nil))

        // Set UserDefaults fallback
        UserDefaults.standard.set("fallback_gemini_key", forKey: "gemini_api_key")
        UserDefaults.standard.set("fallback_google_key", forKey: "google_books_api_key")
        UserDefaults.standard.set("fallback_grok_key", forKey: "grok_api_key")

        // Even though Remote Config fails, properties should return UserDefaults values
        XCTAssertEqual(secureConfig.geminiAPIKey, "fallback_gemini_key")
        XCTAssertEqual(secureConfig.googleBooksAPIKey, "fallback_google_key")
        XCTAssertEqual(secureConfig.grokAPIKey, "fallback_grok_key")
    }

    func testSecureConfigAsyncFallbackWhenRemoteConfigFails() {
        // Simulate Remote Config failure
        mockRemoteConfigManager.fetchAndActivateResult = .failure(.maxRetriesExceeded)

        // Set environment fallback
        setenv("GEMINI_API_KEY", "env_fallback_gemini", 1)
        setenv("GOOGLE_BOOKS_API_KEY", "env_fallback_google", 1)
        setenv("GROK_API_KEY", "env_fallback_grok", 1)

        let expectation = self.expectation(description: "Async fallback test")
        expectation.expectedFulfillmentCount = 3

        secureConfig.getGeminiAPIKeyAsync { key in
            XCTAssertEqual(key, "env_fallback_gemini")
            expectation.fulfill()
        }

        secureConfig.getGoogleBooksAPIKeyAsync { key in
            XCTAssertEqual(key, "env_fallback_google")
            expectation.fulfill()
        }

        secureConfig.getGrokAPIKeyAsync { key in
            XCTAssertEqual(key, "env_fallback_grok")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)

        unsetenv("GEMINI_API_KEY")
        unsetenv("GOOGLE_BOOKS_API_KEY")
        unsetenv("GROK_API_KEY")
    }

    func testSecureConfigPartialRemoteConfigSuccess() {
        // Remote Config has some keys, fails for others
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "remote_gemini"
        // google_books_api_key not set in remote
        mockRemoteConfigManager.mockStrings["grok_api_key"] = "remote_grok"

        // Set UserDefaults for missing key
        UserDefaults.standard.set("userdefaults_google", forKey: "google_books_api_key")

        XCTAssertEqual(secureConfig.geminiAPIKey, "remote_gemini")
        XCTAssertEqual(secureConfig.googleBooksAPIKey, "userdefaults_google")
        XCTAssertEqual(secureConfig.grokAPIKey, "remote_grok")
    }

    func testSecureConfigNoRemoteConfigDataUsesDefaults() {
        // Remote Config returns empty strings
        mockRemoteConfigManager.mockStrings = [:] // Empty

        // Set UserDefaults
        UserDefaults.standard.set("defaults_gemini", forKey: "gemini_api_key")
        UserDefaults.standard.set("defaults_google", forKey: "google_books_api_key")
        UserDefaults.standard.set("defaults_grok", forKey: "grok_api_key")

        XCTAssertEqual(secureConfig.geminiAPIKey, "defaults_gemini")
        XCTAssertEqual(secureConfig.googleBooksAPIKey, "defaults_google")
        XCTAssertEqual(secureConfig.grokAPIKey, "defaults_grok")
    }

    func testSecureConfigRevenueCatOptionalFallback() {
        // Remote Config fails
        mockRemoteConfigManager.fetchAndActivateResult = .failure(.activationFailed(underlyingError: NSError()))

        // No UserDefaults or env set
        XCTAssertNil(secureConfig.revenueCatAPIKey)

        // Set env
        setenv("REVENUECAT_API_KEY", "env_revenuecat", 1)
        XCTAssertEqual(secureConfig.revenueCatAPIKey, "env_revenuecat")
        unsetenv("REVENUECAT_API_KEY")
    }

    // MARK: - Network Failure Simulation with RemoteConfigManager

    func testRemoteConfigManagerIntegrationWithSecureConfig() {
        // Create a real RemoteConfigManager with mock RemoteConfig
        let mockRemoteConfig = MockRemoteConfig()
        mockRemoteConfig.lastFetchStatus = .failure
        let remoteConfigManager = RemoteConfigManager(remoteConfig: mockRemoteConfig)

        let secureConfigWithRealManager = SecureConfig(remoteConfigManager: remoteConfigManager)

        // Set UserDefaults
        UserDefaults.standard.set("integration_test_key", forKey: "gemini_api_key")

        // Since RemoteConfig fetch fails, should fallback
        XCTAssertEqual(secureConfigWithRealManager.geminiAPIKey, "integration_test_key")
    }

    func testAsyncIntegrationWithNetworkFailure() {
        // Simulate network failure in RemoteConfigManager
        let mockRemoteConfig = MockRemoteConfig()
        mockRemoteConfig.lastFetchStatus = .failure
        let remoteConfigManager = RemoteConfigManager(remoteConfig: mockRemoteConfig)

        let secureConfigWithRealManager = SecureConfig(remoteConfigManager: remoteConfigManager)

        // Set env fallback
        setenv("GEMINI_API_KEY", "network_failure_fallback", 1)

        let expectation = self.expectation(description: "Network failure async test")

        secureConfigWithRealManager.getGeminiAPIKeyAsync { key in
            XCTAssertEqual(key, "network_failure_fallback")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)

        unsetenv("GEMINI_API_KEY")
    }

    // MARK: - Validation with Fallback Behavior

    func testValidationWithFallbackSources() {
        // Remote Config has invalid key
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "invalid"

        // UserDefaults has valid key
        UserDefaults.standard.set("AIzaSyD1234567890abcdefghijklmnopqrstuvw", forKey: "gemini_api_key")

        XCTAssertTrue(secureConfig.hasValidGeminiKey)
    }

    func testConfigurationCompleteWithMixedSources() {
        // Remote Config has valid gemini
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = "AIzaSyD1234567890abcdefghijklmnopqrstuvw"

        // UserDefaults has valid google
        UserDefaults.standard.set("AIzaSyD1234567890abcdefghijklmnopqrstuvw", forKey: "google_books_api_key")

        // Env has valid grok
        setenv("GROK_API_KEY", "xai-1234567890abcdefghijklmnopqrstuvw", 1)

        XCTAssertTrue(secureConfig.isConfigurationComplete)

        unsetenv("GROK_API_KEY")
    }

    func testConfigurationIncompleteWhenFallbackFails() {
        // No valid keys anywhere
        mockRemoteConfigManager.mockStrings["gemini_api_key"] = ""
        // UserDefaults empty
        // Env empty

        XCTAssertFalse(secureConfig.isConfigurationComplete)
    }
}