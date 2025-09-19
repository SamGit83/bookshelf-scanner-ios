import SwiftUI

// Removed @main - this is now a library component
// The iOS app will have its own @main struct
public struct BookshelfScannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    public init() {}

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}