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
                    $0.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) + "|" + $0.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                })

                for book in decodedBooks {
                    let normalizedTitle = book.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let normalizedAuthor = book.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                    if existingTitlesAndAuthors.contains(normalizedTitle + "|" + normalizedAuthor) {
                        print("DEBUG BookViewModel: Skipping duplicate book: \(book.title) by \(book.author)")
                        continue
                    }

                    print("DEBUG BookViewModel: Saving book: \(book.title) by \(book.author)")
                    saveBookToFirestore(book)
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

    func clearAllLibraryBooks() {
        let libraryBooks = self.libraryBooks
        for book in libraryBooks {
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
                    guard
                        let title = data["title"] as? String,
                        let author = data["author"] as? String
                    else {
                        print("DEBUG BookViewModel: Document missing title or author: \(document.documentID)")
                        return nil
                    }

                    let isbn = data["isbn"] as? String
                    let genre = data["genre"] as? String

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

                    // Build Book
                    var book = Book(title: title, author: author, isbn: isbn, genre: genre, status: status, coverImageData: coverData, coverImageURL: coverImageURL)
                    // Assign id (from stored id or documentID) and date
                    if let idString = data["id"] as? String, let uuid = UUID(uuidString: idString) {
                        book.id = uuid
                    }
                    book.dateAdded = dateAdded
                    return book
                }

                print("DEBUG BookViewModel: Successfully loaded \(loadedBooks.count) books from Firestore")
                let libraryBooksCount = loadedBooks.filter { $0.status == .library }.count
                print("DEBUG BookViewModel: Library books count: \(libraryBooksCount)")
                self?.books = loadedBooks
                // Cache the books for offline use
                OfflineCache.shared.cacheBooks(loadedBooks)
            }
    }

    func saveBookToFirestore(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            print("DEBUG BookViewModel: saveBookToFirestore failed - user not authenticated")
            errorMessage = "User not authenticated"
            return
        }

        print("DEBUG BookViewModel: Saving book to Firestore: userId=\(userId), bookId=\(book.id.uuidString)")
        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)
        let data: [String: Any] = [
            "id": book.id.uuidString,
            "title": book.title,
            "author": book.author,
            "isbn": book.isbn as Any,
            "genre": book.genre as Any,
            "status": book.status.rawValue,
            "dateAdded": Timestamp(date: book.dateAdded),
            "coverImageData": book.coverImageData as Any,
            "coverImageURL": book.coverImageURL as Any
        ]
        bookRef.setData(data) { error in
            if let error = error {
                print("DEBUG BookViewModel: Failed to save book to Firestore: \(error.localizedDescription)")
                self.errorMessage = "Failed to save book: \(error.localizedDescription)"
            } else {
                print("DEBUG BookViewModel: Successfully saved book to Firestore")
            }
        }
    }

    var libraryBooks: [Book] {
        books.filter { $0.status == .library }
    }

    var currentlyReadingBooks: [Book] {
        books.filter { $0.status == .currentlyReading }
    }

    // MARK: - Recommendations

    private let booksAPIService = GoogleBooksAPIService()

    func generateRecommendations(completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        // Analyze user's reading patterns
        let favoriteAuthors = getFavoriteAuthors()
        let favoriteGenres = getFavoriteGenres()
        let recentBooks = getRecentBooks()

        // Generate recommendations based on patterns
        var allRecommendations: [BookRecommendation] = []

        let group = DispatchGroup()

        // Get recommendations based on favorite authors
        if let topAuthor = favoriteAuthors.first {
            group.enter()
            booksAPIService.getRecommendationsBasedOnAuthor(topAuthor) { result in
                if case .success(let recommendations) = result {
                    allRecommendations.append(contentsOf: recommendations)
                }
                group.leave()
            }
        }

        // Get recommendations based on favorite genres
        if let topGenre = favoriteGenres.first {
            group.enter()
            booksAPIService.getRecommendationsBasedOnGenre(topGenre) { result in
                if case .success(let recommendations) = result {
                    allRecommendations.append(contentsOf: recommendations)
                }
                group.leave()
            }
        }

        // Get recommendations based on recent books
        if let recentBook = recentBooks.first {
            group.enter()
            booksAPIService.getRecommendationsBasedOnTitle(recentBook.title) { result in
                if case .success(let recommendations) = result {
                    allRecommendations.append(contentsOf: recommendations)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Remove duplicates and limit to 20 recommendations
            let uniqueRecommendations = self.removeDuplicates(from: allRecommendations)
            let limitedRecommendations = Array(uniqueRecommendations.prefix(20))

            // Cache recommendations for offline use
            OfflineCache.shared.cacheRecommendations(limitedRecommendations)

            completion(.success(limitedRecommendations))
        }
    }

    private func getFavoriteAuthors() -> [String] {
        let authorCounts = books.reduce(into: [String: Int]()) { counts, book in
            counts[book.author, default: 0] += 1
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