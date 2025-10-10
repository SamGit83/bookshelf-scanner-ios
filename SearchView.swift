import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
struct SearchView: View {
    @ObservedObject var viewModel: BookViewModel
    @State private var searchText = ""
    @State private var searchResults: [Book] = []
    @State private var googleBooksResults: [BookRecommendation] = []
    @State private var isSearching = false
    @State private var isSearchingGoogleBooks = false
    @State private var selectedFilter: SearchFilter = .all
    @Environment(\.presentationMode) var presentationMode

    private let googleBooksService = GoogleBooksAPIService()

    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case title = "Title"
        case author = "Author"
        case genre = "Genre"
        case isbn = "ISBN"
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppleBooksColors.background
                    .ignoresSafeArea()

                VStack(spacing: AppleBooksSpacing.space24) {
                    // Search Header
                    VStack(spacing: AppleBooksSpacing.space20) {
                        // Compact Search Bar
                        GlassCard {
                            HStack(spacing: AppleBooksSpacing.space8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                    .font(.system(size: 16))

                                TextField("Search books...", text: $searchText)
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.text)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .frame(height: 18)
                                    .onChange(of: searchText) { newValue in
                                        performSearch(query: newValue)
                                    }

                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .padding(.vertical, AppleBooksSpacing.space6)
                            .padding(.horizontal, AppleBooksSpacing.space8)
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)
                        .padding(.top, AppleBooksSpacing.space16)
                        .frame(height: 36)

                        // Cancel Button
                        HStack {
                            Spacer()
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Cancel")
                                    .font(AppleBooksTypography.buttonMedium)
                                    .foregroundColor(AppleBooksColors.accent)
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        // Category Filters
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(SearchFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue)
                                    .font(AppleBooksTypography.captionBold)
                                    .tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(AppleBooksColors.card.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal, AppleBooksSpacing.space24)
                        .onChange(of: selectedFilter) { _ in
                            if !searchText.isEmpty {
                                performSearch(query: searchText)
                            } else {
                                resetSearch()
                            }
                        }
                    }

                    // Search Results
                    if searchText.isEmpty {
                        // Empty State
                        VStack(spacing: AppleBooksSpacing.space32) {
                            ZStack {
                                Circle()
                                    .fill(AppleBooksColors.accent.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)

                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppleBooksColors.accent)
                            }

                            Text("Search Books")
                                .font(AppleBooksTypography.displayMedium)
                                .foregroundColor(AppleBooksColors.text)

                            Text("Find books in your library or discover new ones online")
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppleBooksSpacing.space32)
                        }
                        .padding(.top, AppleBooksSpacing.space80)
                    } else if isSearching || (searchResults.isEmpty && isSearchingGoogleBooks) {
                        // Loading State
                        VStack(spacing: AppleBooksSpacing.space24) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(AppleBooksColors.accent)
                            Text(searchResults.isEmpty ? "Searching online..." : "Searching...")
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.textSecondary)
                        }
                        .padding(.top, AppleBooksSpacing.space80)
                    } else if searchResults.isEmpty && googleBooksResults.isEmpty {
                        // No Results
                        VStack(spacing: AppleBooksSpacing.space32) {
                            ZStack {
                                Circle()
                                    .fill(AppleBooksColors.textTertiary.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)

                                Image(systemName: "book.closed")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppleBooksColors.textTertiary)
                            }

                            Text("No books found")
                                .font(AppleBooksTypography.displayMedium)
                                .foregroundColor(AppleBooksColors.text)

                            Text("Try different keywords or check spelling")
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppleBooksSpacing.space32)
                        }
                        .padding(.top, AppleBooksSpacing.space80)
                    } else {
                        // Results List
                        ScrollView {
                            LazyVStack(spacing: AppleBooksSpacing.space16) {
                                // Local Library Results
                                if !searchResults.isEmpty {
                                    Section(header:
                                        Text("From Your Library")
                                            .font(AppleBooksTypography.headlineSmall)
                                            .foregroundColor(AppleBooksColors.text)
                                            .padding(.horizontal, AppleBooksSpacing.space24)
                                            .padding(.vertical, AppleBooksSpacing.space8)
                                    ) {
                                        ForEach(searchResults) { book in
                                            AppleBooksSearchResultRow(book: book, viewModel: viewModel)
                                        }
                                    }
                                }

                                // Google Books Results
                                if !googleBooksResults.isEmpty {
                                    Section(header:
                                        Text("From Google Books")
                                            .font(AppleBooksTypography.headlineSmall)
                                            .foregroundColor(AppleBooksColors.text)
                                            .padding(.horizontal, AppleBooksSpacing.space24)
                                            .padding(.vertical, AppleBooksSpacing.space8)
                                    ) {
                                        ForEach(googleBooksResults) { recommendation in
                                            GoogleBooksSearchResultRow(recommendation: recommendation, viewModel: viewModel)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, AppleBooksSpacing.space16)
                            .padding(.horizontal, AppleBooksSpacing.space24)
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            googleBooksResults = []
            isSearching = false
            isSearchingGoogleBooks = false
            return
        }

        isSearching = true
        googleBooksResults = []

        // Perform search on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let results = self.filterBooks(query: query.lowercased(), filter: self.selectedFilter)

            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false

                // If no local results, search Google Books
                if results.isEmpty {
                    self.searchGoogleBooks(query: query)
                }
            }
        }
    }

    private func searchGoogleBooks(query: String) {
        isSearchingGoogleBooks = true

        googleBooksService.searchBooks(query: query, maxResults: 10) { result in
            DispatchQueue.main.async {
                self.isSearchingGoogleBooks = false
                switch result {
                case .success(let recommendations):
                    self.googleBooksResults = recommendations
                case .failure(let error):
                    print("Google Books search failed: \(error.localizedDescription)")
                    self.googleBooksResults = []
                }
            }
        }
    }

    private func filterBooks(query: String, filter: SearchFilter) -> [Book] {
        return viewModel.books.filter { book in
            switch filter {
            case .all:
                return (book.title ?? "").lowercased().contains(query) ||
                        (book.author ?? "").lowercased().contains(query) ||
                        (book.genre?.lowercased().contains(query) ?? false) ||
                        (book.isbn?.lowercased().contains(query) ?? false)
            case .title:
                return (book.title ?? "").lowercased().contains(query)
            case .author:
                return (book.author ?? "").lowercased().contains(query)
            case .genre:
                return book.genre?.lowercased().contains(query) ?? false
            case .isbn:
                return book.isbn?.lowercased().contains(query) ?? false
            }
        }
    }

    private func resetSearch() {
        searchResults = []
        googleBooksResults = []
        isSearching = false
        isSearchingGoogleBooks = false
    }
}

struct AppleBooksSearchResultRow: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @State private var showActionSheet = false

    var body: some View {
        AppleBooksCard(
            cornerRadius: 12,
            padding: AppleBooksSpacing.space16,
            shadowStyle: .subtle
        ) {
            HStack(spacing: AppleBooksSpacing.space12) {
                // Book Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppleBooksColors.card.opacity(0.5))
                        .frame(width: 60, height: 90)

                    if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 86)
                            .cornerRadius(6)
                    } else {
                        Image(systemName: "book.fill")
                            .resizable()
                            .frame(width: 28, height: 35)
                            .foregroundColor(AppleBooksColors.textTertiary)
                    }
                }

                // Book Details
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text(book.title ?? "Unknown Title")
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .lineLimit(2)

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

                    // Status indicator
                    Text(book.status.rawValue)
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppleBooksSpacing.space8)
                        .padding(.vertical, AppleBooksSpacing.space2)
                        .background(
                            (book.status == .reading || book.status == .currentlyReading) ?
                                AppleBooksColors.success.opacity(0.9) :
                                AppleBooksColors.textTertiary.opacity(0.8)
                        )
                        .cornerRadius(4)
                }

                Spacer()

                // Action Button
                Button(action: {
                    showActionSheet = true
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppleBooksColors.textSecondary)
                }
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text(book.title ?? "Unknown Title"),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Move to Currently Reading")) {
                        withAnimation(.spring()) {
                            viewModel.moveBook(book, to: .reading)
                        }
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
    }
}

struct GoogleBooksSearchResultRow: View {
    let recommendation: BookRecommendation
    @ObservedObject var viewModel: BookViewModel
    @State private var isAddingToLibrary = false
    @State private var isAdded = false

    var body: some View {
        AppleBooksCard(
            cornerRadius: 12,
            padding: AppleBooksSpacing.space16,
            shadowStyle: .subtle
        ) {
            HStack(spacing: AppleBooksSpacing.space12) {
                // Book Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppleBooksColors.card.opacity(0.5))
                        .frame(width: 60, height: 90)

                    if let thumbnailURL = recommendation.thumbnailURL,
                       let url = URL(string: thumbnailURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .scaleEffect(0.5)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 86)
                                    .cornerRadius(6)
                            case .failure:
                                Image(systemName: "book.fill")
                                    .resizable()
                                    .frame(width: 28, height: 35)
                                    .foregroundColor(AppleBooksColors.textTertiary)
                            @unknown default:
                                Image(systemName: "book.fill")
                                    .resizable()
                                    .frame(width: 28, height: 35)
                                    .foregroundColor(AppleBooksColors.textTertiary)
                            }
                        }
                    } else {
                        Image(systemName: "book.fill")
                            .resizable()
                            .frame(width: 28, height: 35)
                            .foregroundColor(AppleBooksColors.textTertiary)
                    }
                }

                // Book Details
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text(recommendation.title)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .lineLimit(2)

                    Text(recommendation.author)
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    Text(recommendation.genre)
                        .font(AppleBooksTypography.captionBold)
                        .foregroundColor(AppleBooksColors.accent)
                        .padding(.horizontal, AppleBooksSpacing.space8)
                        .padding(.vertical, AppleBooksSpacing.space2)
                        .background(AppleBooksColors.accent.opacity(0.1))
                        .cornerRadius(4)

                    if let pageCount = recommendation.pageCount {
                        Text("\(pageCount) pages")
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(AppleBooksColors.success)
                            .padding(.horizontal, AppleBooksSpacing.space8)
                            .padding(.vertical, AppleBooksSpacing.space2)
                            .background(AppleBooksColors.success.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // Add to Library Button
                Button(action: addToLibrary) {
                    if isAdded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    } else if isAddingToLibrary {
                        ProgressView()
                            .frame(width: AppleBooksSpacing.space20, height: AppleBooksSpacing.space20)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppleBooksColors.accent)
                    }
                }
                .disabled(isAddingToLibrary || isAdded)
            }
        }
    }

    private func addToLibrary() {
        isAddingToLibrary = true

        // Add to library using the proper method that fetches complete metadata
        viewModel.addBookFromRecommendation(recommendation) { result in
            DispatchQueue.main.async {
                self.isAddingToLibrary = false
                switch result {
                case .success:
                    // Book added successfully
                    self.isAdded = true
                case .failure(let error):
                    print("Failed to add book from search: \(error.localizedDescription)")
                    // Could show an error message here if needed
                }
            }
        }
    }
}
