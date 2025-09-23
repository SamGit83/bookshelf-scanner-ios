import SwiftUI
import FirebaseCore

@main
struct BookshelfScannerApp: App {
    init() {
        // Configure Firebase using GoogleService-Info.plist
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}