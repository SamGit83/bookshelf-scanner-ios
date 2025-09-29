import UIKit
#if canImport(RevenueCat)
import RevenueCat
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Initialize RevenueCat
        #if canImport(RevenueCat)
        if let apiKey = SecureConfig.shared.revenueCatAPIKey {
            Purchases.configure(withAPIKey: apiKey)
            print("RevenueCat initialized with API key")
        } else {
            print("RevenueCat API key not configured - purchases will be simulated")
        }
        #endif

        return true
    }
}