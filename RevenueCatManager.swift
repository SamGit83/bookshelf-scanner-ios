import Foundation
import Combine
import StoreKit
import Purchases

class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    @Published var offerings: [String: Purchases.Offering] = [:]
    @Published var customerInfo: Purchases.CustomerInfo?
    @Published var isSubscribed = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Configure RevenueCat with API key
        if let apiKey = SecureConfig.shared.revenueCatAPIKey {
            Purchases.configure(withAPIKey: apiKey)
            Purchases.shared.delegate = self
        }

        // Load initial data
        loadOfferings()
        loadCustomerInfo()
    }

    // MARK: - Configuration

    func configure(withAPIKey apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
    }

    // MARK: - Offerings

    func loadOfferings() {
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
    }

    // MARK: - Customer Info

    func loadCustomerInfo() {
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
    }

    private func updateSubscriptionStatus(from customerInfo: Purchases.CustomerInfo?) {
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
    }

    // MARK: - Purchases

    func purchase(package: Purchases.Package, completion: @escaping (Result<Purchases.CustomerInfo, Error>) -> Void) {
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
    }

    // MARK: - Restore Purchases

    func restorePurchases(completion: @escaping (Result<Purchases.CustomerInfo, Error>) -> Void) {
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
    }

    // MARK: - Subscription Management

    func getSubscriptionInfo() -> SubscriptionInfo? {
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
    }

    // MARK: - Analytics

    func trackPurchaseAttempt(package: Purchases.Package) {
        AnalyticsManager.shared.trackSubscriptionCompleted(
            tier: .premium,
            subscriptionId: nil,
            price: package.storeProduct.flatMap { Double(truncating: NSDecimalNumber(decimal: $0.price)) },
            currency: package.storeProduct?.currencyCode ?? ""
        )
    }

    func trackPurchaseSuccess(package: Purchases.Package, customerInfo: Purchases.CustomerInfo) {
        AnalyticsManager.shared.trackSubscriptionCompleted(
            tier: .premium,
            subscriptionId: customerInfo.originalAppUserId,
            price: package.storeProduct.flatMap { Double(truncating: NSDecimalNumber(decimal: $0.price)) },
            currency: package.storeProduct?.currencyCode ?? ""
        )
    }

    func trackPurchaseFailure(package: Purchases.Package, error: Error) {
        // Track failed purchase
        print("Purchase failed for package \(package.identifier): \(error.localizedDescription)")
    }
}

extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: Purchases.CustomerInfo) {
        DispatchQueue.main.async {
            self.customerInfo = customerInfo
            self.updateSubscriptionStatus(from: customerInfo)
        }
    }
}

// MARK: - Supporting Types

struct SubscriptionInfo {
    let productName: String
    let expirationDate: Date
    let isTrial: Bool
}