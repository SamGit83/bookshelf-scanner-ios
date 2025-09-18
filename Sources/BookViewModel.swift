import SwiftUI
import Combine
import FirebaseFirestore

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
        isLoading = true
        errorMessage = nil

        apiService.analyzeImage(image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let responseText):
                    self?.parseAndAddBooks(from: responseText)
                case .failure(let error):
                    ErrorHandler.shared.handle(error, context: "Image Analysis")
                }
            }
        }
    }

    private func parseAndAddBooks(from responseText: String) {
        // Simple parsing - in a real app, you'd use more robust JSON parsing
        // Assuming the response is a JSON string that can be decoded
        do {
            if let data = responseText.data(using: .utf8) {
                let decodedBooks = try JSONDecoder().decode([Book].self, from: data)
                for book in decodedBooks {
                    saveBookToFirestore(book)
                }
            }
        } catch {
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

    private func setupFirestoreListener() {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            // Load from cache if offline
            if let cachedBooks = OfflineCache.shared.loadCachedBooks() {
                self.books = cachedBooks
            }
            return
        }

        listener?.remove()

        listener = db.collection("users").document(userId).collection("books")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    // Try to load from cache if Firestore fails
                    if let cachedBooks = OfflineCache.shared.loadCachedBooks() {
                        self?.books = cachedBooks
                    } else {
                        ErrorHandler.shared.handle(error, context: "Loading Books")
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    self?.books = []
                    return
                }

                let loadedBooks = documents.compactMap { document in
                    do {
                        return try document.data(as: Book.self)
                    } catch {
                        print("Error decoding book: \(error)")
                        return nil
                    }
                }

                self?.books = loadedBooks
                // Cache the books for offline use
                OfflineCache.shared.cacheBooks(loadedBooks)
            }
    }

    func saveBookToFirestore(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        do {
            let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)
            try bookRef.setData(from: book) { error in
                if let error = error {
                    self.errorMessage = "Failed to save book: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = "Failed to encode book: \(error.localizedDescription)"
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