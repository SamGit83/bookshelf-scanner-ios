import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var viewModel = BookViewModel()
    @State private var capturedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ErrorBoundary {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView()
                } else if authService.isAuthenticated {
                    authenticatedView
                } else {
                    LoginView()
                }
            }
        }
        .onAppear {
            // Initialize Firebase
            _ = FirebaseConfig.shared
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            withAnimation(.spring()) {
                if isAuthenticated {
                    // User signed in, refresh data
                    viewModel.refreshData()
                } else {
                    // User signed out, clear local data
                    viewModel.books = []
                }
            }
        }
        .animation(.spring(), value: authService.isAuthenticated)
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
        .accentColor(.blue)
        .sheet(isPresented: $isShowingCamera) {
            CameraView(capturedImage: $capturedImage, isShowingCamera: $isShowingCamera)
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                viewModel.scanBookshelf(image: image)
                capturedImage = nil
            }
        }
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ErrorWrapper(error: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { errorWrapper in
            Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
        }
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}