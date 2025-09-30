import Foundation
import Combine
import StoreKit

// Stub types for when Purchases is not available
struct StoreProduct {
    var productIdentifier: String
    var subscriptionPeriod: SubscriptionPeriod?
}

struct SubscriptionPeriod {
    var unit: Unit
}

enum Unit: String {
    case year = "year"
    case month = "month"
}

struct Package {
    var identifier: String
    var storeProduct: StoreProduct
}

struct Offering {
    var identifier: String
    var availablePackages: [Package]
    var packages: [Package] { availablePackages }
}

struct CustomerInfo {}

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
        // Stub: create default offering with packages
        let monthlyPackage = Package(
            identifier: "premium_monthly",
            storeProduct: StoreProduct(
                productIdentifier: "premium_monthly",
                subscriptionPeriod: SubscriptionPeriod(unit: .month)
            )
        )
        let yearlyPackage = Package(
            identifier: "premium_yearly",
            storeProduct: StoreProduct(
                productIdentifier: "premium_yearly",
                subscriptionPeriod: SubscriptionPeriod(unit: .year)
            )
        )
        let offering = Offering(
            identifier: "default",
            availablePackages: [monthlyPackage, yearlyPackage]
        )
        offerings = ["default": offering]
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