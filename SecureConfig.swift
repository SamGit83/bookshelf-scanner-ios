import Foundation

/// Secure configuration manager for API keys and sensitive data
class SecureConfig {
    static let shared = SecureConfig()

    private let remoteConfigManager = RemoteConfigManager.shared
    private let encryptionManager = EncryptionManager.shared

    private init() {}

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
            do {
                let decryptedKey = try encryptionManager.decrypt(storedKey)
                print("DEBUG SecureConfig: Using decrypted Gemini API key from UserDefaults")
                return decryptedKey
            } catch {
                print("DEBUG SecureConfig: Failed to decrypt Gemini API key, using as plain text")
                return storedKey
            }
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
            do {
                let decryptedKey = try encryptionManager.decrypt(storedKey)
                print("DEBUG SecureConfig: Using decrypted Google Books API key from UserDefaults")
                return decryptedKey
            } catch {
                print("DEBUG SecureConfig: Failed to decrypt Google Books API key, using as plain text")
                return storedKey
            }
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
            do {
                let decryptedKey = try encryptionManager.decrypt(storedKey)
                print("DEBUG SecureConfig: Using decrypted Grok API key from UserDefaults")
                return decryptedKey
            } catch {
                print("DEBUG SecureConfig: Failed to decrypt Grok API key, using as plain text")
                return storedKey
            }
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
            do {
                let decryptedKey = try encryptionManager.decrypt(storedKey)
                print("DEBUG SecureConfig: Using decrypted RevenueCat API key from UserDefaults")
                return decryptedKey
            } catch {
                print("DEBUG SecureConfig: Failed to decrypt RevenueCat API key, using as plain text")
                return storedKey
            }
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
        do {
            let encryptedKey = try encryptionManager.encrypt(key)
            UserDefaults.standard.set(encryptedKey, forKey: "gemini_api_key")
        } catch {
            print("ERROR SecureConfig: Failed to encrypt Gemini API key")
            // Do not store unencrypted key for security
            return
        }
        UserDefaults.standard.synchronize()
    }

    func setGoogleBooksAPIKey(_ key: String) {
        do {
            let encryptedKey = try encryptionManager.encrypt(key)
            UserDefaults.standard.set(encryptedKey, forKey: "google_books_api_key")
        } catch {
            print("ERROR SecureConfig: Failed to encrypt Google Books API key")
            // Do not store unencrypted key for security
            return
        }
        UserDefaults.standard.synchronize()
    }

    func setGrokAPIKey(_ key: String) {
        do {
            let encryptedKey = try encryptionManager.encrypt(key)
            UserDefaults.standard.set(encryptedKey, forKey: "grok_api_key")
        } catch {
            print("ERROR SecureConfig: Failed to encrypt Grok API key")
            // Do not store unencrypted key for security
            return
        }
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

    // MARK: - Timestamp Validation Configuration

    /// Time window in seconds for request validity to prevent replay attacks
    var requestTimeWindowSeconds: TimeInterval {
        // Try Remote Config first
        let remoteValue = remoteConfigManager.getInt(forKey: "request_time_window_seconds")
        if remoteValue > 0 {
            return TimeInterval(remoteValue)
        }

        // Try UserDefaults
        if let storedValue = UserDefaults.standard.object(forKey: "request_time_window_seconds") as? TimeInterval, storedValue > 0 {
            return storedValue
        }

        // Default to 5 minutes
        return 300.0
    }

    /// Set the request time window in seconds
    func setRequestTimeWindowSeconds(_ seconds: TimeInterval) {
        UserDefaults.standard.set(seconds, forKey: "request_time_window_seconds")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Timestamp Validation

    /// Validates if a timestamp is within the allowed time window
    func validateTimestamp(_ timestamp: Date?, service: String, endpoint: String) -> Bool {
        guard let timestamp = timestamp else {
            SecurityLogger.shared.logTimestampValidationFailure(
                service: service,
                endpoint: endpoint,
                providedTimestamp: nil,
                allowedWindow: requestTimeWindowSeconds,
                details: ["reason": "timestamp_missing"]
            )
            return false
        }

        let now = Date()
        let timeDifference = abs(now.timeIntervalSince(timestamp))

        if timeDifference > requestTimeWindowSeconds {
            SecurityLogger.shared.logTimestampValidationFailure(
                service: service,
                endpoint: endpoint,
                providedTimestamp: timestamp,
                allowedWindow: requestTimeWindowSeconds,
                details: ["time_difference_seconds": timeDifference]
            )
            return false
        }

        return true
    }

    /// Validates if a timestamp string is within the allowed time window
    func validateTimestampString(_ timestampString: String?, service: String, endpoint: String) -> Bool {
        guard let timestampString = timestampString else {
            SecurityLogger.shared.logTimestampValidationFailure(
                service: service,
                endpoint: endpoint,
                providedTimestamp: nil,
                allowedWindow: requestTimeWindowSeconds,
                details: ["reason": "timestamp_string_missing"]
            )
            return false
        }

        let dateFormatter = ISO8601DateFormatter()
        guard let timestamp = dateFormatter.date(from: timestampString) else {
            SecurityLogger.shared.logTimestampValidationFailure(
                service: service,
                endpoint: endpoint,
                providedTimestamp: nil,
                allowedWindow: requestTimeWindowSeconds,
                details: ["reason": "timestamp_format_invalid", "provided_string": timestampString]
            )
            return false
        }

        return validateTimestamp(timestamp, service: service, endpoint: endpoint)
    }

    // MARK: - API Key Validation with Logging

    /// Validates an API key and logs issues
    func validateAPIKey(_ key: String?, keyType: String, service: String) -> Bool {
        guard let key = key, !key.isEmpty else {
            SecurityLogger.shared.logAPIKeyIssue(
                type: .apiKeyMissing,
                service: service,
                keyType: keyType,
                details: ["expected_key_type": keyType]
            )
            return false
        }

        // Check if it's a placeholder key
        if key.contains("YOUR_") || key.count < 20 {
            SecurityLogger.shared.logAPIKeyIssue(
                type: .apiKeyInvalid,
                service: service,
                keyType: keyType,
                details: ["key_length": key.count, "appears_placeholder": key.contains("YOUR_")]
            )
            return false
        }

        // Additional validation based on key type
        switch keyType.lowercased() {
        case "gemini":
            if !key.hasPrefix("AIza") {
                SecurityLogger.shared.logAPIKeyIssue(
                    type: .apiKeyInvalid,
                    service: service,
                    keyType: keyType,
                    details: ["reason": "invalid_gemini_key_format"]
                )
                return false
            }
        case "grok":
            if !key.hasPrefix("xoxp-") && !key.hasPrefix("xoxb-") {
                SecurityLogger.shared.logAPIKeyIssue(
                    type: .apiKeyInvalid,
                    service: service,
                    keyType: keyType,
                    details: ["reason": "invalid_grok_key_format"]
                )
                return false
            }
        default:
            break
        }

        return true
    }

    /// Validates all configured API keys and logs issues
    func validateAllAPIKeys() -> Bool {
        var allValid = true

        if !validateAPIKey(geminiAPIKey, keyType: "gemini", service: "SecureConfig") {
            allValid = false
        }

        if !validateAPIKey(googleBooksAPIKey, keyType: "google_books", service: "SecureConfig") {
            allValid = false
        }

        if !validateAPIKey(grokAPIKey, keyType: "grok", service: "SecureConfig") {
            allValid = false
        }

        if let revenueCatKey = revenueCatAPIKey {
            if !validateAPIKey(revenueCatKey, keyType: "revenuecat", service: "SecureConfig") {
                allValid = false
            }
        }

        return allValid
    }
}