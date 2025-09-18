import SwiftUI

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
                LiquidGlass.primary.opacity(0.05)
                    .ignoresSafeArea()

                VStack(spacing: LiquidGlass.Spacing.space24) {
                    // Header
                    VStack(spacing: LiquidGlass.Spacing.space16) {
                        ZStack {
                            Circle()
                                .fill(LiquidGlass.primary.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .blur(radius: 10)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }

                        Text("Add New Book")
                            .font(LiquidGlass.Typography.headlineLarge)
                            .foregroundColor(.white)

                        Text("Search by ISBN or enter details manually")
                            .font(LiquidGlass.Typography.bodyMedium)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)

                    if !showManualEntry {
                        // ISBN Search Section
                        LiquidGlassCard {
                            VStack(spacing: LiquidGlass.Spacing.space16) {
                                Text("Search by ISBN")
                                    .font(LiquidGlass.Typography.headlineMedium)
                                    .foregroundColor(.white)

                                TextField("Enter ISBN (10 or 13 digits)", text: $isbn)
                                    .textFieldStyle(LiquidTextFieldStyle())
                                    .keyboardType(.numberPad)

                                LiquidGlassButton(
                                    title: "Search Book",
                                    style: .primary,
                                    isLoading: isLoading
                                ) {
                                    searchByISBN()
                                }
                                .disabled(isbn.isEmpty || isLoading)

                                Button(action: {
                                    withAnimation(LiquidGlass.Animation.spring) {
                                        showManualEntry = true
                                    }
                                }) {
                                    Text("Enter Manually")
                                        .font(LiquidGlass.Typography.bodyMedium)
                                        .foregroundColor(LiquidGlass.accent)
                                }
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)

                        // Search Results
                        if !searchResults.isEmpty {
                            ScrollView {
                                LazyVStack(spacing: LiquidGlass.Spacing.space16) {
                                    ForEach(searchResults) { book in
                                        BookSearchResultView(book: book, isSelected: selectedBook?.id == book.id) {
                                            selectedBook = book
                                        }
                                    }
                                }
                                .padding(.horizontal, LiquidGlass.Spacing.space32)
                                .padding(.vertical, LiquidGlass.Spacing.space16)
                            }
                        }
                    } else {
                        // Manual Entry Form
                        ScrollView {
                            VStack(spacing: LiquidGlass.Spacing.space20) {
                                LiquidGlassCard {
                                    VStack(spacing: LiquidGlass.Spacing.space16) {
                                        Text("Manual Entry")
                                            .font(LiquidGlass.Typography.headlineMedium)
                                            .foregroundColor(.white)

                                        VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                            Text("Title *")
                                                .font(LiquidGlass.Typography.captionLarge)
                                                .foregroundColor(.white.opacity(0.8))

                                            TextField("Book Title", text: $title)
                                                .textFieldStyle(LiquidTextFieldStyle())
                                        }

                                        VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                            Text("Author *")
                                                .font(LiquidGlass.Typography.captionLarge)
                                                .foregroundColor(.white.opacity(0.8))

                                            TextField("Author Name", text: $author)
                                                .textFieldStyle(LiquidTextFieldStyle())
                                        }

                                        VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                            Text("ISBN (Optional)")
                                                .font(LiquidGlass.Typography.captionLarge)
                                                .foregroundColor(.white.opacity(0.8))

                                            TextField("ISBN", text: $isbn)
                                                .textFieldStyle(LiquidTextFieldStyle())
                                                .keyboardType(.numberPad)
                                        }

                                        VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                            Text("Genre (Optional)")
                                                .font(LiquidGlass.Typography.captionLarge)
                                                .foregroundColor(.white.opacity(0.8))

                                            TextField("Genre", text: $genre)
                                                .textFieldStyle(LiquidTextFieldStyle())
                                        }

                                        HStack(spacing: LiquidGlass.Spacing.space12) {
                                            LiquidGlassButton(
                                                title: "Add Book",
                                                style: .primary,
                                                isLoading: isLoading
                                            ) {
                                                addBookManually()
                                            }
                                            .disabled(title.isEmpty || author.isEmpty || isLoading)

                                            Button(action: {
                                                withAnimation(LiquidGlass.Animation.spring) {
                                                    showManualEntry = false
                                                }
                                            }) {
                                                Text("Search ISBN")
                                                    .font(LiquidGlass.Typography.bodyMedium)
                                                    .foregroundColor(LiquidGlass.accent)
                                                    .padding(.horizontal, LiquidGlass.Spacing.space16)
                                                    .padding(.vertical, LiquidGlass.Spacing.space12)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, LiquidGlass.Spacing.space32)
                            }
                            .padding(.vertical, LiquidGlass.Spacing.space16)
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                },
                trailing: selectedBook != nil ? Button(action: {
                    addSelectedBook()
                }) {
                    Text("Add")
                        .foregroundColor(LiquidGlass.accent)
                        .font(.system(size: 16, weight: .medium))
                } : nil
            )
            .alert(item: Binding(
                get: { errorMessage.map { ErrorWrapper(error: $0) } },
                set: { _ in errorMessage = nil }
            )) { errorWrapper in
                Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
            }
        }
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

struct BookSearchResultView: View {
    let book: BookRecommendation
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        LiquidGlassCard {
            HStack(spacing: LiquidGlass.Spacing.space16) {
                // Book Cover
                ZStack {
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                        .fill(LiquidGlass.glassBackground)
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
                                    .cornerRadius(LiquidGlass.CornerRadius.small)
                            case .failure:
                                Image(systemName: "book")
                                    .resizable()
                                    .frame(width: 24, height: 30)
                                    .foregroundColor(.white.opacity(0.7))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "book")
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
                }

                Spacer()

                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? LiquidGlass.accent : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(LiquidGlass.accent)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .opacity(isSelected ? 1.0 : 0.8)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(LiquidGlass.Animation.spring, value: isSelected)
        .onTapGesture {
            onSelect()
        }
    }
}