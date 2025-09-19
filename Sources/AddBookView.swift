import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AddBookView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = BookViewModel()
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var genre = ""
    @State private var isLoading = false
    @State private var searchResults: [BookRecommendation] = []
    @State private var selectedBook: BookRecommendation?
    @State private var showManualEntry = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                mainContent
            }
            .navigationBarItems(
                leading: closeButton,
                trailing: addButton
            )
            .alert(item: errorBinding) { errorWrapper in
                Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 24) {
            headerView

            if !showManualEntry {
                isbnSearchView
                searchResultsView
            } else {
                manualEntryView
            }

            Spacer()
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }

            Text("Add New Book")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Search by ISBN or enter details manually")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var isbnSearchView: some View {
        VStack(spacing: 16) {
            Text("Search by ISBN")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            TextField("Enter ISBN (10 or 13 digits)", text: $isbn)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .keyboardType(.numberPad)

            searchButton

            Button(action: {
                withAnimation(.spring()) {
                    showManualEntry = true
                }
            }) {
                Text("Enter Manually")
                    .font(.body)
                    .foregroundColor(.blue)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal, 32)
    }

    private var searchButton: some View {
        Button(action: {
            searchByISBN()
        }) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Search Book")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
            }
        }
        .disabled(isbn.isEmpty || isLoading)
    }

    private var searchResultsView: some View {
        Group {
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(searchResults) { book in
                            BookSearchResultView(book: book, isSelected: selectedBook?.id == book.id) {
                                selectedBook = book
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                }
            } else {
                EmptyView()
            }
        }
    }

    private var manualEntryView: some View {
        ScrollView {
            VStack(spacing: 20) {
                manualEntryForm
            }
            .padding(.vertical, 16)
        }
    }

    private var manualEntryForm: some View {
        VStack(spacing: 16) {
            Text("Manual Entry")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            titleField
            authorField
            isbnField
            genreField
            manualEntryButtons
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal, 32)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title *")
                .font(.headline)
                .foregroundColor(.secondary)

            TextField("Book Title", text: $title)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private var authorField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Author *")
                .font(.headline)
                .foregroundColor(.secondary)

            TextField("Author Name", text: $author)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private var isbnField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ISBN (Optional)")
                .font(.headline)
                .foregroundColor(.secondary)

            TextField("ISBN", text: $isbn)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .keyboardType(.numberPad)
        }
    }

    private var genreField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Genre (Optional)")
                .font(.headline)
                .foregroundColor(.secondary)

            TextField("Genre", text: $genre)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private var manualEntryButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                addBookManually()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Add Book")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
            }
            .disabled(title.isEmpty || author.isEmpty || isLoading)

            Button(action: {
                withAnimation(.spring()) {
                    showManualEntry = false
                }
            }) {
                Text("Search ISBN")
                    .font(.body)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
    }

    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(.primary)
                .font(.system(size: 16, weight: .medium))
        }
    }

    private var addButton: some View {
        Group {
            if selectedBook != nil {
                Button(action: {
                    addSelectedBook()
                }) {
                    Text("Add")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                }
            } else {
                EmptyView()
            }
        }
    }

    private var errorBinding: Binding<ErrorWrapper?> {
        Binding(
            get: { errorMessage.map { ErrorWrapper(error: $0) } },
            set: { _ in errorMessage = nil }
        )
    }

    private func searchByISBN() {
        guard !isbn.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        let booksService = GoogleBooksAPIService()
        booksService.searchBooks(query: "isbn:\(isbn)", maxResults: 5) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let books):
                    searchResults = books
                    if books.isEmpty {
                        errorMessage = "No books found with that ISBN. Try entering details manually."
                    }
                case .failure(let error):
                    errorMessage = "Search failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func addSelectedBook() {
        guard let book = selectedBook else { return }

        let newBook = Book(
            title: book.title,
            author: book.author,
            isbn: book.id, // Using Google Books ID as ISBN fallback
            genre: book.genre,
            status: .library
        )

        viewModel.saveBookToFirestore(newBook)
        presentationMode.wrappedValue.dismiss()
    }

    private func addBookManually() {
        guard !title.isEmpty && !author.isEmpty else { return }

        let newBook = Book(
            title: title,
            author: author,
            isbn: isbn.isEmpty ? nil : isbn,
            genre: genre.isEmpty ? nil : genre,
            status: .library
        )

        viewModel.saveBookToFirestore(newBook)
        presentationMode.wrappedValue.dismiss()
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}

struct BookSearchResultView: View {
    let book: BookRecommendation
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 50, height: 70)

                if let thumbnailURL = book.thumbnailURL,
                   let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 30, height: 30)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 46, height: 66)
                                .cornerRadius(6)
                        case .failure:
                            Image(systemName: "book")
                                .resizable()
                                .frame(width: 24, height: 30)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "book")
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

                // BookRecommendation.genre is non-optional (String). Show only if non-empty and not "Unknown".
                if !book.genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && book.genre.lowercased() != "unknown" {
                    Text(book.genre)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Selection Indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)

                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .opacity(isSelected ? 1.0 : 0.8)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(), value: isSelected)
        .onTapGesture {
            onSelect()
        }
    }
}