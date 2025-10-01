import SwiftUI
import FirebaseCore

@main
struct BookshelfScannerApp: App {
    @State private var showSplashScreen = true
    
    init() {
        // Configure Firebase using GoogleService-Info.plist
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplashScreen {
                    SplashScreenView()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Transition to main content after splash animation completes
                // Animation timing: 0.8s icon + 12 letters × 0.1s delay + 0.3s bounce + 0.5s buffer = 3.0s
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplashScreen = false
                    }
                }
            }
        }
    }
}