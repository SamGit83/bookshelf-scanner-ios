import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Currently Reading Book Card with Progress
struct CurrentlyReadingBookCard: View {
    let book: Book
    let onTap: () -> Void
    let onProgressTap: (Book) -> Void

    @State private var showPageNumber = false
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private var progress: Double {
        guard let totalPages = book.totalPages, totalPages > 0 else { return 0 }
        return Double(book.currentPage) / Double(totalPages)
    }

    private var progressText: String {
        guard let totalPages = book.totalPages else { return "" }
        return "\(book.currentPage)/\(totalPages) pages"
    }

    var body: some View {
        AppleBooksCard(
            cornerRadius: 12,
            padding: AppleBooksSpacing.space12,
            shadowStyle: .subtle
        ) {
            VStack(spacing: AppleBooksSpacing.space8) {
                HStack(spacing: AppleBooksSpacing.space12) {
                    // Book Cover
                    if let coverData = book.coverImageData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .overlay(
                                Text("No Cover")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            )
                    }

                    // Book Details
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                        Text(book.title ?? "Unknown Title")
                            .font(AppleBooksTypography.bodyLarge)
                            .bold()
                            .foregroundColor(AppleBooksColors.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(book.author ?? "Unknown Author")
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(AppleBooksColors.text)

                        // Row 1: Page count, reading time, and age rating badges
                        HStack(spacing: AppleBooksSpacing.space6) {
                            // Page count badge
                            let pageText = book.pageCount != nil ? "\(book.pageCount!) pages" : "Page count unavailable"
                            Text(pageText)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.promotional)
                                .padding(.horizontal, AppleBooksSpacing.space6)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(AppleBooksColors.promotional.opacity(0.1))
                                .cornerRadius(4)

                            // Reading time badge
                            let readingText = book.estimatedReadingTime != nil ? book.estimatedReadingTime! : "Reading time unavailable"
                            Text(readingText)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.success)
                                .padding(.horizontal, AppleBooksSpacing.space6)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(AppleBooksColors.success.opacity(0.1))
                                .cornerRadius(4)

                            // Age rating badge
                            if let ageRating = book.ageRating {
                                let isChildren = ageRating.lowercased().contains("children") || ageRating.lowercased().contains("general")
                                let isTeen = ageRating.lowercased().contains("teen")
                                let isAdult = ageRating.lowercased().contains("adult") || ageRating.lowercased().contains("mature")
                                let (bgColor, fgColor): (Color, Color) = {
                                    if isChildren {
                                        return (AppleBooksColors.success.opacity(0.1), AppleBooksColors.success)
                                    } else if isTeen {
                                        return (AppleBooksColors.accent.opacity(0.1), AppleBooksColors.accent)
                                    } else if isAdult {
                                        return (Color(hex: "FF9500").opacity(0.1), Color(hex: "FF9500"))
                                    } else {
                                        return (AppleBooksColors.card.opacity(0.8), AppleBooksColors.text)
                                    }
                                }()
                                Text(ageRating)
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(fgColor)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(bgColor)
                                    .cornerRadius(4)
                            } else {
                                Text("Unrated")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.text)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(AppleBooksColors.card.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }

                        // Row 2: Sub-genre badge
                        HStack(spacing: AppleBooksSpacing.space6) {
                            // Sub-genre badge
                            let subGenreText = book.subGenre != nil ? book.subGenre! : "Sub-genre unavailable"
                            Text(subGenreText)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(Color(hex: "B19CD9"))
                                .padding(.horizontal, AppleBooksSpacing.space6)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(Color(hex: "B19CD9").opacity(0.1))
                                .cornerRadius(4)

                            Spacer()
                        }
                    }

                    Spacer()
                }

                // Progress Bar
                if book.totalPages != nil && book.totalPages! > 0 {
                    VStack(spacing: AppleBooksSpacing.space4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                    .cornerRadius(2)

                                Rectangle()
                                    .fill(AppleBooksColors.success)
                                    .frame(width: geometry.size.width * progress, height: 4)
                                    .cornerRadius(2)
                            }
                        }
                        .frame(height: 4)

                        HStack {
                            Text(progressText)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.textSecondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(AppleBooksTypography.captionBold)
                                .foregroundColor(AppleBooksColors.success)
                        }
                    }
                }
            }
        }
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    if book.currentPage > 0 {
                        ZStack {
                            if showPageNumber {
                                Text("\(book.currentPage)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(AppleBooksColors.accent.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            } else {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(AppleBooksColors.accent.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(8)
                    }
                    Button(action: {
                        onProgressTap(book)
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(AppleBooksColors.accent.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
                Spacer()
            }
        )
        .onReceive(timer) { _ in
            showPageNumber.toggle()
        }
        .onTapGesture(perform: onTap)
    }
}

struct CurrentlyReadingView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: BookViewModel
    @Binding var isShowingCamera: Bool
    @State private var selectedBook: Book?
    @State private var progressBook: Book?
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    private var cardWidth: CGFloat {
        isIPad ? 350 : 280
    }
    
    private var adaptivePadding: CGFloat {
        isIPad ? 48 : 24
    }
    
    private var adaptiveSpacing: CGFloat {
        isIPad ? 24 : 16
    }
    
    private var gridColumns: [GridItem] {
        let count = isIPad ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: adaptiveSpacing), count: count)
    }

    // Dummy data for favorites and trending
    private var favoriteBooks: [Book] {
        // Filter some books from library or create dummies
        let libraryBooks = viewModel.books.filter { $0.status == .library }
        return Array(libraryBooks.prefix(5))
    }

    private var trendingBooks: [Book] {
        // For demo, use library books
        let libraryBooks = viewModel.books.filter { $0.status == .library }
        return Array(libraryBooks.suffix(5))
    }

    private var readingGoalsSection: some View {
        ReadingGoalsSection()
    }

    @ViewBuilder
    private var currentlyReadingSection: some View {
        if !viewModel.currentlyReadingBooks.isEmpty {
            AppleBooksSectionHeader(
                title: "Continue Reading",
                subtitle: "Pick up where you left off",
                showSeeAll: false,
                seeAllAction: nil
            )
            .padding(.horizontal, adaptivePadding)

            if isIPad {
                LazyVGrid(columns: gridColumns, spacing: adaptiveSpacing) {
                    ForEach(viewModel.currentlyReadingBooks) { book in
                        CurrentlyReadingBookCard(book: book, onTap: {
                            selectedBook = book
                        }, onProgressTap: { progressBook in
                            self.progressBook = progressBook
                        })
                        .frame(maxWidth: 500)
                    }
                }
                .padding(.horizontal, adaptivePadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppleBooksSpacing.space16) {
                        ForEach(viewModel.currentlyReadingBooks) { book in
                            CurrentlyReadingBookCard(book: book, onTap: {
                                selectedBook = book
                            }, onProgressTap: { progressBook in
                                self.progressBook = progressBook
                            })
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }
            }
        }
    }

    private var promoBannerSection: some View {
        AppleBooksPromoBanner(
            title: "$9.99 Audiobooks",
            subtitle: "Limited time offer",
            gradient: LinearGradient(
                colors: [AppleBooksColors.promotional, AppleBooksColors.promotional.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        ) {
            // Handle promo tap - could open store
        }
        .frame(maxWidth: isIPad ? 800 : .infinity)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, adaptivePadding)
    }

    @ViewBuilder
    private var favoritesSection: some View {
        if !favoriteBooks.isEmpty {
            AppleBooksSectionHeader(
                title: "Customer Favorites",
                subtitle: "See the books readers love",
                showSeeAll: true,
                seeAllAction: {
                    // Handle see all
                }
            )
            .padding(.horizontal, adaptivePadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: adaptiveSpacing) {
                    ForEach(favoriteBooks) { book in
                        BookCard(book: book, viewModel: viewModel, onProgressTap: { progressBook in
                            self.progressBook = progressBook
                        })
                        .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, adaptivePadding)
            }
        }
    }

    @ViewBuilder
    private var trendingSection: some View {
        if !trendingBooks.isEmpty {
            AppleBooksSectionHeader(
                title: "New & Trending",
                subtitle: "Explore what's hot in audiobooks",
                showSeeAll: true,
                seeAllAction: {
                    // Handle see all
                }
            )
            .padding(.horizontal, adaptivePadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: adaptiveSpacing) {
                    ForEach(trendingBooks) { book in
                        BookCard(book: book, viewModel: viewModel, onProgressTap: { progressBook in
                            self.progressBook = progressBook
                        })
                        .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, adaptivePadding)
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if viewModel.currentlyReadingBooks.isEmpty {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppleBooksColors.accent.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 10)

                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                }

                Text("No books currently reading")
                    .font(AppleBooksTypography.displayMedium)
                    .foregroundColor(AppleBooksColors.text)

                Text("Move books from library or scan new ones!")
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, adaptivePadding)
            .padding(.vertical, AppleBooksSpacing.space64)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppleBooksSpacing.space32) {
                readingGoalsSection
                    .padding(.horizontal, adaptivePadding)
                currentlyReadingSection
                promoBannerSection
                favoritesSection
                trendingSection
                emptyStateSection
            }
            .padding(.vertical, AppleBooksSpacing.space24)
        }
        .background(AppleBooksColors.background)
        .overlay(
            Group {
                if viewModel.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Analyzing image...")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.horizontal, 32)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .sheet(item: $selectedBook) { book in
            NavigationView { // Add NavigationView here
                BookDetailView(book: book, viewModel: viewModel)
            }
        }
        .sheet(item: $progressBook) { book in
            ReadingProgressView(book: book, viewModel: viewModel)
        }
    }
}

// MARK: - Book Card (Shared Component)

struct BookCard: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    let onProgressTap: (Book) -> Void
    @State private var showActionSheet = false
    @State private var showEditView = false

    var body: some View {
        ZStack {
            NavigationLink(destination: BookDetailView(book: book, viewModel: viewModel)) {
                HStack(spacing: 16) {
                    // Book Cover
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .frame(width: 60, height: 90)

                        if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 86)
                                        .cornerRadius(6)
                                case .failure:
                                    Image(systemName: "book.fill")
                                        .resizable()
                                        .frame(width: 32, height: 40)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    Image(systemName: "book.fill")
                                        .resizable()
                                        .frame(width: 32, height: 40)
                                        .foregroundColor(.gray)
                                }
                            }
                        } else if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 86)
                                .cornerRadius(6)
                        } else {
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 32, height: 40)
                                .foregroundColor(.gray)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                    // Book Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title ?? "Unknown Title")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Text(book.author ?? "Unknown Author")
                            .font(.body)
                            .foregroundColor(.secondary)

                        if let genre = book.genre {
                            Text(genre)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }

                        // Reading status indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill((book.status == .reading || book.status == .currentlyReading) ? Color.blue : Color.gray)
                                .frame(width: 8, height: 8)

                            Text(book.status.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .buttonStyle(PlainButtonStyle())

            // Action Menu Button (overlay)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showActionSheet = true
                    }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color(.systemBackground).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                Spacer()
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text(book.title ?? "Unknown Title"),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Update Progress")) {
                        onProgressTap(book)
                    },
                    .default(Text("Edit Book")) {
                        showEditView = true
                    },
                    .default(Text("Move to Library")) {
                        withAnimation(.spring()) {
                            viewModel.moveBook(book, to: .library)
                        }
                    },
                    .destructive(Text("Delete Book")) {
                        withAnimation(.spring()) {
                            viewModel.deleteBook(book)
                        }
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showEditView) {
            EditBookView(book: book, viewModel: viewModel)
        }
    }
}