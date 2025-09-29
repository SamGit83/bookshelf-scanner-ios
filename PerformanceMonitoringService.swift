import Foundation
import FirebaseCore
import FirebasePerformance
import Combine
import UIKit

/**
 * PerformanceMonitoringService - Centralized Performance Monitoring
 *
 * Singleton service managing all performance monitoring, metrics collection,
 * and real-time analytics for the Bookshelf Scanner app.
 */
class PerformanceMonitoringService {
    static let shared = PerformanceMonitoringService()

    // MARK: - Private Properties
    private let queue = DispatchQueue(label: "com.bookshelfscanner.performance", qos: .utility)
    private var cancellables = Set<AnyCancellable>()
    private var activeTraces = [String: Trace]()
    private var metricBuffers = [String: [PerformanceMetric]]()
    private var alertThresholds = [AlertType: Double]()

    // MARK: - Public Properties
    @Published var currentMetrics = PerformanceMetrics()
    @Published var activeAlerts = [PerformanceAlert]()

    // MARK: - Initialization
    private init() {
        setupFirebasePerformance()
        setupDefaultThresholds()
        setupSystemMonitoring()
        setupPeriodicReporting()
    }

    // MARK: - Firebase Performance Setup
    private func setupFirebasePerformance() {
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Configure Firebase Performance Monitoring
        let performance = Performance.sharedInstance()
        performance.isDataCollectionEnabled = true
        performance.isInstrumentationEnabled = true

        // Set custom attributes for better tracking
        performance.setValue("bookshelf_scanner", forAttribute: "app_name")
        performance.setValue(UIDevice.current.systemVersion, forAttribute: "ios_version")
        performance.setValue(UIDevice.current.model, forAttribute: "device_model")
    }

    private func setupDefaultThresholds() {
        alertThresholds = [
            .apiResponseTime: 5.0, // 5 seconds
            .memoryUsage: 100.0, // 100 MB
            .batteryDrain: 10.0, // 10% per hour
            .crashRate: 5.0, // 5% crash rate
            .conversionRate: 10.0, // 10% conversion rate minimum
            .churnRate: 15.0 // 15% churn rate maximum
        ]
    }

    private func setupSystemMonitoring() {
        // Monitor memory usage
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }

        // Monitor battery
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryMetrics()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.trackMemoryWarning()
            }
            .store(in: &cancellables)
    }

    private func setupPeriodicReporting() {
        // Report metrics every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.flushMetrics()
        }
    }

    // MARK: - Trace Management
    func startTrace(name: String, attributes: [String: String] = [:]) -> String {
        let traceId = UUID().uuidString
        queue.async {
            let trace = Performance.startTrace(name: name)
            attributes.forEach { trace?.setValue($0.value, forAttribute: $0.key) }
            self.activeTraces[traceId] = trace
        }
        return traceId
    }

    func stopTrace(traceId: String) {
        queue.async {
            if let trace = self.activeTraces.removeValue(forKey: traceId) {
                trace.stop()
            }
        }
    }

    // MARK: - API Call Tracking
    func trackAPICall(service: String, endpoint: String, method: String = "GET") -> String {
        let traceId = startTrace(name: "api_call", attributes: [
            "service": service,
            "endpoint": endpoint,
            "method": method
        ])

        // Track in analytics
        AnalyticsManager.shared.trackAPICall(service: service, endpoint: endpoint, success: true, responseTime: nil, errorMessage: nil)

        return traceId
    }

    func completeAPICall(traceId: String, success: Bool, responseTime: TimeInterval, dataSize: Int64? = nil, error: Error? = nil) {
        stopTrace(traceId: traceId)

        // Update metrics
        queue.async {
            self.currentMetrics.apiCalls += 1
            self.currentMetrics.totalResponseTime += responseTime
            self.currentMetrics.averageResponseTime = self.currentMetrics.totalResponseTime / Double(self.currentMetrics.apiCalls)

            if let dataSize = dataSize {
                self.currentMetrics.totalDataTransferred += dataSize
            }

            if !success {
                self.currentMetrics.failedAPICalls += 1
            }
        }

        // Track in analytics with final data
        let service = "unknown" // Would need to be passed or stored
        let endpoint = "unknown"
        AnalyticsManager.shared.trackAPICall(
            service: service,
            endpoint: endpoint,
            success: success,
            responseTime: responseTime,
            errorMessage: error?.localizedDescription
        )
    }

    // MARK: - Custom Metrics
    func trackMetric(_ metric: PerformanceMetric) {
        queue.async {
            self.currentMetrics.update(with: metric)

            // Buffer for batch processing
            let key = metric.name
            if self.metricBuffers[key] == nil {
                self.metricBuffers[key] = []
            }
            self.metricBuffers[key]?.append(metric)

            // Check thresholds
            self.checkThresholds(for: metric)
        }
    }

    func trackScreenPerformance(screenName: String, loadTime: TimeInterval) {
        let metric = PerformanceMetric(
            name: "screen_load_time",
            value: loadTime,
            unit: "seconds",
            metadata: ["screen": screenName]
        )
        trackMetric(metric)

        // Firebase screen trace
        let trace = Performance.startTrace(name: "screen_load")
        trace?.setValue(screenName, forAttribute: "screen_name")
        trace?.setValue(String(loadTime), forAttribute: "load_time")
        trace?.stop()
    }

    func trackMemoryUsage(currentUsage: Double, peakUsage: Double) {
        let currentMetric = PerformanceMetric(
            name: "memory_usage_current",
            value: currentUsage,
            unit: "MB",
            metadata: [:]
        )
        let peakMetric = PerformanceMetric(
            name: "memory_usage_peak",
            value: peakUsage,
            unit: "MB",
            metadata: [:]
        )

        trackMetric(currentMetric)
        trackMetric(peakMetric)
    }

    func trackBatteryImpact(drainRate: Double, context: String) {
        let metric = PerformanceMetric(
            name: "battery_drain_rate",
            value: drainRate,
            unit: "percent_per_hour",
            metadata: ["context": context]
        )
        trackMetric(metric)
    }

    func trackUXMetric(name: String, value: Double, context: String? = nil) {
        var metadata = [String: String]()
        if let context = context {
            metadata["context"] = context
        }

        let metric = PerformanceMetric(
            name: "ux_\(name)",
            value: value,
            unit: "score",
            metadata: metadata
        )
        trackMetric(metric)
    }

    func trackAPICost(service: String, cost: Double, tokensUsed: Int? = nil) {
        var metadata = ["service": service]
        if let tokens = tokensUsed {
            metadata["tokens_used"] = String(tokens)
        }

        let metric = PerformanceMetric(
            name: "api_cost",
            value: cost,
            unit: "USD",
            metadata: metadata
        )
        trackMetric(metric)
    }

    func trackCachePerformance(hitRate: Double, cacheSize: Int) {
        let metric = PerformanceMetric(
            name: "cache_performance",
            value: hitRate,
            unit: "percentage",
            metadata: ["cache_size": String(cacheSize)]
        )
        trackMetric(metric)
    }

    func trackUserEngagement(sessionLength: TimeInterval, featuresUsed: Int, booksProcessed: Int) {
        let engagementScore = (sessionLength / 60.0) + Double(featuresUsed) + Double(booksProcessed) // Simple scoring

        let metric = PerformanceMetric(
            name: "user_engagement",
            value: engagementScore,
            unit: "score",
            metadata: [
                "session_length": String(sessionLength),
                "features_used": String(featuresUsed),
                "books_processed": String(booksProcessed)
            ]
        )
        trackMetric(metric)
    }

    func trackConversionFunnel(step: String, conversionRate: Double, dropOffRate: Double) {
        let metric = PerformanceMetric(
            name: "conversion_funnel",
            value: conversionRate,
            unit: "percentage",
            metadata: [
                "step": step,
                "drop_off_rate": String(dropOffRate)
            ]
        )
        trackMetric(metric)
    }

    // MARK: - System Monitoring
    private func updateSystemMetrics() {
        let memoryUsage = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0 // MB
        trackMemoryUsage(currentUsage: memoryUsage, peakUsage: memoryUsage)

        updateBatteryMetrics()
    }

    private func updateBatteryMetrics() {
        let batteryLevel = Double(UIDevice.current.batteryLevel) * 100.0
        let batteryState = UIDevice.current.batteryState

        let metric = PerformanceMetric(
            name: "battery_level",
            value: batteryLevel,
            unit: "percent",
            metadata: ["state": String(describing: batteryState)]
        )
        trackMetric(metric)
    }

    private func trackMemoryWarning() {
        let metric = PerformanceMetric(
            name: "memory_warning",
            value: 1.0,
            unit: "count",
            metadata: [:]
        )
        trackMetric(metric)

        // Trigger alert
        createAlert(type: .memoryUsage, value: currentMetrics.memoryUsage, threshold: alertThresholds[.memoryUsage] ?? 0)
    }

    // MARK: - Alert System
    private func checkThresholds(for metric: PerformanceMetric) {
        guard let threshold = alertThresholds[AlertType(rawValue: metric.name) ?? .custom] else { return }

        let shouldAlert: Bool
        switch metric.name {
        case "api_response_time":
            shouldAlert = metric.value > threshold
        case "memory_usage_current":
            shouldAlert = metric.value > threshold
        case "battery_drain_rate":
            shouldAlert = metric.value > threshold
        case "crash_rate":
            shouldAlert = metric.value > threshold
        case "conversion_rate":
            shouldAlert = metric.value < threshold
        case "churn_rate":
            shouldAlert = metric.value > threshold
        default:
            return // Don't alert on unknown metrics
        }

        if shouldAlert {
            createAlert(type: AlertType(rawValue: metric.name) ?? .custom, value: metric.value, threshold: threshold)
        }
    }

    private func createAlert(type: AlertType, value: Double, threshold: Double) {
        let alert = PerformanceAlert(
            id: UUID().uuidString,
            type: type,
            message: "\(type.displayName) exceeded threshold: \(String(format: "%.2f", value)) (threshold: \(String(format: "%.2f", threshold)))",
            value: value,
            threshold: threshold,
            timestamp: Date()
        )

        queue.async {
            self.activeAlerts.append(alert)
            // Keep only last 50 alerts
            if self.activeAlerts.count > 50 {
                self.activeAlerts.removeFirst()
            }
        }

        // Notify AlertManager
        AlertManager.shared.handleAlert(alert)
    }

    // MARK: - Cost Tracking Integration
    func trackAPICost(service: String, cost: Double, usage: Int = 1) {
        CostTracker.shared.recordCost(service: service, cost: cost, usage: usage)
    }

    // MARK: - Data Export
    func exportMetrics(startDate: Date, endDate: Date) async throws -> [String: Any] {
        // This would integrate with Firebase or custom storage
        // For now, return current metrics
        return [
            "period": [
                "start_date": startDate.ISO8601Format(),
                "end_date": endDate.ISO8601Format()
            ],
            "metrics": currentMetrics.toDictionary(),
            "alerts": activeAlerts.map { $0.toDictionary() }
        ]
    }

    // MARK: - Periodic Reporting
    private func flushMetrics() {
        queue.async {
            // Send buffered metrics to Firebase Analytics
            for (key, metrics) in self.metricBuffers {
                let averageValue = metrics.map { $0.value }.reduce(0, +) / Double(metrics.count)
                AnalyticsManager.shared.trackPerformanceMetric(
                    metricName: key,
                    value: averageValue,
                    unit: metrics.first?.unit
                )
            }

            // Clear buffers
            self.metricBuffers.removeAll()
        }
    }

    // MARK: - Cleanup
    func cleanup() {
        queue.async {
            self.activeTraces.values.forEach { $0.stop() }
            self.activeTraces.removeAll()
            self.metricBuffers.removeAll()
        }
    }
}

// MARK: - Supporting Types
struct PerformanceMetrics {
    var apiCalls: Int = 0
    var failedAPICalls: Int = 0
    var totalResponseTime: TimeInterval = 0.0
    var averageResponseTime: TimeInterval = 0.0
    var totalDataTransferred: Int64 = 0
    var memoryUsage: Double = 0.0
    var batteryLevel: Double = 0.0
    var crashCount: Int = 0
    var conversionRate: Double = 0.0
    var churnRate: Double = 0.0

    mutating func update(with metric: PerformanceMetric) {
        switch metric.name {
        case "memory_usage_current":
            memoryUsage = metric.value
        case "battery_level":
            batteryLevel = metric.value
        case "crash_rate":
            crashCount += Int(metric.value)
        case "conversion_rate":
            conversionRate = metric.value
        case "churn_rate":
            churnRate = metric.value
        default:
            break
        }
    }

    func toDictionary() -> [String: Any] {
        return [
            "api_calls": apiCalls,
            "failed_api_calls": failedAPICalls,
            "total_response_time": totalResponseTime,
            "average_response_time": averageResponseTime,
            "total_data_transferred": totalDataTransferred,
            "memory_usage": memoryUsage,
            "battery_level": batteryLevel,
            "crash_count": crashCount,
            "conversion_rate": conversionRate,
            "churn_rate": churnRate
        ]
    }
}

struct PerformanceMetric {
    let name: String
    let value: Double
    let unit: String
    let timestamp: Date
    let metadata: [String: String]

    init(name: String, value: Double, unit: String, metadata: [String: String] = [:]) {
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = Date()
        self.metadata = metadata
    }
}

struct PerformanceAlert {
    let id: String
    let type: AlertType
    let message: String
    let value: Double
    let threshold: Double
    let timestamp: Date

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "message": message,
            "value": value,
            "threshold": threshold,
            "timestamp": timestamp.ISO8601Format()
        ]
    }
}

enum AlertType: String {
    case apiResponseTime = "api_response_time"
    case memoryUsage = "memory_usage_current"
    case batteryDrain = "battery_drain_rate"
    case crashRate = "crash_rate"
    case conversionRate = "conversion_rate"
    case churnRate = "churn_rate"
    case custom

    var displayName: String {
        switch self {
        case .apiResponseTime: return "API Response Time"
        case .memoryUsage: return "Memory Usage"
        case .batteryDrain: return "Battery Drain"
        case .crashRate: return "Crash Rate"
        case .conversionRate: return "Conversion Rate"
        case .churnRate: return "Churn Rate"
        case .custom: return "Custom Alert"
        }
    }
}