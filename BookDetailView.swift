import SwiftUI
import LiquidGlassDesignSystem
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
        ScrollView {
            VStack(spacing: AppleBooksSpacing.space32) {
                // Book Cover Section
                VStack(spacing: AppleBooksSpacing.space20) {
                    // Large Cover Image
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 200, height: 300)
                            .shadow(color: AppleBooksShadow.subtle.color, radius: AppleBooksShadow.subtle.radius, x: AppleBooksShadow.subtle.x, y: AppleBooksShadow.subtle.y)

                        if let coverURL = book.coverImageURL ?? bookDetails?.thumbnailURL {
                            if let url = URL(string: coverURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 190, height: 290)
                                        .cornerRadius(12)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Image(systemName: "book.fill")
                                    .resizable()
                                    .frame(width: 80, height: 120)
                                    .foregroundColor(.gray)
                                }
                        } else if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 190, height: 290)
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 80, height: 120)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
                .padding(.top, AppleBooksSpacing.space32)

                // Book Metadata Section
                AppleBooksCard {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space12) {
                        // Title
                        Text(currentBook.title ?? "Unknown Title")
                            .font(AppleBooksTypography.displayMedium)
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.leading)

                        // Author
                        Text(currentBook.author ?? "Unknown Author")
                            .font(AppleBooksTypography.headlineMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)

                        // Genre and Publication Info
                        HStack(spacing: AppleBooksSpacing.space12) {
                            if let genre = currentBook.genre ?? bookDetails?.genre {
                                Text(genre)
                                    .font(AppleBooksTypography.captionBold)
                                    .foregroundColor(AppleBooksColors.accent)
                                    .padding(.horizontal, AppleBooksSpacing.space8)
                                    .padding(.vertical, AppleBooksSpacing.space4)
                                    .background(AppleBooksColors.accent.opacity(0.1))
                                    .cornerRadius(6)
                            }

                            if let subGenre = currentBook.subGenre {
                                Text(subGenre)
                                    .font(AppleBooksTypography.captionBold)
                                    .foregroundColor(AppleBooksColors.success)
                                    .padding(.horizontal, AppleBooksSpacing.space8)
                                    .padding(.vertical, AppleBooksSpacing.space4)
                                    .background(AppleBooksColors.success.opacity(0.1))
                                    .cornerRadius(6)
                            }

                            if let publishedDate = bookDetails?.publishedDate ?? currentBook.publicationYear {
                                Text(publishedDate)
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.textTertiary)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)

                // Description Section
                if let description = bookDetails?.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "Description",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        AppleBooksCard {
                            Text(description)
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.text)
                                .lineSpacing(6)
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }

                // Book Details Section
                if (currentBook.pageCount ?? bookDetails?.pageCount) != nil || currentBook.estimatedReadingTime != nil {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "Book Details",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        AppleBooksCard {
                            VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                if let pageCount = currentBook.pageCount ?? bookDetails?.pageCount {
                                    HStack {
                                        Text("Pages")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                        Spacer()
                                        Text("\(pageCount)")
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.text)
                                    }
                                }

                                if let readingTime = currentBook.estimatedReadingTime {
                                    HStack {
                                        Text("Reading Time")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                        Spacer()
                                        Text(readingTime)
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.text)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }

                // Book Teaser Section
                if let teaser = book.teaser, !teaser.isEmpty {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "Book Teaser",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        AppleBooksCard {
                            Text(teaser)
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.text)
                                .lineSpacing(6)
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                } else if isLoadingTeaser {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "Book Teaser",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        AppleBooksCard {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }

                // Author Biography Section
                if let bio = book.authorBio ?? book.authorBiography, !bio.isEmpty {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "About the Author",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        AppleBooksCard {
                            Text(bio)
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.text)
                                .lineSpacing(6)
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                } else if isLoadingBio {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "About the Author",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        AppleBooksCard {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }

                // Reading Progress Section
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                    AppleBooksSectionHeader(
                        title: "Reading Progress",
                        subtitle: nil,
                        showSeeAll: false,
                        seeAllAction: nil
                    )

                    AppleBooksCard {
                        VStack(alignment: .leading, spacing: AppleBooksSpacing.space12) {
                            HStack {
                                Text("Status")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Spacer()
                                Text(currentBook.status.rawValue)
                                    .font(AppleBooksTypography.bodyLarge)
                                    .foregroundColor(AppleBooksColors.text)
                            }

                            if let totalPages = currentBook.totalPages, totalPages > 0 {
                                let progress = Double(currentBook.currentPage) / Double(totalPages)
                                VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                    HStack {
                                        Text("Progress")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                        Spacer()
                                        Text("\(currentBook.currentPage) of \(totalPages) pages")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(AppleBooksColors.text)
                                    }

                                    ProgressView(value: progress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: AppleBooksColors.accent))
                                        .frame(height: 6)
                                }
                            } else {
                                Text("No page information available")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)

                // Action Buttons Section
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                    AppleBooksSectionHeader(
                        title: "Actions",
                        subtitle: nil,
                        showSeeAll: false,
                        seeAllAction: nil
                    )

                    AppleBooksCard {
                        VStack(spacing: AppleBooksSpacing.space12) {
                            if currentBook.status == .library {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewModel.moveBook(currentBook, to: .currentlyReading)
                                    }
                                }) {
                                    Text("Start Reading")
                                        .font(AppleBooksTypography.buttonLarge)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppleBooksSpacing.space16)
                                        .background(AppleBooksColors.accent)
                                        .cornerRadius(12)
                                }
                            } else if currentBook.status == .currentlyReading {
                                Button(action: {
                                    showProgressView = true
                                }) {
                                    Text("Update Progress")
                                        .font(AppleBooksTypography.buttonLarge)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppleBooksSpacing.space16)
                                        .background(AppleBooksColors.success)
                                        .cornerRadius(12)
                                }
                            }

                            Button(action: {
                                showEditView = true
                            }) {
                                Text("Edit Book")
                                    .font(AppleBooksTypography.buttonLarge)
                                    .foregroundColor(AppleBooksColors.text)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppleBooksSpacing.space16)
                                    .background(AppleBooksColors.card.opacity(0.5))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)

                // Recommendations Section
                if !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "You Might Also Like",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppleBooksSpacing.space16) {
                                ForEach(recommendations.prefix(5)) { recommendation in
                                    AppleBooksBookCard(
                                        book: Book(
                                            title: recommendation.title,
                                            author: recommendation.author,
                                            coverImageURL: recommendation.thumbnailURL,
                                            genre: nil,
                                            subGenre: nil,
                                            publicationYear: nil,
                                            pageCount: nil,
                                            estimatedReadingTime: nil,
                                            isbn: nil,
                                            status: .library
                                        ),
                                        onTap: {},
                                        showAddButton: false,
                                        onAddTap: nil
                                    )
                                }
                            }
                            .padding(.horizontal, AppleBooksSpacing.space24)
                        }
                    }
                }

                Spacer(minLength: AppleBooksSpacing.space64)
            }
            .background(AppleBooksColors.background)
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

    private func loadBookDetails() {
        isLoadingDetails = true
        let apiService = GoogleBooksAPIService()
        apiService.fetchBookDetails(isbn: currentBook.isbn, title: currentBook.title, author: currentBook.author) { result in
            DispatchQueue.main.async {
                self.isLoadingDetails = false
                switch result {
                case .success(let details):
                    self.bookDetails = details
                    // Fetch book teaser if not cached
                    if self.currentBook.teaser == nil || self.currentBook.teaser?.isEmpty == true {
                        if let title = self.currentBook.title, let author = self.currentBook.author {
                            self.loadBookTeaser(title: title, author: author)
                        }
                    }
                    // Fetch author bio if not cached
                    if (self.currentBook.authorBio ?? self.currentBook.authorBiography) == nil || (self.currentBook.authorBio ?? self.currentBook.authorBiography)?.isEmpty == true {
                        if let author = self.currentBook.author {
                            self.loadAuthorBiography(author: author)
                        }
                    }
                case .failure(let error):
                    print("Failed to load book details: \(error.localizedDescription)")
                    // Still try to load teaser and bio if details failed and not cached
                    if self.currentBook.teaser == nil || self.currentBook.teaser?.isEmpty == true {
                        if let title = self.currentBook.title, let author = self.currentBook.author {
                            self.loadBookTeaser(title: title, author: author)
                        }
                    }
                    if (self.currentBook.authorBio ?? self.currentBook.authorBiography) == nil || (self.currentBook.authorBio ?? self.currentBook.authorBiography)?.isEmpty == true {
                        if let author = self.currentBook.author {
                            self.loadAuthorBiography(author: author)
                        }
                    }
                }
            }
        }
    }

    private func loadAuthorBiography(author: String) {
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

    private func loadBookTeaser(title: String, author: String) {
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

    private func loadRecommendations() {
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
