import SwiftUI
import LiquidGlassDesignSystem

struct RecommendationsView: View {
    @ObservedObject var viewModel: BookViewModel
    @State private var recommendations: [BookRecommendation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefreshDate: Date?

    // Group recommendations by genre for categories
    private var recommendationsByGenre: [String: [BookRecommendation]] {
        Dictionary(grouping: recommendations) { recommendation in
            recommendation.genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || recommendation.genre.lowercased() == "unknown" ? "General" : recommendation.genre
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppleBooksColors.background
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: AppleBooksSpacing.space20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Finding great books for you...")
                            .font(AppleBooksTypography.bodyMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)
                    }
                    .padding()
                } else if let error = errorMessage {
                    VStack(spacing: AppleBooksSpacing.space20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(AppleBooksColors.warningPrimary)
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
                } else if recommendations.isEmpty {
                    VStack(spacing: AppleBooksSpacing.space20) {
                        Image(systemName: "book")
                            .font(.system(size: 60))
                            .foregroundColor(AppleBooksColors.textSecondary)
                        Text("No recommendations yet")
                            .font(AppleBooksTypography.headlineMedium)
                            .foregroundColor(AppleBooksColors.text)
                        Text("Add some books to your library to get personalized recommendations!")
                            .font(AppleBooksTypography.bodyMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: AppleBooksSpacing.space32) {
                            // Personalized Recommendations Section
                            AppleBooksCollection(
                                books: recommendations.map { convertToBook($0) },
                                title: "Recommended for You",
                                subtitle: "Personalized picks based on your library",
                                viewModel: viewModel
                            ) { book in
                                // Handle book tap - perhaps navigate to detail
                            }

                            // Categories Sections
                            ForEach(recommendationsByGenre.keys.sorted(), id: \.self) { genre in
                                if let genreRecommendations = recommendationsByGenre[genre], !genreRecommendations.isEmpty {
                                    AppleBooksCollection(
                                        books: genreRecommendations.map { convertToBook($0) },
                                        title: genre,
                                        subtitle: "\(genreRecommendations.count) books",
                                        viewModel: viewModel
                                    ) { book in
                                        // Handle book tap
                                    }
                                }
                            }
                        }
                        .padding(.vertical, AppleBooksSpacing.space24)
                    }
                }
            }
            .navigationTitle("Recommendations")
            .navigationBarItems(trailing: Button(action: loadRecommendations) {
                Image(systemName: "arrow.clockwise")
            })
            .onAppear {
                if recommendations.isEmpty || shouldRefreshRecommendations() {
                    loadRecommendations()
                }
            }
        }
    }

    // Helper to convert BookRecommendation to Book for AppleBooksCollection
    private func convertToBook(_ recommendation: BookRecommendation) -> Book {
        Book(
            title: recommendation.title,
            author: recommendation.author,
            genre: recommendation.genre,
            status: .library,
            coverImageURL: recommendation.thumbnailURL
        )
    }

    private func loadRecommendations() {
        guard !isLoading else { return }

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
                case .failure(let error):
                    // If we have cached data, keep using it; otherwise show error
                    if recommendations.isEmpty {
                        errorMessage = error.localizedDescription
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
