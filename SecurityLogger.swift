import Foundation
import FirebaseAnalytics

/// Security logging levels for controlling verbosity
enum SecurityLogLevel: Int, Comparable, Decodable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    static func < (lhs: SecurityLogLevel, rhs: SecurityLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Types of security events that can be logged
enum SecurityEventType: String, Codable {
    case rateLimitViolation = "rate_limit_violation"
    case timestampValidationFailure = "timestamp_validation_failure"
    case apiKeyInvalid = "api_key_invalid"
    case apiKeyMissing = "api_key_missing"
    case apiKeyExpired = "api_key_expired"
    case authenticationFailure = "authentication_failure"
    case authorizationFailure = "authorization_failure"
    case suspiciousActivity = "suspicious_activity"
    case dataTampering = "data_tampering"
    case encryptionFailure = "encryption_failure"
    case decryptionFailure = "decryption_failure"
    case networkSecurityViolation = "network_security_violation"
    case configurationError = "configuration_error"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SecurityEventType(rawValue: rawValue) ?? .suspiciousActivity
    }
}

/// Security event data structure
struct SecurityEvent: Codable {
    let id: String
    let type: SecurityEventType
    let level: SecurityLogLevel
    let timestamp: Date
    let userId: String?
    let deviceId: String?
    let service: String?
    let endpoint: String?
    let details: [String: AnyCodable]?
    let ipAddress: String?
    let userAgent: String?
    let errorMessage: String?
    let stackTrace: String?

    enum CodingKeys: String, CodingKey {
        case id, type, level, timestamp, userId, deviceId, service, endpoint, details, ipAddress, userAgent, errorMessage, stackTrace
    }

    init(type: SecurityEventType,
            level: SecurityLogLevel,
            userId: String? = nil,
            service: String? = nil,
            endpoint: String? = nil,
            details: [String: Any]? = nil,
            errorMessage: String? = nil,
            stackTrace: String? = nil) {

        self.id = UUID().uuidString
        self.type = type
        self.level = level
        self.timestamp = Date()
        self.userId = userId ?? AuthService.shared.currentUser?.id
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString
        self.service = service
        self.endpoint = endpoint
        self.details = details?.mapValues { AnyCodable($0) }
        self.ipAddress = nil // Would need network monitoring to populate
        self.userAgent = "BookshelfScanner/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
        self.errorMessage = errorMessage
        self.stackTrace = stackTrace
    }
}


/// Centralized security logging and monitoring system
class SecurityLogger {
    static let shared = SecurityLogger()

    private let userDefaults = UserDefaults.standard
    private let eventsKey = "security_events"
    private let maxStoredEvents = 1000

    /// Minimum log level for console output
    var consoleLogLevel: SecurityLogLevel = .info

    /// Minimum log level for Firebase Analytics
    var firebaseLogLevel: SecurityLogLevel = .warning

    /// Whether to store events locally
    var storeLocally: Bool = true

    private init() {
        // Load configuration from UserDefaults or use defaults
        loadConfiguration()
    }

    // MARK: - Configuration

    private func loadConfiguration() {
        consoleLogLevel = SecurityLogLevel(rawValue: userDefaults.integer(forKey: "security_console_log_level")) ?? .info
        firebaseLogLevel = SecurityLogLevel(rawValue: userDefaults.integer(forKey: "security_firebase_log_level")) ?? .warning
        storeLocally = userDefaults.bool(forKey: "security_store_locally")
    }

    func setConsoleLogLevel(_ level: SecurityLogLevel) {
        consoleLogLevel = level
        userDefaults.set(level.rawValue, forKey: "security_console_log_level")
    }

    func setFirebaseLogLevel(_ level: SecurityLogLevel) {
        firebaseLogLevel = level
        userDefaults.set(level.rawValue, forKey: "security_firebase_log_level")
    }

    func setStoreLocally(_ enabled: Bool) {
        storeLocally = enabled
        userDefaults.set(enabled, forKey: "security_store_locally")
    }

    // MARK: - Logging Methods

    /// Log a rate limit violation
    func logRateLimitViolation(service: String, endpoint: String, limit: Int, currentCount: Int, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "limit": limit,
            "current_count": currentCount,
            "time_window": "hourly"
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .rateLimitViolation,
            level: .warning,
            service: service,
            endpoint: endpoint,
            details: eventDetails
        )
    }

    /// Log a timestamp validation failure
    func logTimestampValidationFailure(service: String, endpoint: String, providedTimestamp: Date?, allowedWindow: TimeInterval, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "provided_timestamp": providedTimestamp?.timeIntervalSince1970 ?? 0,
            "allowed_window_seconds": allowedWindow,
            "current_time": Date().timeIntervalSince1970
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .timestampValidationFailure,
            level: .error,
            service: service,
            endpoint: endpoint,
            details: eventDetails
        )
    }

    /// Log API key issues
    func logAPIKeyIssue(type: SecurityEventType, service: String, keyType: String, details: [String: Any]? = nil) {
        precondition([.apiKeyInvalid, .apiKeyMissing, .apiKeyExpired].contains(type), "Invalid API key event type")

        let eventDetails: [String: Any] = [
            "key_type": keyType
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: type,
            level: .error,
            service: service,
            details: eventDetails
        )
    }

    /// Log authentication failures
    func logAuthenticationFailure(service: String, reason: String, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "failure_reason": reason
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .authenticationFailure,
            level: .warning,
            service: service,
            details: eventDetails
        )
    }

    /// Log authorization failures
    func logAuthorizationFailure(service: String, resource: String, action: String, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "resource": resource,
            "action": action
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .authorizationFailure,
            level: .error,
            service: service,
            details: eventDetails
        )
    }

    /// Log suspicious activity
    func logSuspiciousActivity(activity: String, severity: SecurityLogLevel = .warning, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "activity": activity
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .suspiciousActivity,
            level: severity,
            details: eventDetails
        )
    }

    /// Log data tampering attempts
    func logDataTampering(service: String, dataType: String, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "data_type": dataType
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .dataTampering,
            level: .critical,
            service: service,
            details: eventDetails
        )
    }

    /// Log encryption/decryption failures
    func logEncryptionFailure(operation: String, error: Error, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "operation": operation,
            "error_description": error.localizedDescription
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .encryptionFailure,
            level: .error,
            details: eventDetails,
            errorMessage: error.localizedDescription
        )
    }

    /// Log network security violations
    func logNetworkSecurityViolation(violation: String, url: String?, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "violation": violation,
            "url": url ?? "unknown"
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .networkSecurityViolation,
            level: .error,
            details: eventDetails
        )
    }

    /// Log configuration errors
    func logConfigurationError(setting: String, error: Error, details: [String: Any]? = nil) {
        let eventDetails: [String: Any] = [
            "setting": setting,
            "error_description": error.localizedDescription
        ].merging(details ?? [:]) { $1 }

        logSecurityEvent(
            type: .configurationError,
            level: .error,
            details: eventDetails,
            errorMessage: error.localizedDescription
        )
    }

    // MARK: - Core Logging

    /// Core method to log security events
    func logSecurityEvent(type: SecurityEventType,
                         level: SecurityLogLevel,
                         service: String? = nil,
                         endpoint: String? = nil,
                         details: [String: Any]? = nil,
                         errorMessage: String? = nil,
                         stackTrace: String? = nil) {

        let event = SecurityEvent(
            type: type,
            level: level,
            service: service,
            endpoint: endpoint,
            details: details,
            errorMessage: errorMessage,
            stackTrace: stackTrace
        )

        // Console logging
        if level >= consoleLogLevel {
            logToConsole(event)
        }

        // Firebase Analytics logging
        if level >= firebaseLogLevel {
            logToFirebase(event)
        }

        // Local storage
        if storeLocally {
            storeEventLocally(event)
        }
    }

    private func logToConsole(_ event: SecurityEvent) {
        let timestamp = ISO8601DateFormatter().string(from: event.timestamp)
        let levelString = String(describing: event.level).uppercased()
        let userInfo = event.userId != nil ? " user:\(event.userId!)" : ""
        let serviceInfo = event.service != nil ? " service:\(event.service!)" : ""

        print("🔒 SECURITY [\(timestamp)] [\(levelString)] \(event.type.rawValue)\(userInfo)\(serviceInfo)")

        if let errorMessage = event.errorMessage {
            print("   Error: \(errorMessage)")
        }

        if let details = event.details, !details.isEmpty {
            print("   Details: \(details)")
        }
    }

    private func logToFirebase(_ event: SecurityEvent) {
        #if canImport(FirebaseAnalytics)
        // Log to Firebase Analytics
        Analytics.logEvent("security_event", parameters: [
            "event_type": event.type.rawValue,
            "severity": event.level.rawValue,
            "user_id": event.userId ?? "anonymous",
            "device_id": event.deviceId ?? "unknown",
            "service": event.service ?? "unknown",
            "endpoint": event.endpoint ?? "unknown",
            "timestamp": event.timestamp.timeIntervalSince1970,
            "error_message": event.errorMessage ?? ""
        ])

        // For critical events, also log a separate critical event
        if event.level == .critical {
            Analytics.logEvent("security_critical_event", parameters: [
                "event_type": event.type.rawValue,
                "user_id": event.userId ?? "anonymous",
                "details": event.errorMessage ?? "No details"
            ])
        }
        #endif
    }

    private func storeEventLocally(_ event: SecurityEvent) {
        var events = getStoredEvents()
        events.append(event)

        // Keep only the most recent events
        if events.count > maxStoredEvents {
            events = Array(events.suffix(maxStoredEvents))
        }

        do {
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: eventsKey)
        } catch {
            print("Failed to store security event locally: \(error)")
        }
    }

    // MARK: - Event Retrieval

    func getStoredEvents() -> [SecurityEvent] {
        guard let data = userDefaults.data(forKey: eventsKey) else { return [] }

        do {
            return try JSONDecoder().decode([SecurityEvent].self, from: data)
        } catch {
            print("Failed to decode stored security events: \(error)")
            return []
        }
    }

    func getEvents(ofType type: SecurityEventType? = nil, level: SecurityLogLevel? = nil, limit: Int? = nil) -> [SecurityEvent] {
        var events = getStoredEvents()

        if let type = type {
            events = events.filter { $0.type == type }
        }

        if let level = level {
            events = events.filter { $0.level == level }
        }

        // Sort by timestamp (most recent first)
        events.sort { $0.timestamp > $1.timestamp }

        if let limit = limit {
            events = Array(events.prefix(limit))
        }

        return events
    }

    func clearStoredEvents() {
        userDefaults.removeObject(forKey: eventsKey)
    }

    // MARK: - Statistics

    func getSecurityStatistics() -> [String: Any] {
        let events = getStoredEvents()
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400)
        let oneWeekAgo = now.addingTimeInterval(-604800)

        let recentEvents = events.filter { $0.timestamp > oneDayAgo }
        let weeklyEvents = events.filter { $0.timestamp > oneWeekAgo }

        var stats: [String: Any] = [
            "total_events": events.count,
            "events_last_24h": recentEvents.count,
            "events_last_7d": weeklyEvents.count
        ]

        // Count by type
        let typeCounts = Dictionary(grouping: events) { $0.type }
            .mapValues { $0.count }
        stats["events_by_type"] = typeCounts

        // Count by level
        let levelCounts = Dictionary(grouping: events) { $0.level }
            .mapValues { $0.count }
        stats["events_by_level"] = levelCounts

        // Most recent critical events
        let criticalEvents = events.filter { $0.level == .critical }.prefix(5)
        stats["recent_critical_events"] = criticalEvents.map { [
            "type": $0.type.rawValue,
            "timestamp": $0.timestamp.timeIntervalSince1970,
            "service": $0.service ?? "unknown"
        ]}

        return stats
    }
}