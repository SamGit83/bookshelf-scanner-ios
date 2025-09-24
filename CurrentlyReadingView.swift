import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Currently Reading Book Card with Progress
struct CurrentlyReadingBookCard: View {
    let book: Book
    let onTap: () -> Void
    let onProgressTap: (Book) -> Void

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
                            .foregroundColor(AppleBooksColors.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(book.author ?? "Unknown Author")
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(AppleBooksColors.textSecondary)

                        if let genre = book.genre {
                            Text(genre)
                                .font(AppleBooksTypography.captionBold)
                                .foregroundColor(AppleBooksColors.accent)
                                .padding(.horizontal, AppleBooksSpacing.space8)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(AppleBooksColors.accent.opacity(0.1))
                                .cornerRadius(4)
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
        .onTapGesture(perform: onTap)
    }
}

struct CurrentlyReadingView: View {
    @ObservedObject var viewModel: BookViewModel
    @Binding var isShowingCamera: Bool
    @State private var selectedBook: Book?
    @State private var progressBook: Book?

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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppleBooksSpacing.space16) {
                    ForEach(viewModel.currentlyReadingBooks) { book in
                        CurrentlyReadingBookCard(book: book, onProgressTap: { progressBook in
                            self.progressBook = progressBook
                        }) {
                            selectedBook = book
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppleBooksSpacing.space16) {
                    ForEach(favoriteBooks) { book in
                        BookCard(book: book, viewModel: viewModel, onProgressTap: { progressBook in
                            self.progressBook = progressBook
                        }) {
                            selectedBook = book
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppleBooksSpacing.space16) {
                    ForEach(trendingBooks) { book in
                        BookCard(book: book, viewModel: viewModel, onProgressTap: { progressBook in
                            self.progressBook = progressBook
                        }) {
                            selectedBook = book
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
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
            .padding(.horizontal, AppleBooksSpacing.space32)
            .padding(.vertical, AppleBooksSpacing.space64)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    readingGoalsSection
                    currentlyReadingSection
                    promoBannerSection
                    favoritesSection
                    trendingSection
                    emptyStateSection
                }
            }
            .background(AppleBooksColors.background)
            .navigationBarHidden(true)
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
                BookDetailView(book: book, viewModel: viewModel)
            }
            .sheet(item: $progressBook) { book in
                ReadingProgressView(book: book, viewModel: viewModel)
            }
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