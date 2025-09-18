import SwiftUI

struct RecommendationsView: View {
    @ObservedObject var viewModel: BookViewModel
    @State private var recommendations: [BookRecommendation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefreshDate: Date?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Finding great books for you...")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Unable to load recommendations")
                            .font(.title2)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button(action: loadRecommendations) {
                            Text("Try Again")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                } else if recommendations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No recommendations yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Add some books to your library to get personalized recommendations!")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        Section(header: Text("Recommended for You")) {
                            ForEach(recommendations) { recommendation in
                                RecommendationRowView(recommendation: recommendation, viewModel: viewModel)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
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

struct RecommendationRowView: View {
    let recommendation: BookRecommendation
    @ObservedObject var viewModel: BookViewModel
    @State private var isAddingToLibrary = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Book cover or placeholder
            if let thumbnailURL = recommendation.thumbnailURL,
               let url = URL(string: thumbnailURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 90)
                            .cornerRadius(5)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(5)
                    case .failure:
                        Image(systemName: "book")
                            .resizable()
                            .frame(width: 60, height: 90)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "book")
                    .resizable()
                    .frame(width: 60, height: 90)
                    .foregroundColor(.gray)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(recommendation.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                if let genre = recommendation.genre {
                    Text(genre)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                if let description = recommendation.description {
                    Text(recommendation.displayDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                HStack {
                    if let publishedDate = recommendation.publishedDate {
                        Text("Published: \(publishedDate)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    if let pageCount = recommendation.pageCount {
                        Text("• \(pageCount) pages")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            Button(action: addToLibrary) {
                if isAddingToLibrary {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .disabled(isAddingToLibrary)
        }
        .padding(.vertical, 8)
    }

    private func addToLibrary() {
        isAddingToLibrary = true

        // Convert recommendation to Book
        let book = Book(
            title: recommendation.title,
            author: recommendation.author,
            genre: recommendation.genre,
            status: .library
        )

        viewModel.saveBookToFirestore(book)

        // Show feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isAddingToLibrary = false
        }
    }
}