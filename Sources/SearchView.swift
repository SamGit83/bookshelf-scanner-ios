import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Search Header
                    VStack(spacing: 16) {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))

                                TextField("Search your library...", text: $searchText)
                                    .foregroundColor(.primary)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)

                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onChange(of: searchText) { newValue in
                                performSearch(query: newValue)
                            }

                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Cancel")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .padding(.horizontal, 16)

                        // Filter Picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(SearchFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 16)
                        .onChange(of: selectedFilter) { _ in
                            if !searchText.isEmpty {
                                performSearch(query: searchText)
                            }
                        }
                    }

                    // Search Results
                    if searchText.isEmpty {
                        // Empty State
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)

                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }

                            Text("Search Your Library")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Find books by title, author, genre, or ISBN")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 64)
                    } else if isSearching {
                        // Loading State
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Searching...")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 64)
                    } else if searchResults.isEmpty {
                        // No Results
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)

                                Image(systemName: "book.closed")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }

                            Text("No books found")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Try different keywords or check spelling")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 64)
                    } else {
                        // Results List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(searchResults) { book in
                                    SearchResultRow(book: book, viewModel: viewModel)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 16)
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
        HStack(spacing: 16) {
            // Book Cover
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 50, height: 70)

                if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 46, height: 66)
                        .cornerRadius(6)
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .frame(width: 24, height: 30)
                        .foregroundColor(.gray)
                }
            }

            // Book Details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let genre = book.genre {
                    Text(genre)
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                // Status indicator
                Text(book.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        book.status == .currentlyReading ?
                            Color.blue.opacity(0.8) :
                            Color.gray.opacity(0.8)
                    )
                    .cornerRadius(4)
            }

            Spacer()

            // Action Button
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text(book.title),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Move to Currently Reading")) {
                        withAnimation(.spring()) {
                            viewModel.moveBook(book, to: .currentlyReading)
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
