import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
     @ObservedObject private var authService = AuthService.shared
     @StateObject private var viewModel = BookViewModel()
     @State private var capturedImage: UIImage?
     @State private var isShowingCamera = false
     @State private var selectedTab = 0
     @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

     private var userInitials: String {
         let name = authService.currentUser?.displayName ?? authService.currentUser?.email ?? "?"
         if name == "?" { return "?" }
         let components = name.split(separator: " ")
         if components.count >= 2 {
             let firstInitial = components.first?.first?.uppercased() ?? ""
             let lastInitial = components.last?.first?.uppercased() ?? ""
             return firstInitial + lastInitial
         } else if let first = components.first?.first?.uppercased() {
             return first
         }
         return "?"
     }

     var body: some View {
         Group {
             if authService.isAuthenticated {
                 if hasCompletedOnboarding {
                     authenticatedView
                 } else {
                     OnboardingView()
                 }
             } else {
                 HomeView()
             }
         }
         .onAppear {
             // Firebase is initialized in AppDelegate
             print("ContentView: onAppear - isAuthenticated: \(authService.isAuthenticated), hasCompletedOnboarding: \(hasCompletedOnboarding)")
         }
         .onChange(of: authService.isAuthenticated) { isAuthenticated in
             print("ContentView: Auth state changed to \(isAuthenticated), hasCompletedOnboarding: \(hasCompletedOnboarding)")
             if isAuthenticated {
                 // User signed in, refresh data
                 viewModel.refreshData()
             } else {
                 // User signed out, clear local data
                 viewModel.books = []
             }
         }
    }

    public var authenticatedView: some View {
        TabView(selection: $selectedTab) {
            LibraryView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(0)

            CurrentlyReadingView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
                .tabItem {
                    Label("Reading", systemImage: "book")
                }
                .tag(1)

            RecommendationsView(viewModel: viewModel)
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
                .tag(2)

            ProfileView(authService: authService)
                .tabItem {
                    VStack {
                        Text(userInitials)
                            .font(.system(size: 16, weight: .semibold))
                        Text("Profile")
                            .font(.caption2)
                    }
                }
                .tag(3)
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraView(capturedImage: $capturedImage, isShowingCamera: $isShowingCamera)
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                viewModel.scanBookshelf(image: image)
                capturedImage = nil
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}