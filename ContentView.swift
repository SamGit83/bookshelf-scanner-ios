import SwiftUI
#if canImport(UIKit)
import UIKit
#endif


struct ContentView: View {
     @ObservedObject private var authService = AuthService.shared
     @ObservedObject private var themeManager = ThemeManager.shared
     @ObservedObject private var accentColorManager = AccentColorManager.shared
     @StateObject private var viewModel = BookViewModel()
     @State private var capturedImage: UIImage?
     @State private var isShowingCamera = false
     @State private var selectedTab = 0

     private var userInitials: String {
         let displayName = authService.currentUser?.displayName
         let email = authService.currentUser?.email
         let name = displayName ?? email ?? "?"
         print("DEBUG ContentView userInitials: currentUser exists: \(authService.currentUser != nil), displayName: \(displayName ?? "nil"), email: \(email ?? "nil"), name: \(name)")
         if name == "?" { return "?" }
         let components = name.split(separator: " ")
         if components.count >= 2 {
             let firstInitial = components.first?.first?.uppercased() ?? ""
             let lastInitial = components.last?.first?.uppercased() ?? ""
             let initials = firstInitial + lastInitial
             print("DEBUG ContentView userInitials: two components, initials: \(initials)")
             return initials
         } else if let first = components.first?.first?.uppercased() {
             print("DEBUG ContentView userInitials: one component, initials: \(first)")
             return first
         }
         print("DEBUG ContentView userInitials: fallback to ?")
         return "?"
     }

     var body: some View {
         Group {
             if authService.isAuthenticated {
                 // For authenticated users, assume they have completed onboarding
                 // unless explicitly marked as not completed
                 if authService.hasCompletedOnboarding || authService.isLoadingOnboardingStatus {
                     authenticatedView
                 } else {
                     OnboardingView()
                 }
             } else {
                 HomeView()
             }
         }
         .preferredColorScheme(themeManager.currentPreference.colorScheme)
         .onAppear {
             // Firebase is initialized in AppDelegate
             print("ContentView: onAppear - isAuthenticated: \(authService.isAuthenticated), hasCompletedOnboarding: \(authService.hasCompletedOnboarding)")
         }
         .onChange(of: authService.isAuthenticated) { isAuthenticated in
             print("ContentView: Auth state changed to \(isAuthenticated), hasCompletedOnboarding: \(authService.hasCompletedOnboarding), user: \(authService.currentUser?.email ?? "none")")
             if isAuthenticated {
                 // User signed in, refresh data
                 viewModel.refreshData()
             } else {
                 // User signed out, clear local data
                 viewModel.books = []
             }
         }
    }


    private var selectedView: some View {
        Group {
            switch selectedTab {
            case 0:
                LibraryView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
            case 1:
                ReadingView(viewModel: viewModel)
            case 2:
                DiscoverView(viewModel: viewModel)
            case 3:
                ProfileView(authService: authService)
            default:
                LibraryView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
            }
        }
    }

    public var authenticatedView: some View {
        NavigationView {
            ZStack {
                selectedView
                    .background(AppleBooksColors.background)
                VStack {
                    Spacer()
                    LiquidGlassTabBar(selectedTab: $selectedTab)
                }
                .edgesIgnoringSafeArea(.bottom)

                // Survey modal overlay
                SurveyModalView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isShowingCamera) {
            CameraView(capturedImage: $capturedImage, isShowingCamera: $isShowingCamera)
        }
        .onChange(of: isShowingCamera) { newValue in
            print("DEBUG: isShowingCamera changed to \(newValue)")
        }
        .onChange(of: capturedImage) { newImage in
            print("DEBUG ContentView: onChange capturedImage triggered, newImage is nil: \(newImage == nil)")
            if let image = newImage {
                print("DEBUG ContentView: Captured image received, calling scanBookshelf")
                viewModel.scanBookshelf(image: image)
                capturedImage = nil
                print("DEBUG ContentView: Set capturedImage to nil after scanBookshelf")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}