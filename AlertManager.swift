import Foundation
import UserNotifications
import Combine
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

/**
 * AlertManager - Configurable Threshold-Based Alert System
 *
 * Manages alerts for performance metrics, business KPIs, and system health.
 * Supports configurable thresholds, notification channels, and escalation policies.
 */
class AlertManager {
    static let shared = AlertManager()

    // MARK: - Private Properties
    private let queue = DispatchQueue(label: "com.bookshelfscanner.alertmanager", qos: .utility)
    private var cancellables = Set<AnyCancellable>()
    private var alertConfigurations = [AlertType: AlertConfiguration]()
    private var activeAlerts = [String: PerformanceAlert]()
    private var alertHistory = [PerformanceAlert]()

    // MARK: - Public Properties
    @Published var recentAlerts = [PerformanceAlert]()
    @Published var alertStats = AlertStatistics()

    // MARK: - Initialization
    private init() {
        setupDefaultConfigurations()
        setupNotificationPermissions()
        setupAlertMonitoring()
        loadAlertHistory()
    }

    private func setupAlertMonitoring() {
        // Set up monitoring for various performance metrics
        // This would typically integrate with PerformanceMonitoringService
        // For now, set up basic monitoring
        setupPerformanceMetricMonitoring()
        setupBusinessKPIMonitoring()
    }

    private func setupPerformanceMetricMonitoring() {
        // Monitor API response times, memory usage, etc.
        // This would subscribe to PerformanceMonitoringService updates
        PerformanceMonitoringService.shared.$currentMetrics
            .sink { [weak self] metrics in
                // Check for alerts based on metrics
                self?.checkPerformanceMetrics(metrics)
            }
            .store(in: &cancellables)
    }

    private func setupBusinessKPIMonitoring() {
        // Monitor conversion rates, churn rates, etc.
        // This would integrate with analytics data
        // For now, this is a placeholder
    }

    private func checkPerformanceMetrics(_ metrics: PerformanceMetrics) {
        // Check API response time
        if metrics.averageResponseTime > 5.0 {
            let alert = PerformanceAlert(
                id: UUID().uuidString,
                type: .apiResponseTime,
                message: "API response time exceeded threshold: \(String(format: "%.2f", metrics.averageResponseTime))s",
                value: metrics.averageResponseTime,
                threshold: 5.0,
                timestamp: Date()
            )
            handleAlert(alert)
        }

        // Check memory usage
        if metrics.memoryUsage > 100.0 {
            let alert = PerformanceAlert(
                id: UUID().uuidString,
                type: .memoryUsage,
                message: "Memory usage exceeded threshold: \(String(format: "%.1f", metrics.memoryUsage))MB",
                value: metrics.memoryUsage,
                threshold: 100.0,
                timestamp: Date()
            )
            handleAlert(alert)
        }
    }

    // MARK: - Alert Configuration
    private func setupDefaultConfigurations() {
        alertConfigurations = [
            .apiResponseTime: AlertConfiguration(
                type: .apiResponseTime,
                threshold: 5.0,
                condition: .greaterThan,
                severity: .medium,
                enabled: true,
                notificationChannels: [.push, .analytics],
                cooldownMinutes: 15
            ),
            .memoryUsage: AlertConfiguration(
                type: .memoryUsage,
                threshold: 100.0,
                condition: .greaterThan,
                severity: .high,
                enabled: true,
                notificationChannels: [.push, .analytics],
                cooldownMinutes: 5
            ),
            .batteryDrain: AlertConfiguration(
                type: .batteryDrain,
                threshold: 10.0,
                condition: .greaterThan,
                severity: .medium,
                enabled: true,
                notificationChannels: [.analytics],
                cooldownMinutes: 60
            ),
            .crashRate: AlertConfiguration(
                type: .crashRate,
                threshold: 5.0,
                condition: .greaterThan,
                severity: .critical,
                enabled: true,
                notificationChannels: [.push, .analytics],
                cooldownMinutes: 30
            ),
            .conversionRate: AlertConfiguration(
                type: .conversionRate,
                threshold: 10.0,
                condition: .lessThan,
                severity: .high,
                enabled: true,
                notificationChannels: [.push, .analytics],
                cooldownMinutes: 1440 // 24 hours
            ),
            .churnRate: AlertConfiguration(
                type: .churnRate,
                threshold: 15.0,
                condition: .greaterThan,
                severity: .high,
                enabled: true,
                notificationChannels: [.push, .analytics],
                cooldownMinutes: 1440 // 24 hours
            )
        ]
    }

    func updateConfiguration(for type: AlertType, configuration: AlertConfiguration) {
        queue.async {
            self.alertConfigurations[type] = configuration
            self.saveConfigurations()
        }
    }

    func getConfiguration(for type: AlertType) -> AlertConfiguration? {
        return alertConfigurations[type]
    }

    // MARK: - Alert Handling
    func handleAlert(_ alert: PerformanceAlert) {
        queue.async {
            // Check if alert should be triggered based on configuration
            guard let config = self.alertConfigurations[alert.type], config.enabled else { return }

            // Check condition
            let shouldTrigger: Bool
            switch config.condition {
            case .greaterThan:
                shouldTrigger = alert.value > config.threshold
            case .lessThan:
                shouldTrigger = alert.value < config.threshold
            case .equal:
                shouldTrigger = alert.value == config.threshold
            }

            guard shouldTrigger else { return }

            // Check cooldown
            if self.isOnCooldown(alert.type, config.cooldownMinutes) { return }

            // Create enhanced alert with configuration
            let enhancedAlert = PerformanceAlert(
                id: alert.id,
                type: alert.type,
                message: alert.message,
                value: alert.value,
                threshold: alert.threshold,
                timestamp: alert.timestamp,
                severity: config.severity,
                configuration: config
            )

            // Store alert
            self.activeAlerts[alert.id] = enhancedAlert
            self.alertHistory.append(enhancedAlert)

            // Update stats
            self.updateAlertStats(with: enhancedAlert)

            // Keep recent alerts list manageable
            if self.recentAlerts.count >= 20 {
                self.recentAlerts.removeFirst()
            }
            self.recentAlerts.append(enhancedAlert)

            // Send notifications
            self.sendNotifications(for: enhancedAlert)

            // Auto-resolve if configured
            if config.autoResolve {
                self.scheduleAutoResolve(alert.id, after: config.autoResolveMinutes)
            }

            // Trigger escalation if needed
            self.checkEscalationPolicy(for: enhancedAlert)
        }
    }

    private func isOnCooldown(_ type: AlertType, _ cooldownMinutes: Int) -> Bool {
        let cutoffDate = Date().addingTimeInterval(-Double(cooldownMinutes) * 60)
        return alertHistory.contains { alert in
            alert.type == type && alert.timestamp > cutoffDate
        }
    }

    func resolveAlert(_ alertId: String, resolution: AlertResolution) {
        queue.async {
            guard let alert = self.activeAlerts.removeValue(forKey: alertId) else { return }

            let resolvedAlert = PerformanceAlert(
                id: alert.id,
                type: alert.type,
                message: alert.message,
                value: alert.value,
                threshold: alert.threshold,
                timestamp: alert.timestamp,
                severity: alert.severity,
                configuration: alert.configuration,
                resolution: resolution,
                resolvedAt: Date()
            )

            // Update in history
            if let index = self.alertHistory.firstIndex(where: { $0.id == alertId }) {
                self.alertHistory[index] = resolvedAlert
            }

            // Update stats
            self.alertStats.resolvedAlerts += 1

            // Log resolution
            AnalyticsManager.shared.trackAlertAction(
                alertType: alert.type.displayName,
                action: "resolved_\(resolution.rawValue)"
            )

            self.saveAlertHistory()
        }
    }

    private func scheduleAutoResolve(_ alertId: String, after minutes: Int) {
        let deadline = DispatchTime.now() + Double(minutes) * 60
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            self?.resolveAlert(alertId, resolution: .autoResolved)
        }
    }

    // MARK: - Notification System
    private func setupNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("AlertManager: Notification permissions granted")
            } else if let error = error {
                print("AlertManager: Notification permissions denied: \(error.localizedDescription)")
            }
        }
    }

    private func sendNotifications(for alert: PerformanceAlert) {
        guard let config = alert.configuration else { return }

        for channel in config.notificationChannels {
            switch channel {
            case .push:
                sendPushNotification(for: alert)
            case .analytics:
                logAlertToAnalytics(alert)
            case .email:
                sendEmailAlert(for: alert)
            case .slack:
                sendSlackAlert(for: alert)
            }
        }
    }

    private func sendPushNotification(for alert: PerformanceAlert) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 \(alert.severity.displayName) Alert"
        content.body = alert.message
        content.sound = .default
        content.badge = NSNumber(value: activeAlerts.count)

        // Add alert details
        content.userInfo = [
            "alert_id": alert.id,
            "alert_type": alert.type.rawValue,
            "severity": alert.severity.rawValue
        ]

        let request = UNNotificationRequest(
            identifier: "alert_\(alert.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("AlertManager: Failed to send push notification: \(error.localizedDescription)")
            }
        }
    }

    private func logAlertToAnalytics(_ alert: PerformanceAlert) {
        AnalyticsManager.shared.trackAlertShown(
            alertType: alert.type.displayName,
            context: "severity_\(alert.severity.rawValue)"
        )
    }

    private func sendEmailAlert(for alert: PerformanceAlert) {
        // Implementation would integrate with email service
        // For now, just log
        print("AlertManager: Email alert - \(alert.message)")
    }

    private func sendSlackAlert(for alert: PerformanceAlert) {
        // Implementation would integrate with Slack webhook
        // For now, just log
        print("AlertManager: Slack alert - \(alert.message)")
    }

    // MARK: - Escalation Policy
    private func checkEscalationPolicy(for alert: PerformanceAlert) {
        guard let config = alert.configuration else { return }

        // Count recent alerts of same type
        let recentCount = alertHistory.filter { recentAlert in
            recentAlert.type == alert.type &&
            recentAlert.timestamp > Date().addingTimeInterval(-3600) // Last hour
        }.count

        // Escalate if multiple alerts in short time
        if recentCount >= config.escalationThreshold {
            escalateAlert(alert, level: .high)
        }

        // Critical alerts always escalate
        if alert.severity == .critical {
            escalateAlert(alert, level: .critical)
        }
    }

    private func escalateAlert(_ alert: PerformanceAlert, level: EscalationLevel) {
        // Enhanced notification for escalated alerts
        let escalatedAlert = PerformanceAlert(
            id: alert.id,
            type: alert.type,
            message: "🚨 ESCALATED: \(alert.message)",
            value: alert.value,
            threshold: alert.threshold,
            timestamp: alert.timestamp,
            severity: alert.severity,
            configuration: alert.configuration,
            escalationLevel: level
        )

        // Send to additional channels
        sendEscalatedNotifications(for: escalatedAlert)
    }

    private func sendEscalatedNotifications(for alert: PerformanceAlert) {
        // Send to all available channels regardless of configuration
        sendPushNotification(for: alert)
        sendEmailAlert(for: alert)
        sendSlackAlert(for: alert)
        logAlertToAnalytics(alert)
    }

    // MARK: - Statistics and Reporting
    private func updateAlertStats(with alert: PerformanceAlert) {
        alertStats.totalAlerts += 1

        switch alert.severity {
        case .low:
            alertStats.lowSeverityAlerts += 1
        case .medium:
            alertStats.mediumSeverityAlerts += 1
        case .high:
            alertStats.highSeverityAlerts += 1
        case .critical:
            alertStats.criticalSeverityAlerts += 1
        }

        // Update type counts
        alertStats.alertsByType[alert.type.rawValue, default: 0] += 1
    }

    func getAlertReport(startDate: Date, endDate: Date) -> AlertReport {
        let alertsInPeriod = alertHistory.filter { alert in
            alert.timestamp >= startDate && alert.timestamp <= endDate
        }

        let resolvedCount = alertsInPeriod.filter { $0.resolution != nil }.count
        let avgResolutionTime = calculateAverageResolutionTime(for: alertsInPeriod)

        return AlertReport(
            period: DateInterval(start: startDate, end: endDate),
            totalAlerts: alertsInPeriod.count,
            resolvedAlerts: resolvedCount,
            averageResolutionTime: avgResolutionTime,
            alertsByType: Dictionary(grouping: alertsInPeriod) { $0.type.rawValue }.mapValues { $0.count },
            alertsBySeverity: Dictionary(grouping: alertsInPeriod) { $0.severity.rawValue }.mapValues { $0.count }
        )
    }

    private func calculateAverageResolutionTime(for alerts: [PerformanceAlert]) -> TimeInterval? {
        let resolvedAlerts = alerts.compactMap { alert -> TimeInterval? in
            guard let resolvedAt = alert.resolvedAt else { return nil }
            return resolvedAt.timeIntervalSince(alert.timestamp)
        }

        guard !resolvedAlerts.isEmpty else { return nil }
        return resolvedAlerts.reduce(0, +) / Double(resolvedAlerts.count)
    }

    // MARK: - Persistence
    private func saveConfigurations() {
        // Save alert configurations to UserDefaults or Firestore
        let configurationsData = try? JSONEncoder().encode(alertConfigurations)
        UserDefaults.standard.set(configurationsData, forKey: "alertConfigurations")
    }

    private func loadConfigurations() {
        // Load alert configurations
        if let data = UserDefaults.standard.data(forKey: "alertConfigurations"),
           let configurations = try? JSONDecoder().decode([AlertType: AlertConfiguration].self, from: data) {
            self.alertConfigurations = configurations
        }
    }

    private func saveAlertHistory() {
        // Save recent alert history (last 1000 alerts)
        let recentHistory = Array(alertHistory.suffix(1000))
        let historyData = try? JSONEncoder().encode(recentHistory)
        UserDefaults.standard.set(historyData, forKey: "alertHistory")
    }

    private func loadAlertHistory() {
        // Load alert history
        if let data = UserDefaults.standard.data(forKey: "alertHistory"),
           let history = try? JSONDecoder().decode([PerformanceAlert].self, from: data) {
            self.alertHistory = history
            self.recentAlerts = Array(history.suffix(20))
        }
    }

    // MARK: - Business KPI Alerts
    func checkBusinessKPIs(conversionRate: Double, churnRate: Double) {
        // Check conversion rate
        let conversionAlert = PerformanceAlert(
            id: UUID().uuidString,
            type: .conversionRate,
            message: "Conversion rate dropped below threshold",
            value: conversionRate,
            threshold: alertConfigurations[.conversionRate]?.threshold ?? 10.0,
            timestamp: Date()
        )
        handleAlert(conversionAlert)

        // Check churn rate
        let churnAlert = PerformanceAlert(
            id: UUID().uuidString,
            type: .churnRate,
            message: "Churn rate exceeded threshold",
            value: churnRate,
            threshold: alertConfigurations[.churnRate]?.threshold ?? 15.0,
            timestamp: Date()
        )
        handleAlert(churnAlert)
    }

    // MARK: - Cleanup
    func cleanup() {
        queue.async {
            // Remove old alerts (older than 30 days)
            let cutoffDate = Date().addingTimeInterval(-30 * 24 * 3600)
            self.alertHistory = self.alertHistory.filter { $0.timestamp > cutoffDate }
            self.saveAlertHistory()
        }
    }
}

// MARK: - Supporting Types
struct AlertConfiguration: Codable {
    var type: AlertType
    var threshold: Double
    var condition: AlertCondition
    var severity: AlertSeverity
    var enabled: Bool
    var notificationChannels: [NotificationChannel]
    var cooldownMinutes: Int
    var autoResolve: Bool = false
    var autoResolveMinutes: Int = 60
    var escalationThreshold: Int = 3 // Number of alerts before escalation
}

enum AlertCondition: String, Codable {
    case greaterThan
    case lessThan
    case equal
}

enum AlertSeverity: String, Codable {
    case low
    case medium
    case high
    case critical

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

enum NotificationChannel: String, Codable {
    case push
    case analytics
    case email
    case slack
}

enum AlertResolution: String, Codable {
    case resolved
    case autoResolved
    case acknowledged
    case escalated
}

enum EscalationLevel: String, Codable {
    case normal
    case high
    case critical
}

struct AlertStatistics {
    var totalAlerts: Int = 0
    var resolvedAlerts: Int = 0
    var lowSeverityAlerts: Int = 0
    var mediumSeverityAlerts: Int = 0
    var highSeverityAlerts: Int = 0
    var criticalSeverityAlerts: Int = 0
    var alertsByType: [String: Int] = [:]
}

struct AlertReport {
    let period: DateInterval
    let totalAlerts: Int
    let resolvedAlerts: Int
    let averageResolutionTime: TimeInterval?
    let alertsByType: [String: Int]
    let alertsBySeverity: [String: Int]
}