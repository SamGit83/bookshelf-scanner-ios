import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BookDetailView: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel

    private var currentBook: Book {
        viewModel.books.first(where: { $0.id == book.id }) ?? book
    }
    @State private var bookDetails: BookRecommendation?
    @State private var isLoadingDetails = false
    @State private var recommendations: [BookRecommendation] = []
    @State private var isLoadingRecommendations = false
    @State private var showProgressView = false
    @State private var showEditView = false
    @State private var isLoadingBio = false
    @State private var isLoadingTeaser = false

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

                                if let coverURL = book.coverImageURL ?? bookDetails?.thumbnailURL {
                                    if let url = URL(string: coverURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 140, height: 190)
                                                .cornerRadius(10)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    } else {
                                        Image(systemName: "book.fill")
                                            .resizable()
                                            .frame(width: 60, height: 80)
                                            .foregroundColor(.gray)
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
                                Text(currentBook.title ?? "Unknown Title")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)

                                Text(currentBook.author ?? "Unknown Author")
                                    .font(.title2)
                                    .foregroundColor(.secondary)

                                // Genre and Publication
                                HStack(spacing: 16) {
                                    if let genre = currentBook.genre ?? bookDetails?.genre {
                                        Text(genre)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(12)
                                    }

                                    if let subGenre = currentBook.subGenre {
                                        Text(subGenre)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(12)
                                    }

                                    if let publishedDate = bookDetails?.publishedDate ?? currentBook.publicationYear {
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

                    // Book Details
                    if (currentBook.pageCount ?? bookDetails?.pageCount) != nil || currentBook.estimatedReadingTime != nil {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Book Details")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if let pageCount = currentBook.pageCount ?? bookDetails?.pageCount {
                                    Text("Page Count: \(pageCount)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                if let readingTime = currentBook.estimatedReadingTime {
                                    Text("Estimated Reading Time: \(readingTime)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                        }
                    }

                    // Book Teaser
                    if let teaser = book.teaser, !teaser.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Book Teaser")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(teaser)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding()
                        }
                    } else {
                        print("DEBUG BookDetailView: Book teaser is nil or empty for book: \(book.title ?? "Unknown")")
                        if isLoadingTeaser {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Book Teaser")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                                .padding()
                            }
                        }
                    }

                    // Author Biography
                    if let bio = book.authorBio ?? book.authorBiography, !bio.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About the Author")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(bio)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding()
                        }
                    } else {
                        print("DEBUG BookDetailView: Author bio is nil or empty for book: \(book.title ?? "Unknown") by \(book.author ?? "Unknown")")
                        if isLoadingBio {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("About the Author")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
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
                                    Text("Status: \(currentBook.status.rawValue)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    if let totalPages = currentBook.totalPages, totalPages > 0 {
                                        let progress = Double(currentBook.currentPage) / Double(totalPages)
                                        Text("Page \(currentBook.currentPage) of \(totalPages)")
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
                                if currentBook.status == .library {
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            viewModel.moveBook(currentBook, to: .currentlyReading)
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
                                } else if currentBook.status == .currentlyReading {
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
                ReadingProgressView(book: currentBook, viewModel: viewModel)
            }
            .sheet(isPresented: $showEditView) {
                EditBookView(book: currentBook, viewModel: viewModel)
            }
        }
        .onAppear {
            loadBookDetails()
            loadRecommendations()
        }
    }

    func loadBookDetails() {
        isLoadingDetails = true
        let apiService = GoogleBooksAPIService()
        apiService.fetchBookDetails(isbn: currentBook.isbn, title: currentBook.title, author: currentBook.author) { result in
            DispatchQueue.main.async {
                self.isLoadingDetails = false
                switch result {
                case .success(let details):
                    self.bookDetails = details
                    // Fetch book teaser if not cached
                    if self.currentBook.teaser == nil || self.currentBook.teaser?.isEmpty == true,
                        let title = self.currentBook.title, let author = self.currentBook.author {
                        self.loadBookTeaser(title: title, author: author)
                    }
                    // Fetch author bio if not cached
                    if (self.currentBook.authorBio ?? self.currentBook.authorBiography) == nil || (self.currentBook.authorBio ?? self.currentBook.authorBiography)?.isEmpty == true,
                        let author = self.currentBook.author {
                        self.loadAuthorBiography(author: author)
                    }
                case .failure(let error):
                    print("Failed to load book details: \(error.localizedDescription)")
                    // Still try to load teaser and bio if details failed and not cached
                    if self.currentBook.teaser == nil || self.currentBook.teaser?.isEmpty == true,
                        let title = self.currentBook.title, let author = self.currentBook.author {
                        self.loadBookTeaser(title: title, author: author)
                    }
                    if (self.currentBook.authorBio ?? self.currentBook.authorBiography) == nil || (self.currentBook.authorBio ?? self.currentBook.authorBiography)?.isEmpty == true,
                        let author = self.currentBook.author {
                        self.loadAuthorBiography(author: author)
                    }
                }
            }
        }
    }

    func loadAuthorBiography(author: String) {
        isLoadingBio = true
        let grokService = GrokAPIService()
        grokService.fetchAuthorBiography(author: author) { result in
            DispatchQueue.main.async {
                self.isLoadingBio = false
                switch result {
                case .success(let bio):
                    self.viewModel.updateBookAuthorBio(self.currentBook, authorBio: bio)
                case .failure(let error):
                    print("Failed to load author biography: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadBookTeaser(title: String, author: String) {
        isLoadingTeaser = true
        let grokService = GrokAPIService()
        grokService.fetchBookSummary(title: title, author: author) { result in
            DispatchQueue.main.async {
                self.isLoadingTeaser = false
                switch result {
                case .success(let teaser):
                    self.viewModel.updateBookTeaser(self.currentBook, teaser: teaser)
                case .failure(let error):
                    print("Failed to load book teaser: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadRecommendations() {
        isLoadingRecommendations = true
        viewModel.generateRecommendations(for: currentBook) { result in
            DispatchQueue.main.async {
                isLoadingRecommendations = false
                switch result {
                case .success(let recs):
                    // Filter out the current book
                    self.recommendations = recs.filter { $0.title != (currentBook.title ?? "") || $0.author != (currentBook.author ?? "") }
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

                if let thumbnailURL = recommendation.thumbnailURL {
                    if let url = URL(string: thumbnailURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 76, height: 116)
                                .cornerRadius(6)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "book.fill")
                            .resizable()
                            .frame(width: 30, height: 40)
                            .foregroundColor(.gray)
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