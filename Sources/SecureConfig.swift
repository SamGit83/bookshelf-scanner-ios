import Foundation

/// Secure configuration manager for API keys and sensitive data
class SecureConfig {
    static let shared = SecureConfig()

    private init() {}

    // MARK: - API Keys

    var geminiAPIKey: String {
        // Try environment variable first (for development/testing)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        // Try UserDefaults (for production, should be encrypted)
        if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !storedKey.isEmpty {
            return storedKey
        }

        // Fallback to placeholder (should never be used in production)
        return "YOUR_GEMINI_API_KEY_HERE"
    }

    var googleBooksAPIKey: String {
        // Try environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        // Try UserDefaults
        if let storedKey = UserDefaults.standard.string(forKey: "google_books_api_key"), !storedKey.isEmpty {
            return storedKey
        }

        // Fallback to placeholder
        return "YOUR_GOOGLE_BOOKS_API_KEY_HERE"
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

    func clearAllKeys() {
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")
        UserDefaults.standard.removeObject(forKey: "google_books_api_key")
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

    var isConfigurationComplete: Bool {
        return hasValidGeminiKey && hasValidGoogleBooksKey
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