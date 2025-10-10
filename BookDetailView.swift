import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BookDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    private let rateLimiter = RateLimiter()
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    private var adaptivePadding: CGFloat {
        isIPad ? 64 : 24
    }
    
    private var maxContentWidth: CGFloat {
        isIPad ? 800 : .infinity
    }
    
    private var sectionMaxWidth: CGFloat {
        isIPad ? 700 : .infinity
    }
    
    private var gridColumns: [GridItem] {
        let count = isIPad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

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

    private var bookCoverSection: some View {
        VStack(spacing: AppleBooksSpacing.space20) {
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
        .frame(maxWidth: sectionMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, adaptivePadding)
        .padding(.top, AppleBooksSpacing.space32)
    }

    private var bookMetadataSection: some View {
        AppleBooksCard {
            VStack(alignment: .leading, spacing: AppleBooksSpacing.space12) {
                Text(currentBook.title ?? "Unknown Title")
                    .font(AppleBooksTypography.displayMedium)
                    .foregroundColor(AppleBooksColors.text)
                    .multilineTextAlignment(.leading)

                Text(currentBook.author ?? "Unknown Author")
                    .font(AppleBooksTypography.headlineMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)

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
        .frame(maxWidth: sectionMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, adaptivePadding)
    }

    // Removed descriptionSection to avoid duplication with AI-generated teaser

    private var bookDetailsSection: AnyView {
        if (currentBook.pageCount ?? bookDetails?.pageCount) != nil || currentBook.estimatedReadingTime != nil || currentBook.isbn != nil {
            AnyView(VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                AppleBooksSectionHeader(
                    title: "Book Details",
                    subtitle: nil,
                    showSeeAll: false,
                    seeAllAction: {}
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

                        if let isbn = currentBook.isbn {
                            HStack {
                                Text("ISBN")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Spacer()
                                Text(isbn)
                                    .font(AppleBooksTypography.bodyLarge)
                                    .foregroundColor(AppleBooksColors.text)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: sectionMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, adaptivePadding))
        } else {
            AnyView(EmptyView())
        }
    }

    private var bookTeaserSection: AnyView {
        if let teaser = currentBook.teaser, !teaser.isEmpty {
            AnyView(VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                AppleBooksSectionHeader(
                    title: "Book Teaser",
                    subtitle: nil,
                    showSeeAll: false,
                    seeAllAction: {}
                )

                AppleBooksCard {
                    Text(teaser)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .lineSpacing(6)
                }
            }
            .frame(maxWidth: sectionMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, adaptivePadding))
        } else if isLoadingTeaser {
            AnyView(VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                AppleBooksSectionHeader(
                    title: "Book Teaser",
                    subtitle: nil,
                    showSeeAll: false,
                    seeAllAction: {}
                )

                AppleBooksCard {
                    ProgressView()
                }
            }
            .frame(maxWidth: sectionMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, adaptivePadding))
        } else {
            AnyView(EmptyView())
        }
    }

    private var authorBiographySection: AnyView {
        if let bio = currentBook.authorBio ?? currentBook.authorBiography, !bio.isEmpty {
            AnyView(VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                AppleBooksSectionHeader(
                    title: "About the Author",
                    subtitle: nil,
                    showSeeAll: false,
                    seeAllAction: {}
                )

                AppleBooksCard {
                    Text(bio)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .lineSpacing(6)
                }
            }
            .frame(maxWidth: sectionMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, adaptivePadding))
        } else if isLoadingBio {
            AnyView(VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                AppleBooksSectionHeader(
                    title: "About the Author",
                    subtitle: nil,
                    showSeeAll: false,
                    seeAllAction: {}
                )

                AppleBooksCard {
                    ProgressView()
                }
            }
            .frame(maxWidth: sectionMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, adaptivePadding))
        } else {
            AnyView(EmptyView())
        }
    }

    private var readingProgressSection: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
            AppleBooksSectionHeader(
                title: "Reading Progress",
                subtitle: nil,
                showSeeAll: false,
                seeAllAction: {}
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
        .frame(maxWidth: sectionMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, adaptivePadding)
    }

    private var actionButtonsSection: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
            AppleBooksSectionHeader(
                title: "Actions",
                subtitle: nil,
                showSeeAll: false,
                seeAllAction: {}
            )

            AppleBooksCard {
                HStack(spacing: AppleBooksSpacing.space12) {
                    if currentBook.status == .library {
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.moveBook(currentBook, to: .reading)
                            }
                        }) {
                            Text("Start Reading")
                                .font(AppleBooksTypography.buttonLarge)
                                .foregroundColor(.white)
                                .frame(maxWidth: isIPad ? 300 : .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(AppleBooksColors.accent)
                                .cornerRadius(12)
                        }
                    } else if currentBook.status == .reading || currentBook.status == .currentlyReading {
                        Button(action: {
                            showProgressView = true
                        }) {
                            Text("Update Progress")
                                .font(AppleBooksTypography.buttonLarge)
                                .foregroundColor(.white)
                                .frame(maxWidth: isIPad ? 300 : .infinity)
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
                            .frame(maxWidth: isIPad ? 300 : .infinity)
                            .padding(.vertical, AppleBooksSpacing.space16)
                            .background(AppleBooksColors.card.opacity(0.5))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .frame(maxWidth: sectionMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, adaptivePadding)
    }

    private var recommendationsSection: AnyView {
        if !recommendations.isEmpty {
            AnyView(VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
                AppleBooksSectionHeader(
                    title: "You Might Also Like",
                    subtitle: nil,
                    showSeeAll: false,
                    seeAllAction: {}
                )
                .padding(.horizontal, adaptivePadding)

                if isIPad {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(recommendations.prefix(6)) { recommendation in
                            AppleBooksBookCard(
                                book: Book(
                                    title: recommendation.title,
                                    author: recommendation.author,
                                    genre: nil as String?,
                                    status: .library,
                                    coverImageURL: recommendation.thumbnailURL
                                ),
                                onTap: {},
                                showAddButton: false,
                                onAddTap: {},
                                onEditTap: nil,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(.horizontal, adaptivePadding)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppleBooksSpacing.space16) {
                            ForEach(recommendations.prefix(5)) { recommendation in
                                AppleBooksBookCard(
                                    book: Book(
                                        title: recommendation.title,
                                        author: recommendation.author,
                                        genre: nil as String?,
                                        status: .library,
                                        coverImageURL: recommendation.thumbnailURL
                                    ),
                                    onTap: {},
                                    showAddButton: false,
                                    onAddTap: {},
                                    onEditTap: nil,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)
                    }
                }
            })
        } else {
            AnyView(EmptyView())
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppleBooksSpacing.space32) {
                if isIPad {
                    HStack(alignment: .top, spacing: AppleBooksSpacing.space32) {
                        VStack(spacing: AppleBooksSpacing.space20) {
                            bookCoverSection
                        }
                        .frame(maxWidth: 300)
                        
                        VStack(alignment: .leading, spacing: AppleBooksSpacing.space24) {
                            bookMetadataSection
                            bookDetailsSection
                            readingProgressSection
                            actionButtonsSection
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: maxContentWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, adaptivePadding)
                    
                    bookTeaserSection
                    authorBiographySection
                    recommendationsSection
                } else {
                    bookCoverSection
                    bookMetadataSection
                    bookDetailsSection
                    bookTeaserSection
                    authorBiographySection
                    readingProgressSection
                    actionButtonsSection
                    recommendationsSection
                }
                Spacer(minLength: AppleBooksSpacing.space64)
            }
            .background(AppleBooksColors.background)
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Book") {
                            showEditView = true
                        }
                        if currentBook.status == .library {
                            Button("Start Reading") {
                                withAnimation(.spring()) {
                                    viewModel.moveBook(currentBook, to: .reading)
                                }
                            }
                        } else if currentBook.status == .reading || currentBook.status == .currentlyReading {
                            Button("Update Progress") {
                                showProgressView = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showProgressView) {
                ReadingProgressView(book: currentBook, viewModel: viewModel)
            }
            .sheet(isPresented: $showEditView) {
                EditBookView(book: currentBook, viewModel: viewModel)
            }
        }
        .onAppear {
            loadBookDetails()
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
                    print("DEBUG BookDetailView: Book details loaded successfully, initiating teaser and bio fetches")
                    // Always fetch fresh AI-generated book teaser
                    if let title = self.currentBook.title, let author = self.currentBook.author {
                        self.loadBookTeaser(title: title, author: author)
                    }
                    // Always fetch fresh AI-generated author bio
                    if let author = self.currentBook.author {
                        self.loadAuthorBiography(author: author)
                    }
                case .failure(let error):
                    print("Failed to load book details: \(error.localizedDescription)")
                    // Always try to load fresh AI-generated teaser and bio even if details failed
                    if let title = self.currentBook.title, let author = self.currentBook.author {
                        self.loadBookTeaser(title: title, author: author)
                    }
                    if let author = self.currentBook.author {
                        self.loadAuthorBiography(author: author)
                    }
                }
            }
        }
    }

    private func loadAuthorBiography(author: String) {
        guard !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("DEBUG BookDetailView: Skipping author bio load - empty author")
            isLoadingBio = false
            return
        }
        isLoadingBio = true
        guard rateLimiter.canMakeCall() else {
            print("DEBUG BookDetailView: Rate limit exceeded for author bio fetch - cannot make API call")
            isLoadingBio = false
            return
        }
        print("DEBUG BookDetailView: Initiating author bio fetch for author: \(author)")
        let grokService = GrokAPIService()
        grokService.fetchAuthorBiography(author: author) { result in
            DispatchQueue.main.async {
                self.isLoadingBio = false
                switch result {
                case .success(let bio):
                    print("DEBUG BookDetailView: Successfully loaded author bio for \(author)")
                    self.viewModel.updateBookAuthorBio(self.currentBook, authorBio: bio)
                case .failure(let error):
                    print("DEBUG BookDetailView: Failed to load author biography for \(author): \(error.localizedDescription)")
                }
                self.rateLimiter.recordCall()
            }
        }
    }

    private func loadBookTeaser(title: String, author: String) {
        isLoadingTeaser = true
        guard rateLimiter.canMakeCall() else {
            print("DEBUG BookDetailView: Rate limit exceeded for book teaser fetch - cannot make API call")
            isLoadingTeaser = false
            return
        }
        print("DEBUG BookDetailView: Initiating book teaser fetch for title: \(title), author: \(author)")
        let grokService = GrokAPIService()
        grokService.fetchBookSummary(title: title, author: author) { result in
            DispatchQueue.main.async {
                self.isLoadingTeaser = false
                switch result {
                case .success(let teaser):
                    print("DEBUG BookDetailView: Successfully loaded book teaser for \(title)")
                    self.viewModel.updateBookTeaser(self.currentBook, teaser: teaser)
                case .failure(let error):
                    print("DEBUG BookDetailView: Failed to load book teaser for \(title): \(error.localizedDescription)")
                }
                self.rateLimiter.recordCall()
            }
        }
    }

    private func loadRecommendations() {
        print("DEBUG BookDetailView: loadRecommendations called, recommendations count: \(recommendations.count), isLoading: \(isLoadingRecommendations)")
        guard !isLoadingRecommendations && recommendations.isEmpty else { return }
        isLoadingRecommendations = true
        viewModel.generateRecommendations(for: currentBook) { result in
            DispatchQueue.main.async {
                isLoadingRecommendations = false
                switch result {
                case .success(let recs):
                    // Filter out the current book
                    self.recommendations = recs.filter { $0.title != (currentBook.title ?? "") || $0.author != (currentBook.author ?? "") }
                    print("DEBUG BookDetailView: Loaded \(self.recommendations.count) recommendations")
                case .failure(let error):
                    print("Failed to load recommendations: \(error.localizedDescription)")
                }
            }
        }
    }
}
