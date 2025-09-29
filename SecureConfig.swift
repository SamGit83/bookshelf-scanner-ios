import Foundation

/// Secure configuration manager for API keys and sensitive data
class SecureConfig {
    static let shared = SecureConfig()

    private init() {}

    // MARK: - API Keys

    var geminiAPIKey: String {
        // Try environment variable first (for development/testing)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using Gemini API key from environment variable")
            return envKey
        }

        // Try UserDefaults (for production, should be encrypted)
        if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using Gemini API key from UserDefaults")
            return storedKey
        }

        // Fallback to placeholder (should never be used in production)
        print("DEBUG SecureConfig: Using placeholder Gemini API key - this will cause API failures")
        return "YOUR_GEMINI_API_KEY_HERE"
    }

    var googleBooksAPIKey: String {
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using Google Books API key from environment variable")
            return envKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "google_books_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using Google Books API key from UserDefaults")
            return storedKey
        }

        // Fallback to placeholder
        print("DEBUG SecureConfig: Using placeholder Google Books API key - this will cause API failures")
        return "YOUR_GOOGLE_BOOKS_API_KEY_HERE"
    }

    var grokAPIKey: String {
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GROK_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using Grok API key from environment variable")
            return envKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "grok_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using Grok API key from UserDefaults")
            return storedKey
        }

        // Fallback to placeholder
        print("DEBUG SecureConfig: Using placeholder Grok API key - this will cause API failures")
        return "YOUR_GROK_API_KEY_HERE"
    }

    var revenueCatAPIKey: String? {
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"], !envKey.isEmpty {
            print("DEBUG SecureConfig: Using RevenueCat API key from environment variable")
            return envKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "revenuecat_api_key"), !storedKey.isEmpty {
            print("DEBUG SecureConfig: Using RevenueCat API key from UserDefaults")
            return storedKey
        }

        // No fallback - return nil if not configured
        print("DEBUG SecureConfig: RevenueCat API key not configured")
        return nil
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