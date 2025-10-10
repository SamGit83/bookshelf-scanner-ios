import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AddBookView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BookViewModel
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var genre = ""
    @State private var isLoading = false
    @State private var searchResults: [BookRecommendation] = []
    @State private var selectedBook: BookRecommendation?
    @State private var showManualEntry = false
    @State private var errorMessage: Error?
    @State private var showUpgradeModal = false

    var body: some View {
        NavigationView {
            ZStack {
                AppleBooksColors.background
                    .ignoresSafeArea()

                mainContent
            }
            .navigationBarItems(
                leading: closeButton,
                trailing: addButton
            )
            .alert(item: errorBinding) { (errorWrapper: ErrorWrapper) in
                Alert(title: Text("Error"), message: Text(errorWrapper.error.localizedDescription), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeModalView()
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: AppleBooksSpacing.space32) {
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
        VStack(spacing: AppleBooksSpacing.space16) {
            Text("Add New Book")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)

            Text("Search by ISBN or enter details manually")
                .font(AppleBooksTypography.bodyMedium)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
        .padding(.vertical, AppleBooksSpacing.space32)
    }

    private var isbnSearchView: some View {
        AppleBooksCard {
            VStack(spacing: AppleBooksSpacing.space16) {
                Text("Search by ISBN")
                    .font(AppleBooksTypography.headlineMedium)
                    .foregroundColor(AppleBooksColors.text)

                TextField("Enter ISBN (10 or 13 digits)", text: $isbn)
                    .padding(AppleBooksSpacing.space12)
                    .background(AppleBooksColors.card.opacity(0.5))
                    .cornerRadius(8)
                    .keyboardType(.numberPad)
                    .foregroundColor(AppleBooksColors.text)

                searchButton

                Button(action: {
                    withAnimation(.spring()) {
                        showManualEntry = true
                    }
                }) {
                    Text("Enter Manually")
                        .font(AppleBooksTypography.captionBold)
                        .foregroundColor(AppleBooksColors.accent)
                }
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
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
                    .padding(AppleBooksSpacing.space16)
                    .background(AppleBooksColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(AppleBooksTypography.buttonLarge)
            }
        }
        .disabled(isbn.isEmpty || isLoading)
    }

    private var searchResultsView: some View {
        Group {
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: AppleBooksSpacing.space16) {
                        ForEach(searchResults) { book in
                            BookSearchResultView(book: book, isSelected: selectedBook?.id == book.id) {
                                selectedBook = book
                            }
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                    .padding(.vertical, AppleBooksSpacing.space16)
                }
            } else {
                EmptyView()
            }
        }
    }

    private var manualEntryView: some View {
        ScrollView {
            VStack(spacing: AppleBooksSpacing.space20) {
                manualEntryForm
            }
            .padding(.vertical, AppleBooksSpacing.space16)
        }
    }

    private var manualEntryForm: some View {
        AppleBooksCard {
            VStack(spacing: AppleBooksSpacing.space16) {
                Text("Manual Entry")
                    .font(AppleBooksTypography.headlineMedium)
                    .foregroundColor(AppleBooksColors.text)

                titleField
                authorField
                isbnField
                genreField
                manualEntryButtons
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
            Text("Title *")
                .font(AppleBooksTypography.headlineSmall)
                .foregroundColor(AppleBooksColors.textSecondary)

            TextField("Book Title", text: $title)
                .padding(AppleBooksSpacing.space12)
                .background(AppleBooksColors.card.opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(AppleBooksColors.text)
        }
    }

    private var authorField: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
            Text("Author *")
                .font(AppleBooksTypography.headlineSmall)
                .foregroundColor(AppleBooksColors.textSecondary)

            TextField("Author Name", text: $author)
                .padding(AppleBooksSpacing.space12)
                .background(AppleBooksColors.card.opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(AppleBooksColors.text)
        }
    }

    private var isbnField: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
            Text("ISBN (Optional)")
                .font(AppleBooksTypography.headlineSmall)
                .foregroundColor(AppleBooksColors.textSecondary)

            TextField("ISBN", text: $isbn)
                .padding(AppleBooksSpacing.space12)
                .background(AppleBooksColors.card.opacity(0.5))
                .cornerRadius(8)
                .keyboardType(.numberPad)
                .foregroundColor(AppleBooksColors.text)
        }
    }

    private var genreField: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
            Text("Genre (Optional)")
                .font(AppleBooksTypography.headlineSmall)
                .foregroundColor(AppleBooksColors.textSecondary)

            TextField("Genre", text: $genre)
                .padding(AppleBooksSpacing.space12)
                .background(AppleBooksColors.card.opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(AppleBooksColors.text)
        }
    }

    private var manualEntryButtons: some View {
        HStack(spacing: AppleBooksSpacing.space12) {
            Button(action: {
                addBookManually()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Add Book")
                        .frame(maxWidth: .infinity)
                        .padding(AppleBooksSpacing.space16)
                        .background(AppleBooksColors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(AppleBooksTypography.buttonLarge)
                }
            }
            .disabled(title.isEmpty || author.isEmpty || isLoading)

            Button(action: {
                withAnimation(.spring()) {
                    showManualEntry = false
                }
            }) {
                Text("Search ISBN")
                    .font(AppleBooksTypography.captionBold)
                    .foregroundColor(AppleBooksColors.accent)
                    .padding(.horizontal, AppleBooksSpacing.space16)
                    .padding(.vertical, AppleBooksSpacing.space12)
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
            get: { errorMessage.map { ErrorWrapper(error: $0, guidance: nil) } },
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
                        errorMessage = NSError(domain: "SearchError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No books found with that ISBN. Try entering details manually."])
                    }
                case .failure(let error):
                    errorMessage = NSError(domain: "SearchError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Search failed: \(error.localizedDescription)"])
                }
            }
        }
    }

    private func addSelectedBook() {
        guard let book = selectedBook else { return }

        if !UsageTracker.shared.canAddBook() {
            showUpgradeModal = true
            return
        }

        viewModel.addBookFromRecommendation(book) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    if let nsError = error as? NSError, nsError.domain == "DuplicateBook" {
                        self.errorMessage = NSError(domain: "AddBookError", code: 1, userInfo: [NSLocalizedDescriptionKey: "This book is already in your library"])
                    } else {
                        self.errorMessage = NSError(domain: "AddBookError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to add book: \(error.localizedDescription)"])
                    }
                }
            }
        }
    }

    private func addBookManually() {
        guard !title.isEmpty && !author.isEmpty else { return }

        if !UsageTracker.shared.canAddBook() {
            showUpgradeModal = true
            return
        }

        // Always try to fetch metadata from Google Books API using title and author search
        isLoading = true
        errorMessage = nil

        let booksService = GoogleBooksAPIService()
        booksService.fetchBookDetails(isbn: isbn.isEmpty ? nil : isbn, title: title, author: author) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let recommendation):
                    if let recommendation = recommendation {
                        // Create book with fetched metadata
                        var newBook = Book(
                            title: self.title,
                            author: self.author,
                            isbn: self.isbn.isEmpty ? nil : self.isbn,
                            genre: recommendation.genre != "Unknown" ? recommendation.genre : (self.genre.isEmpty ? nil : self.genre),
                            status: .library,
                            ageRating: recommendation.ageRating
                        )

                        // Map additional metadata
                        newBook.pageCount = recommendation.pageCount
                        newBook.publicationYear = recommendation.publishedDate
                        newBook.teaser = recommendation.description
                        newBook.coverImageURL = recommendation.thumbnailURL

                        // Calculate estimated reading time if page count is available
                        if let pages = recommendation.pageCount {
                            newBook.estimatedReadingTime = self.calculateEstimatedReadingTime(pages: pages)
                        }

                        self.viewModel.saveBookToFirestore(newBook)
                        self.viewModel.successMessage = "Book added to your library."
                        self.presentationMode.wrappedValue.dismiss()
                    } else {
                        // No metadata found, create with manual data
                        self.createBookWithManualData()
                    }
                case .failure(let error):
                    print("DEBUG AddBookView: Failed to fetch book details: \(error.localizedDescription)")
                    // Fall back to manual data
                    self.createBookWithManualData()
                }
            }
        }
    }

    private func createBookWithManualData() {
        let newBook = Book(
            title: title,
            author: author,
            isbn: isbn.isEmpty ? nil : isbn,
            genre: genre.isEmpty ? nil : genre,
            status: .library
        )

        viewModel.saveBookToFirestore(newBook)
        viewModel.successMessage = "Book added to your library."
        presentationMode.wrappedValue.dismiss()
    }

    private func calculateEstimatedReadingTime(pages: Int) -> String {
        // Average reading speed: 200 words per minute
        // Average words per page: 250
        // Pages per minute: 200/250 = 0.8
        // Minutes per page: 1/0.8 ≈ 1.25
        let minutesPerPage = 1.25
        let totalMinutes = Double(pages) * minutesPerPage

        if totalMinutes < 60 {
            let roundedMinutes = Int(ceil(totalMinutes))
            return "\(roundedMinutes) minute\(roundedMinutes != 1 ? "s" : "")"
        } else {
            let hours = Int(totalMinutes / 60)
            let remainingMinutes = Int(ceil(totalMinutes.truncatingRemainder(dividingBy: 60)))
            let hourString = "\(hours) hour\(hours != 1 ? "s" : "")"
            let minuteString = remainingMinutes > 0 ? " \(remainingMinutes) minute\(remainingMinutes != 1 ? "s" : "")" : ""
            return hourString + minuteString
        }
    }
}

struct BookSearchResultView: View {
    let book: BookRecommendation
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        AppleBooksCard {
            HStack(spacing: AppleBooksSpacing.space12) {
                // Book Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppleBooksColors.card.opacity(0.5))
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
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text(book.title)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .lineLimit(2)

                    Text(book.author)
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    // BookRecommendation.genre is non-optional (String). Show only if non-empty and not "Unknown".
                    if !book.genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && book.genre.lowercased() != "unknown" {
                        Text(book.genre)
                            .font(AppleBooksTypography.captionBold)
                            .foregroundColor(AppleBooksColors.accent)
                    }
                }

                Spacer()

                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppleBooksColors.accent : AppleBooksColors.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(AppleBooksColors.accent)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}