import Foundation

/// Secure configuration manager for API keys and sensitive data
class SecureConfig {
    static let shared = SecureConfig()

    private let remoteConfigManager: RemoteConfigManagerProtocol

    private init() {
        self.remoteConfigManager = RemoteConfigManager.shared
    }

    // For testing
    init(remoteConfigManager: RemoteConfigManagerProtocol = RemoteConfigManager.shared) {
        self.remoteConfigManager = remoteConfigManager
    }

    // MARK: - API Keys

    var geminiAPIKey: String {
        // Try Remote Config first
        let remoteKey = remoteConfigManager.getString(forKey: "gemini_api_key")
        if !remoteKey.isEmpty {
            print("DEBUG SecureConfig: Using Gemini API key from Remote Config")
            return remoteKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using Gemini API key from UserDefaults")
            return storedKey
        }

        // Try environment variable
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using Gemini API key from environment variable")
            return envKey
        }

        // Fallback to placeholder (should never be used in production)
        print("DEBUG SecureConfig: Using placeholder Gemini API key - this will cause API failures")
        return "YOUR_GEMINI_API_KEY_HERE"
    }

    var googleBooksAPIKey: String {
        // Try Remote Config first
        let remoteKey = remoteConfigManager.getString(forKey: "google_books_api_key")
        if !remoteKey.isEmpty {
            print("DEBUG SecureConfig: Using Google Books API key from Remote Config")
            return remoteKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "google_books_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using Google Books API key from UserDefaults")
            return storedKey
        }

        // Try environment variable
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using Google Books API key from environment variable")
            return envKey
        }

        // Fallback to placeholder
        print("DEBUG SecureConfig: Using placeholder Google Books API key - this will cause API failures")
        return "YOUR_GOOGLE_BOOKS_API_KEY_HERE"
    }

    var grokAPIKey: String {
        // Try Remote Config first
        let remoteKey = remoteConfigManager.getString(forKey: "grok_api_key")
        if !remoteKey.isEmpty {
            print("DEBUG SecureConfig: Using Grok API key from Remote Config")
            return remoteKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "grok_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using Grok API key from UserDefaults")
            return storedKey
        }

        // Try environment variable
        if let envKey = ProcessInfo.processInfo.environment["GROK_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using Grok API key from environment variable")
            return envKey
        }

        // Fallback to placeholder
        print("DEBUG SecureConfig: Using placeholder Grok API key - this will cause API failures")
        return "YOUR_GROK_API_KEY_HERE"
    }

    var revenueCatAPIKey: String? {
        // Try Remote Config first
        let remoteKey = remoteConfigManager.getString(forKey: "revenuecat_api_key")
        if !remoteKey.isEmpty {
            print("DEBUG SecureConfig: Using RevenueCat API key from Remote Config")
            return remoteKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "revenuecat_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using RevenueCat API key from UserDefaults")
            return storedKey
        }

        // Try environment variable
        if let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using RevenueCat API key from environment variable")
            return envKey
        }

        // No fallback - return nil if not configured
        print("DEBUG SecureConfig: RevenueCat API key not configured")
        return nil
    }

    // MARK: - Async API Key Retrieval

    func getGeminiAPIKeyAsync(completion: @escaping (String) -> Void) {
        // Ensure Remote Config is fresh
        remoteConfigManager.fetchAndActivate { [weak self] result in
            guard let self = self else { return }
            completion(self.geminiAPIKey)
        }
    }

    func getGoogleBooksAPIKeyAsync(completion: @escaping (String) -> Void) {
        // Ensure Remote Config is fresh
        remoteConfigManager.fetchAndActivate { [weak self] result in
            guard let self = self else { return }
            completion(self.googleBooksAPIKey)
        }
    }

    func getGrokAPIKeyAsync(completion: @escaping (String) -> Void) {
        // Ensure Remote Config is fresh
        remoteConfigManager.fetchAndActivate { [weak self] result in
            guard let self = self else { return }
            completion(self.grokAPIKey)
        }
    }

    func getRevenueCatAPIKeyAsync(completion: @escaping (String?) -> Void) {
        // Ensure Remote Config is fresh
        remoteConfigManager.fetchAndActivate { [weak self] result in
            guard let self = self else { return }
            completion(self.revenueCatAPIKey)
        }
    }

    // MARK: - Configuration Management

    func setGeminiAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "gemini_api_key")
        UserDefaults.standard.synchronize()
    }

    func setGoogleBooksAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "google_books_api_key")
        UserDefaults.standard.synchronize()
    }

    func setGrokAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "grok_api_key")
        UserDefaults.standard.synchronize()
    }

    func clearAllKeys() {
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")
        UserDefaults.standard.removeObject(forKey: "google_books_api_key")
        UserDefaults.standard.removeObject(forKey: "grok_api_key")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Validation

    var hasValidGeminiKey: Bool {
        let key = geminiAPIKey
        return !key.isEmpty && !key.contains("YOUR_") && key.count > 20
    }

    var hasValidGoogleBooksKey: Bool {
        let key = googleBooksAPIKey
        return !key.isEmpty && !key.contains("YOUR_") && key.count > 20
    }

    var hasValidGrokKey: Bool {
        let key = grokAPIKey
        return !key.isEmpty && !key.contains("YOUR_") && key.count > 20
    }

    var isConfigurationComplete: Bool {
        return hasValidGeminiKey && hasValidGoogleBooksKey && hasValidGrokKey
    }

    // MARK: - Environment Detection

    var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var isTestFlight: Bool {
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    var isProduction: Bool {
        return !isDevelopment && !isTestFlight
    }
}