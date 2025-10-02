import Foundation
import Combine
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

class ABTestingManager: ObservableObject {
    static let shared = ABTestingManager()

    @Published var currentPricingVariant: PricingVariant = .standard
    @Published var currentLimitsVariant: LimitsVariant = .standard

    #if canImport(FirebaseRemoteConfig)
    private let remoteConfig = RemoteConfig.remoteConfig()
    #else
    private let remoteConfig: Any? = nil
    #endif
    private let userDefaults = UserDefaults.standard

    // A/B Test Keys
    private let pricingTestKey = "pricing_test_variant"
    private let limitsTestKey = "limits_test_variant"
    private let userVariantKey = "user_test_variant"

    // Test Variants
    enum PricingVariant: String, CaseIterable {
        case standard = "standard"      // $2.99/month
        case premium = "premium"        // $3.99/month
        case discounted = "discounted"  // $1.99/month (limited time)

        var monthlyPrice: Double {
            switch self {
            case .standard: return 2.99
            case .premium: return 3.99
            case .discounted: return 1.99
            }
        }

        var annualPrice: Double {
            return monthlyPrice * 12 * 0.8 // 20% discount for annual
        }

        var displayPrice: String {
            return String(format: "$%.2f", monthlyPrice)
        }
    }

    enum LimitsVariant: String, CaseIterable {
        case conservative = "conservative"  // 15 scans, 20 books, 3 recs
        case standard = "standard"          // 20 scans, 25 books, 5 recs
        case generous = "generous"          // 30 scans, 35 books, 8 recs

        var scanLimit: Int {
            switch self {
            case .conservative: return 15
            case .standard: return 20
            case .generous: return 30
            }
        }

        var bookLimit: Int {
            switch self {
            case .conservative: return 20
            case .standard: return 25
            case .generous: return 35
            }
        }

        var recommendationLimit: Int {
            switch self {
            case .conservative: return 3
            case .standard: return 5
            case .generous: return 8
            }
        }
    }

    private init() {
        setupRemoteConfig()
        loadUserVariants()
    }

    private func setupRemoteConfig() {
        #if canImport(FirebaseRemoteConfig)
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings

        // Default values
        let defaults: [String: NSObject] = [
            pricingTestKey: "standard" as NSObject,
            limitsTestKey: "standard" as NSObject
        ]
        remoteConfig.setDefaults(defaults)
        #endif
    }

    func fetchRemoteConfig(completion: @escaping () -> Void) {
        #if canImport(FirebaseRemoteConfig)
        remoteConfig.fetchAndActivate { [weak self] status, error in
            if let error = error {
                print("Error fetching remote config: \(error.localizedDescription)")
            } else {
                print("Remote config fetched successfully")
                self?.updateVariantsFromRemoteConfig()
            }
            completion()
        }
        #else
        completion()
        #endif
    }

    private func updateVariantsFromRemoteConfig() {
        #if canImport(FirebaseRemoteConfig)
        let pricingVariant = remoteConfig[pricingTestKey].stringValue ?? "standard"
        let limitsVariant = remoteConfig[limitsTestKey].stringValue ?? "standard"

        currentPricingVariant = PricingVariant(rawValue: pricingVariant) ?? .standard
        currentLimitsVariant = LimitsVariant(rawValue: limitsVariant) ?? .standard

        // Save to user defaults for persistence
        userDefaults.set(pricingVariant, forKey: pricingTestKey)
        userDefaults.set(limitsVariant, forKey: limitsTestKey)

        // Update UsageTracker with new limits
        updateUsageTrackerLimits()

        // Log variant assignment
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("ab_test_variant_assigned", parameters: [
            "pricing_variant": pricingVariant,
            "limits_variant": limitsVariant
        ])
        #endif
        #endif
    }

    private func loadUserVariants() {
        let pricingVariant = userDefaults.string(forKey: pricingTestKey) ?? "standard"
        let limitsVariant = userDefaults.string(forKey: limitsTestKey) ?? "standard"

        currentPricingVariant = PricingVariant(rawValue: pricingVariant) ?? .standard
        currentLimitsVariant = LimitsVariant(rawValue: limitsVariant) ?? .standard

        updateUsageTrackerLimits()
    }

    private func updateUsageTrackerLimits() {
        // Update the variant limits in UsageTracker
        Task {
            await MainActor.run {
                UsageTracker.shared.variantScanLimit = currentLimitsVariant.scanLimit
                UsageTracker.shared.variantBookLimit = currentLimitsVariant.bookLimit
                UsageTracker.shared.variantRecommendationLimit = currentLimitsVariant.recommendationLimit
            }
        }
    }

    // MARK: - Analytics Tracking

    func trackConversion(fromVariant: String, toVariant: String? = nil) {
        #if canImport(FirebaseAnalytics)
        var parameters: [String: Any] = [
            "from_variant": fromVariant,
            "pricing_variant": currentPricingVariant.rawValue,
            "limits_variant": currentLimitsVariant.rawValue
        ]

        if let toVariant = toVariant {
            parameters["to_variant"] = toVariant
        }

        Analytics.logEvent("ab_test_conversion", parameters: parameters)
        #endif
    }

    func trackLimitHit(limitType: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("limit_hit", parameters: [
            "limit_type": limitType,
            "pricing_variant": currentPricingVariant.rawValue,
            "limits_variant": currentLimitsVariant.rawValue
        ])
        #endif
    }

    func trackUpgradePromptShown(source: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("upgrade_prompt_shown", parameters: [
            "source": source,
            "pricing_variant": currentPricingVariant.rawValue,
            "limits_variant": currentLimitsVariant.rawValue
        ])
        #endif
    }

    // MARK: - Test Management

    func forceVariant(pricing: PricingVariant, limits: LimitsVariant) {
        currentPricingVariant = pricing
        currentLimitsVariant = limits
        updateUsageTrackerLimits()

        // Save forced variants
        userDefaults.set(pricing.rawValue, forKey: pricingTestKey)
        userDefaults.set(limits.rawValue, forKey: limitsTestKey)
    }

    func resetToDefaults() {
        currentPricingVariant = .standard
        currentLimitsVariant = .standard
        updateUsageTrackerLimits()

        userDefaults.removeObject(forKey: pricingTestKey)
        userDefaults.removeObject(forKey: limitsTestKey)
    }
}