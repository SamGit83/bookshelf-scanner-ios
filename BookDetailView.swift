import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BookDetailView: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @State private var bookDetails: BookRecommendation?
    @State private var isLoadingDetails = false
    @State private var recommendations: [BookRecommendation] = []
    @State private var isLoadingRecommendations = false
    @State private var showProgressView = false
    @State private var showEditView = false

    var body: some View {
        ZStack {
            AnimatedBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Book Cover and Basic Info
                    GlassCard {
                        VStack(spacing: 16) {
                            // Cover Image
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 150, height: 200)

                                if let coverURL = book.coverImageURL ?? bookDetails?.thumbnailURL, let url = URL(string: coverURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 140, height: 190)
                                                .cornerRadius(10)
                                        case .failure:
                                            Image(systemName: "book.fill")
                                                .resizable()
                                                .frame(width: 60, height: 80)
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            Image(systemName: "book.fill")
                                                .resizable()
                                                .frame(width: 60, height: 80)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                } else if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 140, height: 190)
                                        .cornerRadius(10)
                                } else {
                                    Image(systemName: "book.fill")
                                        .resizable()
                                        .frame(width: 60, height: 80)
                                        .foregroundColor(.gray)
                                }
                            }

                            // Title and Author
                            VStack(spacing: 8) {
                                Text(book.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)

                                Text(book.author)
                                    .font(.title2)
                                    .foregroundColor(.secondary)

                                // Genre and Publication
                                HStack(spacing: 16) {
                                    if let genre = book.genre ?? bookDetails?.genre {
                                        Text(genre)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(12)
                                    }

                                    if let publishedDate = bookDetails?.publishedDate {
                                        Text(publishedDate)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    // Description
                    if let description = bookDetails?.description, !description.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding()
                        }
                    }

                    // Reading Progress
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reading Progress")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Status: \(book.status.rawValue)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    if let totalPages = book.totalPages, totalPages > 0 {
                                        let progress = Double(book.currentPage) / Double(totalPages)
                                        Text("Page \(book.currentPage) of \(totalPages)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)

                                        ProgressView(value: progress)
                                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                            .frame(height: 8)
                                    } else {
                                        Text("No page information available")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding()
                    }

                    // Action Buttons
                    GlassCard {
                        VStack(spacing: 12) {
                            Text("Actions")
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                if book.status == .library {
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            viewModel.moveBook(book, to: .currentlyReading)
                                        }
                                    }) {
                                        Text("Start Reading")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .font(.headline)
                                    }
                                } else if book.status == .currentlyReading {
                                    Button(action: {
                                        showProgressView = true
                                    }) {
                                        Text("Update Progress")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .font(.headline)
                                    }
                                }

                                Button(action: {
                                    showEditView = true
                                }) {
                                    Text("Edit Book")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(10)
                                        .font(.headline)
                                }
                            }
                        }
                        .padding()
                    }

                    // Recommendations
                    if !recommendations.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("You Might Also Like")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(recommendations.prefix(5)) { recommendation in
                                            RecommendationCard(recommendation: recommendation)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProgressView) {
                ReadingProgressView(book: book, viewModel: viewModel)
            }
            .sheet(isPresented: $showEditView) {
                EditBookView(book: book, viewModel: viewModel)
            }
        }
        .onAppear {
            loadBookDetails()
            loadRecommendations()
        }
    }

    private func loadBookDetails() {
        isLoadingDetails = true
        let apiService = GoogleBooksAPIService()
        apiService.fetchBookDetails(isbn: book.isbn, title: book.title, author: book.author) { result in
            DispatchQueue.main.async {
                isLoadingDetails = false
                switch result {
                case .success(let details):
                    self.bookDetails = details
                case .failure(let error):
                    print("Failed to load book details: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadRecommendations() {
        isLoadingRecommendations = true
        viewModel.generateRecommendations { result in
            DispatchQueue.main.async {
                isLoadingRecommendations = false
                switch result {
                case .success(let recs):
                    // Filter out the current book
                    self.recommendations = recs.filter { $0.title != book.title || $0.author != book.author }
                case .failure(let error):
                    print("Failed to load recommendations: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: BookRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 120)

                if let thumbnailURL = recommendation.thumbnailURL, let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 76, height: 116)
                                .cornerRadius(6)
                        case .failure:
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 30, height: 40)
                                .foregroundColor(.gray)
                        @unknown default:
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 30, height: 40)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .frame(width: 30, height: 40)
                        .foregroundColor(.gray)
                }
            }

            Text(recommendation.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 80)

            Text(recommendation.author)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}