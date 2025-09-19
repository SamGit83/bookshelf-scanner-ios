import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var viewModel = BookViewModel()
    @State private var capturedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Firebase is initialized in AppDelegate
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // User signed in, refresh data
                viewModel.refreshData()
            } else {
                // User signed out, clear local data
                viewModel.books = []
            }
        }
    }

    private var authenticatedView: some View {
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
                    Label("Profile", systemImage: "person.circle")
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