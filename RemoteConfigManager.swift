import Foundation
import FirebaseRemoteConfig

protocol RemoteConfigProtocol {
    var lastFetchStatus: RemoteConfigFetchStatus { get }
    var lastFetchTime: Date? { get }
    var configSettings: RemoteConfigSettings { get set }

    func setDefaults(_ defaults: [String: NSObject])
    func fetch(completionHandler: @escaping (RemoteConfigFetchStatus, Error?) -> Void)
    func activate(completion: ((Bool, Error?) -> Void)?)
    func configValue(forKey key: String) -> RemoteConfigValue
}

extension RemoteConfig: RemoteConfigProtocol {}

protocol RemoteConfigManagerProtocol {
    func getString(forKey key: String) -> String
    func fetchAndActivate(completion: @escaping (Result<Void, RemoteConfigError>) -> Void)
}

extension RemoteConfigManager: RemoteConfigManagerProtocol {}

enum RemoteConfigError: Error {
    case fetchFailed(status: RemoteConfigFetchStatus, underlyingError: Error?)
    case activationFailed(underlyingError: Error)
    case maxRetriesExceeded
    case validationFailed(key: String, reason: String)
    case notInitialized
}

class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    private let remoteConfig: RemoteConfigProtocol
    private var isInitialized = false

    // For testing
    init(remoteConfig: RemoteConfigProtocol = RemoteConfig.remoteConfig()) {
        self.remoteConfig = remoteConfig
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development; set to 3600 for production
        remoteConfig.configSettings = settings

        // Set default values
        setDefaultValues()
    }

    private func setDefaultValues() {
        let defaults: [String: NSObject] = [
            "feature_enabled": false as NSObject,
            "max_books_limit": 100 as NSObject,
            "api_timeout": 30 as NSObject
        ]
        remoteConfig.setDefaults(defaults)
    }

    /// Fetches and activates Remote Config values with retry logic
    /// - Parameter completion: Completion handler with Result<Void, RemoteConfigError>
    func fetchAndActivate(completion: @escaping (Result<Void, RemoteConfigError>) -> Void) {
        fetchAndActivateWithRetry(attempt: 1, maxAttempts: 3, completion: completion)
    }

    private func fetchAndActivateWithRetry(attempt: Int, maxAttempts: Int, completion: @escaping (Result<Void, RemoteConfigError>) -> Void) {
        remoteConfig.fetch { [weak self] status, error in
            guard let self = self else { return }

            if let error = error {
                let configError = RemoteConfigError.fetchFailed(status: status, underlyingError: error)
                if attempt < maxAttempts {
                    let delay = pow(2.0, Double(attempt - 1)) // Exponential backoff: 1s, 2s, 4s
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.fetchAndActivateWithRetry(attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
                    }
                } else {
                    completion(.failure(.maxRetriesExceeded))
                }
                return
            }

            if status == .success {
                self.remoteConfig.activate { changed, error in
                    if let error = error {
                        let configError = RemoteConfigError.activationFailed(underlyingError: error)
                        if attempt < maxAttempts {
                            let delay = pow(2.0, Double(attempt - 1))
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                self.fetchAndActivateWithRetry(attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
                            }
                        } else {
                            completion(.failure(.maxRetriesExceeded))
                        }
                    } else {
                        self.isInitialized = true
                        completion(.success(()))
                    }
                }
            } else {
                let configError = RemoteConfigError.fetchFailed(status: status, underlyingError: nil)
                if attempt < maxAttempts {
                    let delay = pow(2.0, Double(attempt - 1))
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.fetchAndActivateWithRetry(attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
                    }
                } else {
                    completion(.failure(.maxRetriesExceeded))
                }
            }
        }
    }

    /// Gets a string value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: The string value, or default if not found
    func getString(forKey key: String) -> String {
        return remoteConfig.configValue(forKey: key).stringValue ?? ""
    }

    /// Gets a boolean value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: The boolean value, or default if not found
    func getBool(forKey key: String) -> Bool {
        return remoteConfig.configValue(forKey: key).boolValue
    }

    /// Gets an integer value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: The integer value, or default if not found
    func getInt(forKey key: String) -> Int64 {
        return remoteConfig.configValue(forKey: key).numberValue.int64Value
    }

    /// Gets a double value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: The double value, or default if not found
    func getDouble(forKey key: String) -> Double {
        return remoteConfig.configValue(forKey: key).numberValue.doubleValue
    }

    /// Gets the last fetch status
    var lastFetchStatus: RemoteConfigFetchStatus {
        return remoteConfig.lastFetchStatus
    }

    /// Gets the last fetch time
    var lastFetchTime: Date? {
        return remoteConfig.lastFetchTime
    }

    /// Checks if Remote Config is properly initialized
    var isRemoteConfigInitialized: Bool {
        return isInitialized
    }

    /// Validates if Remote Config has valid data for required keys
    func hasValidData() -> Bool {
        guard isInitialized else { return false }

        // Check required keys have valid values
        let requiredKeys = ["feature_enabled", "max_books_limit", "api_timeout"]
        for key in requiredKeys {
            if !isValidValue(forKey: key) {
                return false
            }
        }
        return true
    }

    /// Validates a specific config value
    private func isValidValue(forKey key: String) -> Bool {
        let configValue = remoteConfig.configValue(forKey: key)

        switch key {
        case "feature_enabled":
            // Bool is always valid
            return true
        case "max_books_limit":
            let value = configValue.numberValue.int64Value
            return value > 0 && value <= 1000 // Reasonable range
        case "api_timeout":
            let value = configValue.numberValue.int64Value
            return value > 0 && value <= 300 // 5 minutes max
        default:
            // For string values, check not empty
            return !configValue.stringValue.isEmpty
        }
    }

    /// Gets a validated string value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: Result with string value or validation error
    func getValidatedString(forKey key: String) -> Result<String, RemoteConfigError> {
        guard isInitialized else { return .failure(.notInitialized) }

        let value = getString(forKey: key)
        if value.isEmpty {
            return .failure(.validationFailed(key: key, reason: "Value is empty"))
        }
        return .success(value)
    }

    /// Gets a validated boolean value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: Result with bool value or validation error
    func getValidatedBool(forKey key: String) -> Result<Bool, RemoteConfigError> {
        guard isInitialized else { return .failure(.notInitialized) }

        // Bool values are always considered valid
        return .success(getBool(forKey: key))
    }

    /// Gets a validated integer value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: Result with int value or validation error
    func getValidatedInt(forKey key: String) -> Result<Int64, RemoteConfigError> {
        guard isInitialized else { return .failure(.notInitialized) }

        let value = getInt(forKey: key)
        if value <= 0 {
            return .failure(.validationFailed(key: key, reason: "Value must be positive"))
        }
        return .success(value)
    }

    /// Gets a validated double value for the given key
    /// - Parameter key: The key for the config value
    /// - Returns: Result with double value or validation error
    func getValidatedDouble(forKey key: String) -> Result<Double, RemoteConfigError> {
        guard isInitialized else { return .failure(.notInitialized) }

        let value = getDouble(forKey: key)
        if value < 0 {
            return .failure(.validationFailed(key: key, reason: "Value must be non-negative"))
        }
        return .success(value)
    }
}