import SwiftUI

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
            withAnimation(LiquidGlass.Animation.spring) {
                if isAuthenticated {
                    // User signed in, refresh data
                    viewModel.refreshData()
                } else {
                    // User signed out, clear local data
                    viewModel.books = []
                }
            }
        }
        .animation(LiquidGlass.Animation.spring, value: authService.isAuthenticated)
    }

    private var authenticatedView: some View {
        ZStack(alignment: .bottom) {
            // Main content with blur background
            TabView(selection: $selectedTab) {
                LibraryView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
                    .tag(0)

                CurrentlyReadingView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
                    .tag(1)

                RecommendationsView(viewModel: viewModel)
                    .tag(2)

                ProfileView(authService: authService)
                    .tag(3)
            }
            .background(
                // Dynamic background based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        LiquidGlass.primary.opacity(0.1)
                    case 1:
                        LiquidGlass.secondary.opacity(0.1)
                    case 2:
                        LiquidGlass.accent.opacity(0.1)
                    case 3:
                        LiquidGlass.success.opacity(0.1)
                    default:
                        LiquidGlass.primary.opacity(0.1)
                    }
                }
                .ignoresSafeArea()
            )

            // Custom Liquid Glass Tab Bar
            LiquidGlassTabBarWithIndicator(selectedTab: $selectedTab)
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