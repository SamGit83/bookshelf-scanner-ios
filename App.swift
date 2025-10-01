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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplashScreen = false
                    }
                }
            }
        }
    }
}