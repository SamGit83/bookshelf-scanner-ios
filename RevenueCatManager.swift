import Foundation
import Combine
import StoreKit

// Stub types for when Purchases is not available
struct Offering {}
struct CustomerInfo {}
struct Package {}

class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    @Published var offerings: [String: Offering] = [:]
    @Published var customerInfo: CustomerInfo?
    @Published var isSubscribed = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load initial data
        loadOfferings()
        loadCustomerInfo()
    }

    // MARK: - Configuration

    func configure(withAPIKey apiKey: String) {
        // Stub: do nothing
    }

    // MARK: - Offerings

    func loadOfferings() {
        // Stub: set empty offerings
        offerings = [:]
    }

    // MARK: - Customer Info

    func loadCustomerInfo() {
        // Stub: set nil customer info
        customerInfo = nil
        updateSubscriptionStatus(from: nil)
    }

    private func updateSubscriptionStatus(from customerInfo: CustomerInfo?) {
        // Stub: always free tier
        isSubscribed = false
        AuthService.shared.updateUserTier(.free)
    }

    // MARK: - Purchases

    func purchase(package: Package, completion: @escaping (Result<CustomerInfo, Error>) -> Void) {
        // Stub: simulate successful purchase
        let customerInfo = CustomerInfo()
        self.customerInfo = customerInfo
        updateSubscriptionStatus(from: customerInfo)
        completion(.success(customerInfo))
    }

    // MARK: - Restore Purchases

    func restorePurchases(completion: @escaping (Result<CustomerInfo, Error>) -> Void) {
        // Stub: simulate successful restore
        let customerInfo = CustomerInfo()
        self.customerInfo = customerInfo
        updateSubscriptionStatus(from: customerInfo)
        completion(.success(customerInfo))
    }

    // MARK: - Subscription Management

    func getSubscriptionInfo() -> SubscriptionInfo? {
        // Stub: no subscription info
        return nil
    }

    // MARK: - Analytics

    func trackPurchaseAttempt(package: Package) {
        // Stub: do nothing
    }

    func trackPurchaseSuccess(package: Package, customerInfo: CustomerInfo) {
        // Stub: do nothing
    }

    func trackPurchaseFailure(package: Package, error: Error) {
        // Stub: do nothing
    }
}


// MARK: - Supporting Types

struct SubscriptionInfo {
    let productName: String
    let expirationDate: Date
    let isTrial: Bool
}