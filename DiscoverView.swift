import SwiftUI

struct DiscoverView: View {
    @ObservedObject var viewModel: BookViewModel
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @State private var recommendations: [BookRecommendation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefreshDate: Date?
    @State private var selectedBook: Book?
    @State private var showUpgradeModal = false
    @State private var hasFetchedRecommendations = false
@AppStorage("showRecommendations") private var showRecommendations = false

    // Group recommendations by genre for categories
    private var recommendationsByGenre: [String: [BookRecommendation]] {
        Dictionary(grouping: recommendations) { recommendation in
            recommendation.genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || recommendation.genre.lowercased() == "unknown" ? "General" : recommendation.genre
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $showRecommendations) {
                Text("Show Recommendations")
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.text)
            }
            .toggleStyle(.switch)
            .padding(.horizontal, AppleBooksSpacing.space24)
            .padding(.vertical, AppleBooksSpacing.space16)
            .onChange(of: showRecommendations) { oldValue, newValue in
                if newValue {
                    loadRecommendations()
                }
            }

            ZStack {
                AppleBooksColors.background
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: AppleBooksSpacing.space20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Discovering great books for you...")
                            .font(AppleBooksTypography.bodyMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)
                    }
                    .padding()
                } else if let error = errorMessage {
                    VStack(spacing: AppleBooksSpacing.space20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(SemanticColors.warningPrimary)
                        Text("Unable to load recommendations")
                            .font(AppleBooksTypography.headlineMedium)
                            .foregroundColor(AppleBooksColors.text)
                        Text(error)
                            .font(AppleBooksTypography.bodyMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button(action: loadRecommendations) {
                            Text("Try Again")
                                .font(AppleBooksTypography.buttonLarge)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppleBooksColors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                } else if showRecommendations && recommendations.isEmpty {
                    VStack(spacing: AppleBooksSpacing.space20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(AppleBooksColors.textSecondary)
                        Text("No recommendations yet")
                            .font(AppleBooksTypography.headlineMedium)
                            .foregroundColor(AppleBooksColors.text)
                        Text("Add some books to your library to get personalized recommendations powered by intelligent AI!")
                            .font(AppleBooksTypography.bodyMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: loadRecommendations) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Get Recommendations")
                            }
                            .font(AppleBooksTypography.buttonLarge)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppleBooksColors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                } else if showRecommendations && !recommendations.isEmpty {
                    ScrollView {
                        VStack(spacing: AppleBooksSpacing.space32) {
                            // Header with Grok AI branding
                            VStack(spacing: AppleBooksSpacing.space8) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(Color(hex: "FF2D92"))
                                    Text("Powered by Smart AI")
                                        .font(AppleBooksTypography.captionBold)
                                        .foregroundColor(Color(hex: "FF2D92"))
                                }
                                Text("Personalized recommendations based on your library")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, AppleBooksSpacing.space24)
                            .padding(.top, AppleBooksSpacing.space16)

                            // All Recommendations Section
                            if !recommendations.isEmpty {
                                AppleBooksCollection(
                                    books: recommendations.map { convertToBook($0) },
                                    title: "Recommended for You",
                                    subtitle: "\(recommendations.count) personalized picks",
                                    onBookTap: { book in
                                        selectedBook = book
                                    },
                                    onSeeAllTap: nil,
                                    onEditTap: nil,
                                    viewModel: viewModel
                                )
                            }

                            // Categories Sections
                            ForEach(recommendationsByGenre.keys.sorted(), id: \.self) { genre in
                                if let genreRecommendations = recommendationsByGenre[genre], !genreRecommendations.isEmpty {
                                    AppleBooksCollection(
                                        books: genreRecommendations.map { convertToBook($0) },
                                        title: genre,
                                        subtitle: "\(genreRecommendations.count) books",
                                        onBookTap: { book in
                                            selectedBook = book
                                        },
                                        onSeeAllTap: nil,
                                        onEditTap: nil,
                                        viewModel: viewModel
                                    )
                                }
                            }
                        }
                        .padding(.vertical, AppleBooksSpacing.space24)
                    }
                }
            }
        }
        .onAppear {
            if showRecommendations && !hasFetchedRecommendations {
                loadRecommendations()
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: loadRecommendations) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppleBooksColors.accent)
                }
                .disabled(isLoading || !showRecommendations)
            }
        }
        .sheet(item: $selectedBook) { book in
            BookDetailView(book: book, viewModel: viewModel)
        }
        .sheet(isPresented: $showUpgradeModal) {
            UpgradeModalView()
        }
    }

    // Helper to convert BookRecommendation to Book for AppleBooksCollection
    private func convertToBook(_ recommendation: BookRecommendation) -> Book {
        var book = Book(
            title: recommendation.title,
            author: recommendation.author,
            genre: recommendation.genre,
            status: .toRead,
            coverImageURL: recommendation.thumbnailURL
        )

        // Add additional metadata if available
        if let pageCount = recommendation.pageCount {
            book.pageCount = pageCount
        }

        if let publishedDate = recommendation.publishedDate {
            book.publicationYear = publishedDate
        }

        book.teaser = recommendation.description

        return book
    }

    private func loadRecommendations() {
        guard !isLoading else { return }

        guard showRecommendations else { return }

        // Don't load recommendations if user has no books
        guard !viewModel.books.isEmpty else {
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil

        // Try to load cached recommendations first
        if let cachedRecommendations = OfflineCache.shared.loadCachedRecommendations() {
            recommendations = cachedRecommendations
        }

        viewModel.generateRecommendations { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let newRecommendations):
                    recommendations = newRecommendations
                    lastRefreshDate = Date()
                    errorMessage = nil
                    hasFetchedRecommendations = true
                case .failure(let error):
                    // Check if it's a limit error
                    if error.localizedDescription.contains("Recommendation limit reached") {
                        showUpgradeModal = true
                    } else {
                        // If we have cached data, keep using it; otherwise show error
                        if recommendations.isEmpty {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    private func shouldRefreshRecommendations() -> Bool {
        guard let lastRefresh = lastRefreshDate else { return true }
        return Date().timeIntervalSince(lastRefresh) > 3600 // Refresh every hour
    }
}


struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(viewModel: BookViewModel())
    }
}