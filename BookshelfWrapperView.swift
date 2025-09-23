import SwiftUI

struct BookshelfWrapperView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = BookViewModel()
    @State private var capturedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
            } else {
                HomeView()
            }
        }
        .preferredColorScheme(themeManager.currentPreference.colorScheme)
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                viewModel.refreshData()
            } else {
                viewModel.books = []
            }
        }
    }

    private var authenticatedView: some View {
        ZStack {
            AppleBooksColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Daily Reading Goals Section
                    ReadingGoalsSection()

                    // Currently Reading Collection
                    AppleBooksCollection(
                        books: viewModel.books.filter { $0.status == .reading || $0.status == .currentlyReading },
                        title: "Continue Reading",
                        subtitle: "Pick up where you left off",
                        onBookTap: { book in
                            // Handle book tap - could navigate to detail view
                        },
                        onSeeAllTap: {
                            // Handle see all
                        },
                        viewModel: viewModel
                    )

                    // Featured Promotional Banner
                    AppleBooksPromoBanner(
                        title: "$9.99 Audiobooks",
                        subtitle: "Limited time offer",
                        gradient: LinearGradient(
                            colors: [AppleBooksColors.promotional, AppleBooksColors.promotional.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ) {
                        // Handle promo tap
                    }

                    // Customer Favorites
                    AppleBooksCollection(
                        books: Array(viewModel.books.prefix(5)), // Placeholder for favorites
                        title: "Customer Favorites",
                        subtitle: "See the books readers love",
                        onBookTap: { book in
                            // Handle book tap
                        },
                        onSeeAllTap: {
                            // Handle see all
                        },
                        viewModel: viewModel
                    )

                    // New & Trending
                    AppleBooksCollection(
                        books: Array(viewModel.books.suffix(5)), // Placeholder for trending
                        title: "New & Trending",
                        subtitle: "Explore what's hot in audiobooks",
                        onBookTap: { book in
                            // Handle book tap
                        },
                        onSeeAllTap: {
                            // Handle see all
                        },
                        viewModel: viewModel
                    )
                }
            }
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

struct BookshelfWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        BookshelfWrapperView()
    }
}