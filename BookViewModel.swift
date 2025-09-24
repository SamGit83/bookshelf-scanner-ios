import SwiftUI
import Combine
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#endif

class BookViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = GeminiAPIService()
    private let grokService = GrokAPIService()
    private let googleBooksService = GoogleBooksAPIService()
    private let db = FirebaseConfig.shared.db
    private var listener: ListenerRegistration?

    init() {
        setupFirestoreListener()
    }

    deinit {
        listener?.remove()
    }

    func scanBookshelf(image: UIImage) {
        print("DEBUG BookViewModel: scanBookshelf called")
        isLoading = true
        errorMessage = nil

        apiService.analyzeImage(image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let responseText):
                    print("DEBUG BookViewModel: Gemini analysis success, response length: \(responseText.count)")
                    self?.parseAndAddBooks(from: responseText)
                case .failure(let error):
                    print("DEBUG BookViewModel: Gemini analysis failed: \(error.localizedDescription)")
                    ErrorHandler.shared.handle(error, context: "Image Analysis")
                }
            }
        }
    }

    private func parseAndAddBooks(from responseText: String) {
        print("DEBUG BookViewModel: parseAndAddBooks called, responseText: \(responseText)")
        // Extract JSON from markdown code block if present
        var jsonString = responseText
        if let jsonStart = responseText.range(of: "```json\n"), let jsonEnd = responseText.range(of: "\n```", options: .backwards) {
            jsonString = String(responseText[jsonStart.upperBound..<jsonEnd.lowerBound])
            print("DEBUG BookViewModel: Extracted JSON from markdown: \(jsonString)")
        } else {
            print("DEBUG BookViewModel: No markdown found, using full responseText")
        }

        // Simple parsing - in a real app, you'd use more robust JSON parsing
        // Assuming the response is a JSON string that can be decoded
        do {
            if let data = jsonString.data(using: .utf8) {
                print("DEBUG BookViewModel: Attempting to decode JSON: \(jsonString)")
                let decodedBooks = try JSONDecoder().decode([Book].self, from: data)
                print("DEBUG BookViewModel: Successfully decoded \(decodedBooks.count) books")

                // Check for duplicates based on title and author (case-insensitive)
                let existingTitlesAndAuthors = Set(self.books.map {
                    ($0.title ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) + "|" + ($0.author ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                })

                for book in decodedBooks {
                    let normalizedTitle = (book.title ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let normalizedAuthor = (book.author ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                    if existingTitlesAndAuthors.contains(normalizedTitle + "|" + normalizedAuthor) {
                        print("DEBUG BookViewModel: Skipping duplicate book: \(book.title ?? "") by \(book.author ?? "")")
                        continue
                    }

                    print("DEBUG BookViewModel: Fetching cover for book: \(book.title ?? "") by \(book.author ?? "")")
                    googleBooksService.fetchCoverURL(isbn: book.isbn, title: book.title, author: book.author) { [weak self] result in
                        var updatedBook = book
                        switch result {
                        case .success(let url):
                            if let urlString = url {
                                // Convert HTTP to HTTPS for security and iOS compatibility
                                let secureURLString = urlString.replacingOccurrences(of: "http://", with: "https://")
                                print("DEBUG BookViewModel: Fetched cover URL: \(secureURLString) for \(book.title ?? "")")
                                updatedBook.coverImageURL = secureURLString
                                // Try to download the image data for local storage
                                if let imageURL = URL(string: urlString) {
                                    URLSession.shared.dataTask(with: imageURL) { data, response, error in
                                        DispatchQueue.main.async {
                                            if let data = data, error == nil {
                                                updatedBook.coverImageData = data
                                                print("DEBUG BookViewModel: Downloaded cover image data for \(book.title ?? "")")
                                            } else {
                                                print("DEBUG BookViewModel: Failed to download cover image for \(book.title ?? ""): \(error?.localizedDescription ?? "Unknown error")")
                                            }
                                            // Save to Firestore and update local array
                                            self?.saveBookToFirestore(updatedBook)
                                            self?.updateLocalBook(updatedBook)
                                        }
                                    }.resume()
                                } else {
                                    // Save with URL even if download fails
                                    self?.saveBookToFirestore(updatedBook)
                                    self?.updateLocalBook(updatedBook)
                                }
                            } else {
                                print("DEBUG BookViewModel: No cover URL found for \(book.title ?? "")")
                                self?.saveBookToFirestore(updatedBook)
                            }
                        case .failure(let error):
                            print("DEBUG BookViewModel: Failed to fetch cover for \(book.title ?? ""): \(error.localizedDescription)")
                            self?.saveBookToFirestore(updatedBook)
                        }
                    }
                }
            } else {
                print("DEBUG BookViewModel: Failed to convert jsonString to data")
                errorMessage = "Failed to parse book data. Please try again."
            }
        } catch {
            print("DEBUG BookViewModel: JSON decode error: \(error)")
            print("DEBUG BookViewModel: Failed JSON string: \(jsonString)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("DEBUG BookViewModel: Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("DEBUG BookViewModel: Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("DEBUG BookViewModel: Value not found for type \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("DEBUG BookViewModel: Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("DEBUG BookViewModel: Unknown decoding error")
                }
            }
            // Fallback: try to extract basic info with regex or string parsing
            errorMessage = "Failed to parse book data. Please try again."
        }
    }

    func refreshData() {
        setupFirestoreListener()
    }

    func refreshBookCovers() {
        print("DEBUG BookViewModel: Manual cover refresh requested")
        migrateExistingHTTPURLs() // First migrate any HTTP URLs to HTTPS
        fetchMissingCoversForExistingBooks()
    }

    private func migrateExistingHTTPURLs() {
        print("DEBUG BookViewModel: Starting migration of HTTP URLs to HTTPS")
        guard let userId = FirebaseConfig.shared.currentUserId else {
            print("DEBUG BookViewModel: Cannot migrate URLs - user not authenticated")
            return
        }

        let booksRef = db.collection("users").document(userId).collection("books")

        booksRef.whereField("coverImageURL", isGreaterThan: "").getDocuments { snapshot, error in
            if let error = error {
                print("DEBUG BookViewModel: Error fetching books for migration: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("DEBUG BookViewModel: No documents found for migration")
                return
            }

            print("DEBUG BookViewModel: Found \(documents.count) books to check for HTTP URLs")

            for document in documents {
                let data = document.data()
                if let coverURL = data["coverImageURL"] as? String,
                   coverURL.hasPrefix("http://") {

                    let httpsURL = coverURL.replacingOccurrences(of: "http://", with: "https://")
                    print("DEBUG BookViewModel: Migrating \(coverURL) to \(httpsURL)")

                    document.reference.updateData(["coverImageURL": httpsURL]) { error in
                        if let error = error {
                            print("DEBUG BookViewModel: Failed to migrate URL for book \(document.documentID): \(error.localizedDescription)")
                        } else {
                            print("DEBUG BookViewModel: Successfully migrated URL for book \(document.documentID)")
                        }
                    }
                }
            }
        }
    }

    func fetchMissingCoversForExistingBooks() {
        print("DEBUG BookViewModel: fetchMissingCoversForExistingBooks called")
        let booksWithoutCovers = books.filter { $0.coverImageURL == nil && $0.coverImageData == nil }
        print("DEBUG BookViewModel: Found \(booksWithoutCovers.count) books without covers")

        // Process books with rate limiting to avoid overwhelming the API
        processBooksForCovers(Array(booksWithoutCovers), index: 0)
    }

    private func processBooksForCovers(_ booksToProcess: [Book], index: Int) {
        guard index < booksToProcess.count else {
            print("DEBUG BookViewModel: Finished processing all books for covers")
            return
        }

        let book = booksToProcess[index]
        print("DEBUG BookViewModel: Fetching cover for existing book (\(index + 1)/\(booksToProcess.count)): \(book.title ?? "") by \(book.author ?? "")")

        googleBooksService.fetchCoverURL(isbn: book.isbn, title: book.title, author: book.author) { [weak self] result in
            var updatedBook = book
            switch result {
            case .success(let url):
                if let urlString = url {
                    // Convert HTTP to HTTPS for security and iOS compatibility
                    let secureURLString = urlString.replacingOccurrences(of: "http://", with: "https://")
                    print("DEBUG BookViewModel: Fetched cover URL for existing book: \(secureURLString)")
                    updatedBook.coverImageURL = secureURLString
                    // Try to download the image data
                    if let imageURL = URL(string: urlString) {
                        URLSession.shared.dataTask(with: imageURL) { data, response, error in
                            DispatchQueue.main.async {
                                if let data = data, error == nil {
                                    updatedBook.coverImageData = data
                                    print("DEBUG BookViewModel: Downloaded cover image data for existing book")
                                } else {
                                    print("DEBUG BookViewModel: Failed to download cover for existing book: \(error?.localizedDescription ?? "Unknown error")")
                                }
                                // Save to Firestore and update local array
                                self?.saveBookToFirestore(updatedBook)
                                self?.updateLocalBook(updatedBook)

                                // Process next book after a delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self?.processBooksForCovers(booksToProcess, index: index + 1)
                                }
                            }
                        }.resume()
                    } else {
                        // Save with URL even if download fails
                        self?.saveBookToFirestore(updatedBook)
                        self?.updateLocalBook(updatedBook)
                        // Process next book
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.processBooksForCovers(booksToProcess, index: index + 1)
                        }
                    }
                } else {
                    print("DEBUG BookViewModel: No cover URL found for existing book: \(book.title ?? "")")
                    // Process next book
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.processBooksForCovers(booksToProcess, index: index + 1)
                    }
                }
            case .failure(let error):
                print("DEBUG BookViewModel: Failed to fetch cover for existing book \(book.title ?? ""): \(error.localizedDescription)")
                // Process next book even on failure
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.processBooksForCovers(booksToProcess, index: index + 1)
                }
            }
        }
    }

    func moveBook(_ book: Book, to status: BookStatus) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.updateData(["status": status.rawValue]) { error in
            if let error = error {
                self.errorMessage = "Failed to update book: \(error.localizedDescription)"
            }
        }
    }

    func deleteBook(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.delete { error in
            if let error = error {
                self.errorMessage = "Failed to delete book: \(error.localizedDescription)"
            }
        }
    }

    func updateBookTeaser(_ book: Book, teaser: String) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.updateData(["teaser": teaser]) { error in
            if let error = error {
                self.errorMessage = "Failed to update teaser: \(error.localizedDescription)"
            } else {
                // Update local book
                if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                    self.books[index].teaser = teaser
                }
            }
        }
    }

    func updateBookAuthorBio(_ book: Book, authorBio: String) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.updateData(["authorBio": authorBio]) { error in
            if let error = error {
                self.errorMessage = "Failed to update author bio: \(error.localizedDescription)"
            } else {
                // Update local book
                if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                    self.books[index].authorBio = authorBio
                }
            }
        }
    }

    func clearAllLibraryBooks() {
        let libraryBooks = self.libraryBooks
        for book in libraryBooks {
            deleteBook(book)
        }
    }

    func clearAllBooks() {
        for book in books {
            deleteBook(book)
        }
    }

    private func setupFirestoreListener() {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            print("DEBUG BookViewModel: setupFirestoreListener - user not authenticated, loading from cache")
            // Load from cache if offline
            if let cachedBooks = OfflineCache.shared.loadCachedBooks() {
                self.books = cachedBooks
                print("DEBUG BookViewModel: Loaded \(cachedBooks.count) books from cache")
            } else {
                print("DEBUG BookViewModel: No cached books available")
            }
            return
        }

        print("DEBUG BookViewModel: Setting up Firestore listener for userId=\(userId)")
        listener?.remove()

        listener = db.collection("users").document(userId).collection("books")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("DEBUG BookViewModel: Firestore listener error: \(error.localizedDescription), loading from cache")
                    // Try to load from cache if Firestore fails
                    if let cachedBooks = OfflineCache.shared.loadCachedBooks() {
                        self?.books = cachedBooks
                        print("DEBUG BookViewModel: Loaded \(cachedBooks.count) books from cache due to error")
                    } else {
                        print("DEBUG BookViewModel: No cached books, handling error")
                        ErrorHandler.shared.handle(error, context: "Loading Books")
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("DEBUG BookViewModel: No documents in snapshot")
                    self?.books = []
                    return
                }

                print("DEBUG BookViewModel: Received \(documents.count) documents from Firestore")
                let loadedBooks: [Book] = documents.compactMap { document in
                    let data = document.data()
                    print("DEBUG BookViewModel: Processing document \(document.documentID), data keys: \(data.keys.sorted())")
                    print("DEBUG BookViewModel: title value: \(String(describing: data["title"])), type: \(type(of: data["title"]))")
                    print("DEBUG BookViewModel: author value: \(String(describing: data["author"])), type: \(type(of: data["author"]))")
                    let title = (data["title"] as? String) ?? ""
                    let author = (data["author"] as? String) ?? ""

                    let isbn = data["isbn"] as? String
                    let genre = data["genre"] as? String
                    let subGenre = data["subGenre"] as? String
                    let estimatedReadingTime = data["estimatedReadingTime"] as? String

                    let statusRaw = (data["status"] as? String) ?? BookStatus.library.rawValue
                    let status = BookStatus(rawValue: statusRaw) ?? .library

                    var dateAdded = Date()
                    if let ts = data["dateAdded"] as? Timestamp {
                        dateAdded = ts.dateValue()
                    } else if let d = data["dateAdded"] as? Date {
                        dateAdded = d
                    }

                    let coverData = data["coverImageData"] as? Data
                    let coverImageURL = data["coverImageURL"] as? String
                    let teaser = data["teaser"] as? String
                    let authorBio = data["authorBio"] as? String
                    let pageCount = data["pageCount"] as? Int

                    // Build Book
                    var book = Book(title: title, author: author, isbn: isbn, genre: genre, status: status, coverImageData: coverData, coverImageURL: coverImageURL)
                    book.subGenre = subGenre
                    book.estimatedReadingTime = estimatedReadingTime
                    // Assign id (from stored id or documentID) and date
                    if let idString = data["id"] as? String, let uuid = UUID(uuidString: idString) {
                        book.id = uuid
                    }
                    book.dateAdded = dateAdded
                    book.teaser = teaser
                    book.authorBio = authorBio
                    book.pageCount = pageCount
                    return book
                }

                print("DEBUG BookViewModel: Successfully loaded \(loadedBooks.count) books from Firestore")
                let libraryBooksCount = loadedBooks.filter { $0.status == .library }.count
                print("DEBUG BookViewModel: Library books count: \(libraryBooksCount)")
                self?.books = loadedBooks
                // Cache the books for offline use
                OfflineCache.shared.cacheBooks(loadedBooks)

                // Fetch missing covers for existing books
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Small delay to avoid overwhelming the API
                    self?.fetchMissingCoversForExistingBooks()
                }
            }
    }

    func saveBookToFirestore(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            print("DEBUG BookViewModel: saveBookToFirestore failed - user not authenticated")
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)
        let data: [String: Any] = [
            "id": book.id.uuidString,
            "title": book.title ?? "",
            "author": book.author ?? "",
            "isbn": book.isbn as Any,
            "genre": book.genre as Any,
            "subGenre": book.subGenre as Any,
            "estimatedReadingTime": book.estimatedReadingTime as Any,
            "pageCount": book.pageCount as Any,
            "status": book.status.rawValue,
            "dateAdded": Timestamp(date: book.dateAdded),
            "coverImageData": book.coverImageData as Any,
            "coverImageURL": book.coverImageURL as Any,
            "teaser": book.teaser as Any,
            "authorBio": book.authorBio as Any
        ]
        print("DEBUG BookViewModel: saveBookToFirestore data keys: \(data.keys.sorted())")
        print("DEBUG BookViewModel: saveBookToFirestore pageCount value: \(String(describing: book.pageCount))")
        bookRef.setData(data) { error in
            if let error = error {
                print("DEBUG BookViewModel: Failed to save book to Firestore: \(error.localizedDescription)")
                self.errorMessage = "Failed to save book: \(error.localizedDescription)"
            } else {
                print("DEBUG BookViewModel: Successfully saved book to Firestore")
            }
        }
    }

    private func updateLocalBook(_ updatedBook: Book) {
        DispatchQueue.main.async {
            if let index = self.books.firstIndex(where: { $0.id == updatedBook.id }) {
                self.books[index] = updatedBook
                print("DEBUG BookViewModel: Updated local book with cover image: \(updatedBook.title ?? "")")
            }
        }
    }

    // Legacy support - map old statuses to new ones
    var libraryBooks: [Book] {
        books.filter { $0.status == .library || $0.status == .toRead || $0.status == .reading || $0.status == .read }
    }

    var currentlyReadingBooks: [Book] {
        books.filter { $0.status == .currentlyReading || $0.status == .reading }
    }
    
    // New status-based computed properties
    var toReadBooks: [Book] {
        books.filter { $0.status == .toRead || $0.status == .library }
    }
    
    var readingBooks: [Book] {
        books.filter { $0.status == .reading || $0.status == .currentlyReading }
    }
    
    var readBooks: [Book] {
        books.filter { $0.status == .read }
    }

    // MARK: - Recommendations

    func generateRecommendations(for currentBook: Book? = nil, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        // Use Grok AI to generate personalized recommendations based on user's entire library
        grokService.generateRecommendations(userBooks: books, currentBook: currentBook) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recommendations):
                    // Remove duplicates and limit to 20 recommendations
                    let uniqueRecommendations = self.removeDuplicates(from: recommendations)
                    let limitedRecommendations = Array(uniqueRecommendations.prefix(20))

                    // Cache recommendations for offline use
                    OfflineCache.shared.cacheRecommendations(limitedRecommendations)

                    completion(.success(limitedRecommendations))
                case .failure(let error):
                    print("DEBUG BookViewModel: Grok recommendation failed: \(error.localizedDescription)")
                    // Fallback to cached recommendations if available
                    if let cachedRecommendations = OfflineCache.shared.loadCachedRecommendations() {
                        completion(.success(cachedRecommendations))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private func getFavoriteAuthors() -> [String] {
        let authorCounts = books.reduce(into: [String: Int]()) { counts, book in
            counts[book.author ?? "", default: 0] += 1
        }
        return authorCounts.sorted { $0.value > $1.value }.map { $0.key }
    }

    private func getFavoriteGenres() -> [String] {
        let genreCounts = books.compactMap { $0.genre }.reduce(into: [String: Int]()) { counts, genre in
            counts[genre, default: 0] += 1
        }
        return genreCounts.sorted { $0.value > $1.value }.map { $0.key }
    }

    private func getRecentBooks() -> [Book] {
        return books.sorted { $0.dateAdded > $1.dateAdded }
    }

    private func removeDuplicates(from recommendations: [BookRecommendation]) -> [BookRecommendation] {
        var seen = Set<String>()
        return recommendations.filter { recommendation in
            let identifier = "\(recommendation.title)-\(recommendation.author)"
            if seen.contains(identifier) {
                return false
            }
            seen.insert(identifier)
            return true
        }
    }
}