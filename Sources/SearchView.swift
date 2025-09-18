import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: BookViewModel
    @State private var searchText = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var selectedFilter: SearchFilter = .all
    @Environment(\.presentationMode) var presentationMode

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
                LiquidGlass.primary.opacity(0.05)
                    .ignoresSafeArea()

                VStack(spacing: LiquidGlass.Spacing.space16) {
                    // Search Header
                    VStack(spacing: LiquidGlass.Spacing.space16) {
                        HStack {
                            LiquidGlassSearchBar(text: $searchText, placeholder: "Search your library...")
                                .onChange(of: searchText) { newValue in
                                    performSearch(query: newValue)
                                }

                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Cancel")
                                    .foregroundColor(LiquidGlass.accent)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space16)

                        // Filter Picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(SearchFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, LiquidGlass.Spacing.space16)
                        .onChange(of: selectedFilter) { _ in
                            if !searchText.isEmpty {
                                performSearch(query: searchText)
                            }
                        }
                    }

                    // Search Results
                    if searchText.isEmpty {
                        // Empty State
                        VStack(spacing: LiquidGlass.Spacing.space20) {
                            ZStack {
                                Circle()
                                    .fill(LiquidGlass.secondary.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)

                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Text("Search Your Library")
                                .font(LiquidGlass.Typography.headlineLarge)
                                .foregroundColor(.white)

                            Text("Find books by title, author, genre, or ISBN")
                                .font(LiquidGlass.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, LiquidGlass.Spacing.space32)
                        }
                        .padding(.top, LiquidGlass.Spacing.space64)
                    } else if isSearching {
                        // Loading State
                        VStack(spacing: LiquidGlass.Spacing.space20) {
                            LiquidSpinner()
                            Text("Searching...")
                                .font(LiquidGlass.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, LiquidGlass.Spacing.space64)
                    } else if searchResults.isEmpty {
                        // No Results
                        VStack(spacing: LiquidGlass.Spacing.space20) {
                            ZStack {
                                Circle()
                                    .fill(LiquidGlass.secondary.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)

                                Image(systemName: "book.closed")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Text("No books found")
                                .font(LiquidGlass.Typography.headlineLarge)
                                .foregroundColor(.white)

                            Text("Try different keywords or check spelling")
                                .font(LiquidGlass.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, LiquidGlass.Spacing.space32)
                        }
                        .padding(.top, LiquidGlass.Spacing.space64)
                    } else {
                        // Results List
                        ScrollView {
                            LazyVStack(spacing: LiquidGlass.Spacing.space16) {
                                ForEach(searchResults) { book in
                                    SearchResultRow(book: book, viewModel: viewModel)
                                        .padding(.horizontal, LiquidGlass.Spacing.space16)
                                }
                            }
                            .padding(.vertical, LiquidGlass.Spacing.space16)
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
            isSearching = false
            return
        }

        isSearching = true

        // Perform search on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let results = self.filterBooks(query: query.lowercased(), filter: self.selectedFilter)

            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }

    private func filterBooks(query: String, filter: SearchFilter) -> [Book] {
        return viewModel.books.filter { book in
            switch filter {
            case .all:
                return book.title.lowercased().contains(query) ||
                       book.author.lowercased().contains(query) ||
                       (book.genre?.lowercased().contains(query) ?? false) ||
                       (book.isbn?.lowercased().contains(query) ?? false)
            case .title:
                return book.title.lowercased().contains(query)
            case .author:
                return book.author.lowercased().contains(query)
            case .genre:
                return book.genre?.lowercased().contains(query) ?? false
            case .isbn:
                return book.isbn?.lowercased().contains(query) ?? false
            }
        }
    }
}

struct SearchResultRow: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @State private var showActionSheet = false

    var body: some View {
        LiquidGlassCard {
            HStack(spacing: LiquidGlass.Spacing.space16) {
                // Book Cover
                ZStack {
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                        .fill(LiquidGlass.glassBackground)
                        .frame(width: 50, height: 70)

                    if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 46, height: 66)
                            .cornerRadius(LiquidGlass.CornerRadius.small)
                    } else {
                        Image(systemName: "book.fill")
                            .resizable()
                            .frame(width: 24, height: 30)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Book Details
                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space4) {
                    Text(book.title)
                        .font(LiquidGlass.Typography.headlineSmall)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(book.author)
                        .font(LiquidGlass.Typography.bodySmall)
                        .foregroundColor(.white.opacity(0.8))

                    if let genre = book.genre {
                        Text(genre)
                            .font(LiquidGlass.Typography.captionSmall)
                            .foregroundColor(LiquidGlass.accent)
                    }

                    // Status indicator
                    Text(book.status.rawValue)
                        .font(LiquidGlass.Typography.captionSmall)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, LiquidGlass.Spacing.space8)
                        .padding(.vertical, LiquidGlass.Spacing.space2)
                        .background(
                            book.status == .currentlyReading ?
                                LiquidGlass.accent.opacity(0.2) :
                                LiquidGlass.secondary.opacity(0.2)
                        )
                        .cornerRadius(LiquidGlass.CornerRadius.small)
                }

                Spacer()

                // Action Button
                Button(action: {
                    showActionSheet = true
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .liquidInteraction()
                }
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text(book.title),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Move to Currently Reading")) {
                        withAnimation(LiquidGlass.Animation.spring) {
                            viewModel.moveBook(book, to: .currentlyReading)
                        }
                    },
                    .default(Text("Move to Library")) {
                        withAnimation(LiquidGlass.Animation.spring) {
                            viewModel.moveBook(book, to: .library)
                        }
                    },
                    .destructive(Text("Delete Book")) {
                        withAnimation(LiquidGlass.Animation.spring) {
                            viewModel.deleteBook(book)
                        }
                    },
                    .cancel()
                ]
            )
        }
        .liquidInteraction()
    }
}

// Custom Search Bar Component
struct LiquidGlassSearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 16))

            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .font(LiquidGlass.Typography.bodyMedium)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(LiquidGlass.Spacing.space12)
        .background(
            RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                .fill(LiquidGlass.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}