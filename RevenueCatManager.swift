import Foundation
import Combine
import StoreKit
#if canImport(RevenueCat)
import RevenueCat
#else
// Stub types for when RevenueCat is not available
enum PeriodType {
    case intro, normal, trial
}

class EntitlementInfo {
    var isActive: Bool = false
    var productIdentifier: String = ""
    var expirationDate: Date?
    var periodType: PeriodType = .normal
}

class Entitlements {
    var active: [String: EntitlementInfo] = [:]
}

class Offering {}

class CustomerInfo {
    var originalAppUserId: String = ""
    var entitlements: Entitlements = Entitlements()
}

class StoreProduct {
    var price: Decimal = 0
    var currencyCode: String = ""
}

class Package {
    var storeProduct: StoreProduct?
    var identifier: String = ""
}
#endif

class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    @Published var offerings: [String: Offering] = [:]
    @Published var customerInfo: CustomerInfo?
    @Published var isSubscribed = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        #if canImport(RevenueCat)
        // Configure RevenueCat with API key
        if let apiKey = SecureConfig.shared.revenueCatAPIKey {
            Purchases.configure(withAPIKey: apiKey)
            Purchases.shared.delegate = self
        }

        // Load initial data
        loadOfferings()
        loadCustomerInfo()
        #endif
    }

    // MARK: - Configuration

    func configure(withAPIKey apiKey: String) {
        #if canImport(RevenueCat)
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        #endif
    }

    // MARK: - Offerings

    func loadOfferings() {
        #if canImport(RevenueCat)
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error = error {
                print("RevenueCat: Failed to load offerings: \(error.localizedDescription)")
                return
            }

            if let offerings = offerings {
                DispatchQueue.main.async {
                    self?.offerings = offerings.all
                }
            }
        }
        #endif
    }

    // MARK: - Customer Info

    func loadCustomerInfo() {
        #if canImport(RevenueCat)
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            if let error = error {
                print("RevenueCat: Failed to load customer info: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                self?.customerInfo = customerInfo
                self?.updateSubscriptionStatus(from: customerInfo)
            }
        }
        #endif
    }

    private func updateSubscriptionStatus(from customerInfo: CustomerInfo?) {
        #if canImport(RevenueCat)
        guard let customerInfo = customerInfo else {
            isSubscribed = false
            return
        }

        // Check if user has active subscription
        let hasActiveSubscription = customerInfo.entitlements.active.contains { entitlement in
            entitlement.value.isActive
        }

        isSubscribed = hasActiveSubscription

        // Update user tier based on subscription status
        if hasActiveSubscription {
            AuthService.shared.updateUserTier(.premium, subscriptionId: customerInfo.originalAppUserId)
        } else {
            AuthService.shared.updateUserTier(.free)
        }
        #endif
    }

    // MARK: - Purchases

    func purchase(package: Package, completion: @escaping (Result<CustomerInfo, Error>) -> Void) {
        #if canImport(RevenueCat)
        Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
            if let error = error {
                if userCancelled {
                    completion(.failure(NSError(domain: "RevenueCat", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled by user"])))
                } else {
                    completion(.failure(error))
                }
                return
            }

            if let customerInfo = customerInfo {
                DispatchQueue.main.async {
                    self.customerInfo = customerInfo
                    self.updateSubscriptionStatus(from: customerInfo)
                }
                completion(.success(customerInfo))
            }
        }
        #else
        // Fallback for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(NSError(domain: "RevenueCat", code: -1, userInfo: [NSLocalizedDescriptionKey: "RevenueCat not available"])))
        }
        #endif
    }

    // MARK: - Restore Purchases

    func restorePurchases(completion: @escaping (Result<CustomerInfo, Error>) -> Void) {
        #if canImport(RevenueCat)
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let customerInfo = customerInfo {
                DispatchQueue.main.async {
                    self.customerInfo = customerInfo
                    self.updateSubscriptionStatus(from: customerInfo)
                }
                completion(.success(customerInfo))
            }
        }
        #else
        // Fallback for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.failure(NSError(domain: "RevenueCat", code: -1, userInfo: [NSLocalizedDescriptionKey: "RevenueCat not available"])))
        }
        #endif
    }

    // MARK: - Subscription Management

    func getSubscriptionInfo() -> SubscriptionInfo? {
        #if canImport(RevenueCat)
        guard let customerInfo = customerInfo else { return nil }

        // Find active subscription
        guard let activeEntitlement = customerInfo.entitlements.active.first?.value else {
            return nil
        }

        return SubscriptionInfo(
            productName: activeEntitlement.productIdentifier,
            expirationDate: activeEntitlement.expirationDate ?? Date(),
            isTrial: activeEntitlement.periodType == .trial
        )
        #else
        return nil
        #endif
    }

    // MARK: - Analytics

    func trackPurchaseAttempt(package: Package) {
        AnalyticsManager.shared.trackSubscriptionCompleted(
            tier: .premium,
            subscriptionId: nil,
            price: package.storeProduct.flatMap { Double(truncating: NSDecimalNumber(decimal: $0.price)) },
            currency: package.storeProduct?.currencyCode ?? ""
        )
    }

    func trackPurchaseSuccess(package: Package, customerInfo: CustomerInfo) {
        AnalyticsManager.shared.trackSubscriptionCompleted(
            tier: .premium,
            subscriptionId: customerInfo.originalAppUserId,
            price: package.storeProduct.flatMap { Double(truncating: NSDecimalNumber(decimal: $0.price)) },
            currency: package.storeProduct?.currencyCode ?? ""
        )
    }

    func trackPurchaseFailure(package: Package, error: Error) {
        // Track failed purchase
        print("Purchase failed for package \(package.identifier): \(error.localizedDescription)")
    }
}

#if canImport(RevenueCat)
extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            self.customerInfo = customerInfo
            self.updateSubscriptionStatus(from: customerInfo)
        }
    }
}
#endif

// MARK: - Supporting Types

struct SubscriptionInfo {
    let productName: String
    let expirationDate: Date
    let isTrial: Bool
}