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
        } else {
        }
        #endif

        return true
    }
}