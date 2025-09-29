import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
import Combine

class AnalyticsManager {
    static let shared = AnalyticsManager()

    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #else
    private let db: Any? = nil
    #endif
    private var cancellables = Set<AnyCancellable>()

    // User properties
    private enum UserProperty: String {
        case userTier = "user_tier"
        case subscriptionId = "subscription_id"
        case onboardingCompleted = "onboarding_completed"
        case totalBooks = "total_books"
        case monthlyScans = "monthly_scans"
        case monthlyRecommendations = "monthly_recommendations"
        case experimentVariant = "experiment_variant"
        case appVersion = "app_version"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case country = "country"
        case favoriteGenre = "favorite_genre"
    }

    private init() {
        setupUserProperties()
        setupAuthStateListener()
    }

    // MARK: - User Properties Setup

    private func setupUserProperties() {
        // Set static properties
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            setUserProperty(UserProperty.appVersion.rawValue, value: version)
        }

        #if os(iOS)
        setUserProperty(UserProperty.deviceModel.rawValue, value: UIDevice.current.model)
        setUserProperty(UserProperty.osVersion.rawValue, value: UIDevice.current.systemVersion)
        #endif

        // Set country from user profile or device locale
        let country = Locale.current.region?.identifier ?? "Unknown"
        setUserProperty(UserProperty.country.rawValue, value: country)
    }

    private func setupAuthStateListener() {
        AuthService.shared.$currentUser
            .sink { [weak self] userProfile in
                self?.updateUserProperties(from: userProfile)
            }
            .store(in: &cancellables)

        AuthService.shared.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if !isAuthenticated {
                    self?.clearUserProperties()
                }
            }
            .store(in: &cancellables)
    }

    private func updateUserProperties(from userProfile: UserProfile?) {
        guard let user = userProfile else { return }

        setUserProperty(UserProperty.userTier.rawValue, value: user.tier.rawValue)
        setUserProperty(UserProperty.onboardingCompleted.rawValue, value: user.hasCompletedOnboarding ? "true" : "false")

        if let subscriptionId = user.subscriptionId {
            setUserProperty(UserProperty.subscriptionId.rawValue, value: subscriptionId)
        }

        if let favoriteGenre = user.favoriteBookGenre {
            setUserProperty(UserProperty.favoriteGenre.rawValue, value: favoriteGenre)
        }
    }

    private func clearUserProperties() {
        // Clear user-specific properties on logout
        #if canImport(FirebaseAnalytics)
        let propertiesToClear: [UserProperty] = [.userTier, .subscriptionId, .onboardingCompleted, .totalBooks, .monthlyScans, .monthlyRecommendations, .experimentVariant, .favoriteGenre]
        for property in propertiesToClear {
            Analytics.setUserProperty(nil, forName: property.rawValue)
        }
        #endif
    }

    func updateDynamicUserProperties(totalBooks: Int, monthlyScans: Int, monthlyRecommendations: Int) {
        setUserProperty(UserProperty.totalBooks.rawValue, value: String(totalBooks))
        setUserProperty(UserProperty.monthlyScans.rawValue, value: String(monthlyScans))
        setUserProperty(UserProperty.monthlyRecommendations.rawValue, value: String(monthlyRecommendations))
    }

    func setExperimentVariant(experimentId: String, variantId: String) {
        setUserProperty(UserProperty.experimentVariant.rawValue, value: "\(experimentId):\(variantId)")
    }

    private func setUserProperty(_ name: String, value: String?) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
    }

    // MARK: - Freemium Metrics Events

    func trackLimitHit(limitType: String, currentValue: Int, limitValue: Int) {
        logEvent("limit_hit", parameters: [
            "limit_type": limitType,
            "current_value": currentValue,
            "limit_value": limitValue
        ])
    }

    func trackUpgradePromptShown(source: String, limitType: String? = nil) {
        var params: [String: Any] = ["source": source]
        if let limitType = limitType {
            params["limit_type"] = limitType
        }
        logEvent("upgrade_prompt_shown", parameters: params)
    }

    func trackSubscriptionCompleted(tier: UserTier, subscriptionId: String?, price: Double? = nil, currency: String? = nil) {
        var params: [String: Any] = ["tier": tier.rawValue]
        if let subscriptionId = subscriptionId {
            params["subscription_id"] = subscriptionId
        }
        if let price = price {
            params["value"] = price
        }
        if let currency = currency {
            params["currency"] = currency
        }
        logEvent("subscription_completed", parameters: params)

        // Also track as revenue event
        if let price = price, let currency = currency {
            logEvent(AnalyticsEventPurchase, parameters: [
                AnalyticsParameterValue: price,
                AnalyticsParameterCurrency: currency,
                "tier": tier.rawValue
            ])
        }
    }

    // MARK: - User Engagement Events

    func trackBookshelfScanCompleted(bookCount: Int, scanDuration: TimeInterval? = nil) {
        var params: [String: Any] = ["book_count": bookCount]
        if let duration = scanDuration {
            params["scan_duration"] = duration
        }
        logEvent("bookshelf_scan_completed", parameters: params)
    }

    func trackRecommendationInteraction(recommendationId: String, action: String, position: Int? = nil) {
        var params: [String: Any] = [
            "recommendation_id": recommendationId,
            "action": action
        ]
        if let position = position {
            params["position"] = position
        }
        logEvent("recommendation_interaction", parameters: params)
    }

    func trackReadingSessionCompleted(bookId: String, sessionDuration: TimeInterval, pagesRead: Int) {
        logEvent("reading_session_completed", parameters: [
            "book_id": bookId,
            "session_duration": sessionDuration,
            "pages_read": pagesRead
        ])
    }

    func trackBookStatusChanged(bookId: String, fromStatus: BookStatus, toStatus: BookStatus) {
        logEvent("book_status_changed", parameters: [
            "book_id": bookId,
            "from_status": fromStatus.rawValue,
            "to_status": toStatus.rawValue
        ])
    }

    // MARK: - Performance Monitoring Events

    func trackAPICall(service: String, endpoint: String, success: Bool, responseTime: TimeInterval? = nil, errorMessage: String? = nil) {
        var params: [String: Any] = [
            "service": service,
            "endpoint": endpoint,
            "success": success
        ]
        if let responseTime = responseTime {
            params["response_time"] = responseTime
        }
        if let errorMessage = errorMessage {
            params["error_message"] = errorMessage
        }
        logEvent("api_call_made", parameters: params)
    }

    func trackAppCrash(error: Error, context: String) {
        logEvent("app_crash", parameters: [
            "error_message": error.localizedDescription,
            "context": context,
            "error_type": String(describing: type(of: error))
        ])
    }

    func trackPerformanceMetric(metricName: String, value: Double, unit: String? = nil) {
        var params: [String: Any] = [
            "metric_name": metricName,
            "value": value
        ]
        if let unit = unit {
            params["unit"] = unit
        }
        logEvent("app_performance_metric", parameters: params)

        // Also track in PerformanceMonitoringService
        PerformanceMonitoringService.shared.trackMetric(PerformanceMetric(
            name: metricName,
            value: value,
            unit: unit ?? "unit",
            metadata: [:]
        ))
    }

    // MARK: - Cost Tracking Integration
    func trackAPICost(service: String, cost: Double, usage: Int = 1) {
        logEvent("api_cost_incurred", parameters: [
            "service": service,
            "cost": cost,
            "usage": usage
        ])

        // Track in CostTracker
        CostTracker.shared.recordCost(service: service, cost: cost / Double(usage), usage: usage)
    }

    // MARK: - Alert System Integration
    func trackAlertTriggered(alertType: String, severity: String, value: Double, threshold: Double) {
        logEvent("alert_triggered", parameters: [
            "alert_type": alertType,
            "severity": severity,
            "value": value,
            "threshold": threshold
        ])
    }

    // MARK: - Optimization Tracking
    func trackOptimizationImplemented(optimizationId: String, type: String, expectedSavings: Double) {
        logEvent("optimization_implemented", parameters: [
            "optimization_id": optimizationId,
            "type": type,
            "expected_savings": expectedSavings
        ])
    }

    func trackRecommendationViewed(recommendationId: String, type: String) {
        logEvent("recommendation_viewed", parameters: [
            "recommendation_id": recommendationId,
            "type": type
        ])
    }

    // MARK: - Business KPI Events

    func trackUserAcquisition(source: String, campaign: String? = nil) {
        var params: [String: Any] = ["source": source]
        if let campaign = campaign {
            params["campaign"] = campaign
        }
        logEvent("user_acquisition", parameters: params)
    }

    func trackFeatureUsage(feature: String, context: String? = nil) {
        var params: [String: Any] = ["feature": feature]
        if let context = context {
            params["context"] = context
        }
        logEvent("feature_usage", parameters: params)
    }

    func trackConversionFunnelStep(step: String, stepNumber: Int, totalSteps: Int) {
        logEvent("conversion_funnel_step", parameters: [
            "step": step,
            "step_number": stepNumber,
            "total_steps": totalSteps
        ])
    }

    // MARK: - Conversion Funnel Tracking

    func trackOnboardingStep(step: String, completed: Bool) {
        logEvent("onboarding_step", parameters: [
            "step": step,
            "completed": completed
        ])
    }

    func trackUpgradeFlowStarted(source: String) {
        logEvent("upgrade_flow_started", parameters: ["source": source])
    }

    func trackUpgradeFlowCompleted(success: Bool, tier: UserTier? = nil) {
        var params: [String: Any] = ["success": success]
        if let tier = tier {
            params["tier"] = tier.rawValue
        }
        logEvent("upgrade_flow_completed", parameters: params)
    }

    // MARK: - Real-time Dashboard Data Collection

    func trackSessionStart() {
        logEvent(AnalyticsEventAppOpen, parameters: nil)
    }

    func trackSessionEnd(duration: TimeInterval) {
        logEvent("session_end", parameters: ["duration": duration])
    }

    func trackScreenView(screenName: String, screenClass: String? = nil) {
        var params: [String: Any] = [
            AnalyticsParameterScreenName: screenName
        ]
        if let screenClass = screenClass {
            params[AnalyticsParameterScreenClass] = screenClass
        }
        logEvent(AnalyticsEventScreenView, parameters: params)
    }

    // MARK: - Alert System Integration

    func trackAlertShown(alertType: String, context: String? = nil) {
        var params: [String: Any] = ["alert_type": alertType]
        if let context = context {
            params["context"] = context
        }
        logEvent("alert_shown", parameters: params)
    }

    func trackAlertAction(alertType: String, action: String) {
        logEvent("alert_action", parameters: [
            "alert_type": alertType,
            "action": action
        ])
    }

    // MARK: - Data Export Capabilities

    func exportAnalyticsData(userId: String, startDate: Date, endDate: Date) async throws -> [String: Any] {
        // This would integrate with Firebase Analytics data export or custom collection
        // For now, return a placeholder structure
        let data: [String: Any] = [
            "user_id": userId,
            "export_period": [
                "start_date": startDate.ISO8601Format(),
                "end_date": endDate.ISO8601Format()
            ],
            "events": [], // Would contain actual event data
            "note": "Data export functionality requires Firebase Analytics data export setup"
        ]
        return data
    }

    // MARK: - Helper Methods

    private func logEvent(_ name: String, parameters: [String: Any]?) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #endif
    }

    // MARK: - Privacy Compliance

    func disableAnalyticsForUser() {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty("opted_out", forName: "analytics_consent")
        #endif
        // Additional privacy compliance measures would be implemented here
    }

    func enableAnalyticsForUser() {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty("opted_in", forName: "analytics_consent")
        #endif
    }
}