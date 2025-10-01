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
            .background(Color(red: 0.949, green: 0.949, blue: 0.969))
            .onAppear {
                // Transition to main content after splash animation completes
                // Animation timing: 0.8s icon + 12 letters × 0.15s delay + 0.3s bounce + 0.7s buffer = 3.6s
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplashScreen = false
                    }
                }
            }
        }
    }
}