import SwiftUI
import Combine
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#endif

// Analytics integration
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

class BookViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalBooks: Int = 0
    @Published var hasMoreBooks = true
    @Published var isLoadingMore = false

    private let apiService = GeminiAPIService()
    private let grokService = GrokAPIService()
    private let googleBooksService = GoogleBooksAPIService()
    private let db = FirebaseConfig.shared.db
    private var lastDocument: QueryDocumentSnapshot?
    private var isOfflineMode = false
    private var currentCachePage = 1

    init() {
        loadFirstPage()
    }

    func scanBookshelf(image: UIImage) {
        print("DEBUG BookViewModel: scanBookshelf called")

        // Check usage limits
        if !UsageTracker.shared.canPerformScan() {
            errorMessage = "Scan limit reached. Upgrade to Premium for unlimited scans."
            // Trigger upgrade prompt
            AnalyticsManager.shared.trackUpgradePromptShown(source: "scan_limit_hit", limitType: "scan")
            NotificationCenter.default.post(
                name: Notification.Name("UpgradePromptShown"),
                object: nil,
                userInfo: ["limit_type": "scan"]
            )
            return
        }

        isLoading = true
        errorMessage = nil
        let scanStartTime = Date()

        apiService.analyzeImage(image) { [weak self] result in
            let responseTime = Date().timeIntervalSince(scanStartTime)
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let responseText):
                    print("DEBUG BookViewModel: Gemini analysis success, response length: \(responseText.count)")
                    UsageTracker.shared.incrementScans()
                    // Track API call success
                    AnalyticsManager.shared.trackAPICall(service: "Gemini", endpoint: "analyzeImage", success: true, responseTime: responseTime)

                    // Trigger feature usage for surveys
                    NotificationCenter.default.post(
                        name: Notification.Name("FeatureUsed"),
                        object: nil,
                        userInfo: ["feature": "scan", "context": "successful_scan"]
                    )

                    self?.parseAndAddBooks(from: responseText)
                case .failure(let error):
                    print("DEBUG BookViewModel: Gemini analysis failed: \(error.localizedDescription)")
                    ErrorHandler.shared.handle(error, context: "Image Analysis")
                    // Track API call failure
                    AnalyticsManager.shared.trackAPICall(service: "Gemini", endpoint: "analyzeImage", success: false, responseTime: responseTime, errorMessage: error.localizedDescription)
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
                    let coverFetchStartTime = Date()
                    googleBooksService.fetchCoverURL(isbn: book.isbn, title: book.title, author: book.author) { [weak self] result in
                        let coverResponseTime = Date().timeIntervalSince(coverFetchStartTime)
                        var updatedBook = book
                        switch result {
                        case .success(let url):
                            AnalyticsManager.shared.trackAPICall(service: "GoogleBooks", endpoint: "fetchCoverURL", success: true, responseTime: coverResponseTime)
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
                                                // updatedBook.coverImageData = data // Commented out to reduce memory usage - rely on URL
                                                print("DEBUG BookViewModel: Downloaded cover image data for \(book.title ?? "") (not storing in memory)")
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
                            AnalyticsManager.shared.trackAPICall(service: "GoogleBooks", endpoint: "fetchCoverURL", success: false, responseTime: coverResponseTime, errorMessage: error.localizedDescription)
                            print("DEBUG BookViewModel: Failed to fetch cover for \(book.title ?? ""): \(error.localizedDescription)")
                            self?.saveBookToFirestore(updatedBook)
                        }
                    }
                }
                // Track bookshelf scan completed
                AnalyticsManager.shared.trackBookshelfScanCompleted(bookCount: decodedBooks.count)
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
        loadFirstPage()
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
            var migrationCount = 0

            for document in documents {
                let data = document.data()
                if let coverURL = data["coverImageURL"] as? String,
                   coverURL.hasPrefix("http://") {

                    let httpsURL = coverURL.replacingOccurrences(of: "http://", with: "https://")
                    print("DEBUG BookViewModel: Migrating book \(document.documentID): \(coverURL) → \(httpsURL)")
                    migrationCount += 1

                    document.reference.updateData(["coverImageURL": httpsURL]) { error in
                        if let error = error {
                            print("DEBUG BookViewModel: ❌ Failed to migrate URL for book \(document.documentID): \(error.localizedDescription)")
                        } else {
                            print("DEBUG BookViewModel: ✅ Successfully migrated URL for book \(document.documentID)")
                        }
                    }
                }
            }

            print("DEBUG BookViewModel: Migration complete - processed \(migrationCount) HTTP URLs")
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
                                    // updatedBook.coverImageData = data // Commented out to reduce memory usage
                                    print("DEBUG BookViewModel: Downloaded cover image data for existing book (not storing in memory)")
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

        bookRef.updateData(["status": status.rawValue]) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to update book: \(error.localizedDescription)"
            } else {
                // Track book status change
                AnalyticsManager.shared.trackBookStatusChanged(bookId: book.id.uuidString, fromStatus: book.status, toStatus: status)
                self?.loadFirstPage()
            }
        }
    }

    func deleteBook(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.delete { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to delete book: \(error.localizedDescription)"
            } else {
                self?.loadFirstPage()
            }
        }
    }

    func updateBookTeaser(_ book: Book, teaser: String) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.updateData(["teaser": teaser]) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to update teaser: \(error.localizedDescription)"
            } else {
                // Update local book
                if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                    self.books[index].teaser = teaser
                }
                self?.loadFirstPage()
            }
        }
    }

    func updateBookAuthorBio(_ book: Book, authorBio: String) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.updateData(["authorBio": authorBio]) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to update author bio: \(error.localizedDescription)"
            } else {
                // Update local book
                if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                    self.books[index].authorBio = authorBio
                }
                self?.loadFirstPage()
            }
        }
    }

    func updateReadingProgress(_ book: Book, currentPage: Int) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        var updateData: [String: Any] = ["currentPage": currentPage]

        // If this is the first time reading, set the start date
        if book.dateStartedReading == nil {
            updateData["dateStartedReading"] = Timestamp(date: Date())
        }

        bookRef.updateData(updateData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to update reading progress: \(error.localizedDescription)"
            } else {
                // Update local book
                if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                    self.books[index].currentPage = currentPage
                    if self.books[index].dateStartedReading == nil {
                        self.books[index].dateStartedReading = Date()
                    }
                }
                // Track reading progress update
                let pagesRead = currentPage - (book.currentPage)
                if pagesRead > 0 {
                    AnalyticsManager.shared.trackReadingSessionCompleted(bookId: book.id.uuidString, sessionDuration: 0, pagesRead: pagesRead) // Duration not tracked here
                }
                self?.loadFirstPage()
            }
        }
    }

    func markBookAsComplete(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        let updateData: [String: Any] = [
            "status": BookStatus.read.rawValue,
            "dateFinishedReading": Timestamp(date: Date()),
            "currentPage": book.totalPages ?? book.currentPage
        ]

        bookRef.updateData(updateData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to mark book as complete: \(error.localizedDescription)"
            } else {
                // Update local book
                if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                    self.books[index].status = .read
                    self.books[index].dateFinishedReading = Date()
                    self.books[index].currentPage = book.totalPages ?? book.currentPage
                }
                // Track book completion
                let sessionDuration = book.dateStartedReading != nil ? Date().timeIntervalSince(book.dateStartedReading!) : 0
                let pagesRead = (book.totalPages ?? book.currentPage) - book.currentPage
                AnalyticsManager.shared.trackReadingSessionCompleted(bookId: book.id.uuidString, sessionDuration: sessionDuration, pagesRead: pagesRead)
                AnalyticsManager.shared.trackBookStatusChanged(bookId: book.id.uuidString, fromStatus: book.status, toStatus: .read)
                self?.loadFirstPage()
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
            print("DEBUG BookViewModel: setupFirestoreListener - user not authenticated (currentUserId is nil), setting books to empty")
            // Do not load from cache for unauthenticated users to prevent showing books from previous sessions
            self.books = []
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

                    // let coverData = data["coverImageData"] as? Data // Commented out to reduce memory usage - use URL instead
                    let coverData: Data? = nil
                    let coverImageURL = data["coverImageURL"] as? String
                    let teaser = data["teaser"] as? String
                    let authorBio = data["authorBio"] as? String
                    let pageCount = data["pageCount"] as? Int
                    let currentPage = data["currentPage"] as? Int ?? 0
                    let totalPages = data["totalPages"] as? Int

                    var dateStartedReading: Date? = nil
                    if let ts = data["dateStartedReading"] as? Timestamp {
                        dateStartedReading = ts.dateValue()
                    }

                    var dateFinishedReading: Date? = nil
                    if let ts = data["dateFinishedReading"] as? Timestamp {
                        dateFinishedReading = ts.dateValue()
                    }

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
                    book.currentPage = currentPage
                    book.totalPages = totalPages
                    book.dateStartedReading = dateStartedReading
                    book.dateFinishedReading = dateFinishedReading
                    return book
                }

                print("DEBUG BookViewModel: Successfully loaded \(loadedBooks.count) books from Firestore for user \(userId)")
                let libraryBooksCount = loadedBooks.filter { $0.status == .library }.count
                print("DEBUG BookViewModel: Library books count: \(libraryBooksCount)")

                // Memory logging for books
                let booksWithCoverData = loadedBooks.filter { $0.coverImageData != nil }
                let totalCoverDataSize = booksWithCoverData.reduce(0) { $0 + ($1.coverImageData?.count ?? 0) }
                let totalCoverDataSizeMB = Double(totalCoverDataSize) / 1024.0 / 1024.0
                print("DEBUG BookViewModel Memory: \(booksWithCoverData.count) books with cover data, total size: \(String(format: "%.2f", totalCoverDataSizeMB)) MB")

                self?.books = loadedBooks
                let totalImageSize = books.reduce(0) { $0 + ($1.coverImageData?.count ?? 0) }
                print("DEBUG BookViewModel: Total cover image data size: \(totalImageSize / 1024 / 1024) MB")
                // Sync book count with UsageTracker
                UsageTracker.shared.syncBookCount(loadedBooks.count)
                // Cache the books for offline use
                print("DEBUG BookViewModel: Caching \(loadedBooks.count) books for offline use")
                OfflineCache.shared.cacheBooks(loadedBooks)
 
                // Fetch missing covers only if not recently refreshed (e.g., within last 5 minutes)
                let lastCoverRefresh = UserDefaults.standard.double(forKey: "lastCoverRefreshTime")
                let now = Date().timeIntervalSince1970
                if now - lastCoverRefresh > 300 { // 5 minutes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.refreshBookCovers()
                        UserDefaults.standard.set(now, forKey: "lastCoverRefreshTime")
                    }
                } else {
                    print("DEBUG BookViewModel: Skipping cover refresh - recently done")
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
            "authorBio": book.authorBio as Any,
            "currentPage": book.currentPage,
            "totalPages": book.totalPages as Any,
            "dateStartedReading": book.dateStartedReading.map { Timestamp(date: $0) } as Any,
            "dateFinishedReading": book.dateFinishedReading.map { Timestamp(date: $0) } as Any
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

    // MARK: - Pagination

    private func loadFirstPage() {
        books = []
        lastDocument = nil
        isOfflineMode = false
        currentCachePage = 1
        isLoading = true
        errorMessage = nil
        totalBooks = OfflineCache.shared.getTotalBooks()
        hasMoreBooks = totalBooks > 0

        guard let userId = FirebaseConfig.shared.currentUserId else {
            print("DEBUG BookViewModel: loadFirstPage - user not authenticated, loading from cache")
            loadFromCachePaginated(page: 1, limit: 20)
            isLoading = false
            return
        }

        let query = db.collection("users").document(userId).collection("books")
            .order(by: "dateAdded", descending: true)
            .limit(to: 20)

        query.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("DEBUG BookViewModel: Firestore loadFirstPage error: \(error.localizedDescription), falling back to cache")
                    self?.isOfflineMode = true
                    self?.loadFromCachePaginated(page: 1, limit: 20)
                    ErrorHandler.shared.handle(error, context: "Loading Books")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("DEBUG BookViewModel: No documents in first page snapshot")
                    self?.hasMoreBooks = false
                    return
                }

                let loadedBooks = self?.decodeBooks(from: documents) ?? []
                self?.books = loadedBooks
                let totalImageSize = books.reduce(0) { $0 + ($1.coverImageData?.count ?? 0) }
                print("DEBUG BookViewModel: Total cover image data size: \(totalImageSize / 1024 / 1024) MB")
                self?.lastDocument = documents.last
                self?.hasMoreBooks = documents.count == 20
                print("DEBUG BookViewModel: Loaded first page: \(loadedBooks.count) books, hasMore: \(self?.hasMoreBooks ?? false)")

                // Sync cache in background if online
                DispatchQueue.global(qos: .background).async {
                    self?.syncCache()
                }
            }
        }
    }

    func loadNextPage() {
        guard hasMoreBooks && !isLoadingMore else { return }
        isLoadingMore = true

        if isOfflineMode {
            currentCachePage += 1
            loadFromCachePaginated(page: currentCachePage, limit: 20)
        } else {
            guard let userId = FirebaseConfig.shared.currentUserId, let last = lastDocument else { return }

            let query = db.collection("users").document(userId).collection("books")
                .order(by: "dateAdded", descending: true)
                .start(afterDocument: last)
                .limit(to: 20)

            query.getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoadingMore = false
                    if let error = error {
                        print("DEBUG BookViewModel: Firestore loadNextPage error: \(error.localizedDescription), falling back to cache")
                        self?.isOfflineMode = true
                        self?.currentCachePage += 1
                        self?.loadFromCachePaginated(page: self?.currentCachePage ?? 1, limit: 20)
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        self?.hasMoreBooks = false
                        return
                    }

                    let loadedBooks = self?.decodeBooks(from: documents) ?? []
                    self?.books.append(contentsOf: loadedBooks)
                    let totalImageSize = books.reduce(0) { $0 + ($1.coverImageData?.count ?? 0) }
                    print("DEBUG BookViewModel: Total cover image data size: \(totalImageSize / 1024 / 1024) MB")
                    self?.lastDocument = documents.last
                    self?.hasMoreBooks = documents.count == 20
                    print("DEBUG BookViewModel: Loaded next page: \(loadedBooks.count) books, hasMore: \(self?.hasMoreBooks ?? false)")
                }
            }
        }
    }

    private func loadFromCachePaginated(page: Int, limit: Int) {
        let loadedBooks = OfflineCache.shared.loadBooks(page: page, limit: limit) ?? []
        if page == 1 {
            books = loadedBooks
            lastDocument = nil
        } else {
            books.append(contentsOf: loadedBooks)
        }
        let totalImageSize = books.reduce(0) { $0 + ($1.coverImageData?.count ?? 0) }
        print("DEBUG BookViewModel: Total cover image data size: \(totalImageSize / 1024 / 1024) MB")
        totalBooks = OfflineCache.shared.getTotalBooks()
        hasMoreBooks = (page * limit) < totalBooks
        isLoadingMore = false
        print("DEBUG BookViewModel: Loaded cache page \(page): \(loadedBooks.count) books, total: \(totalBooks), hasMore: \(hasMoreBooks)")
    }

    private func decodeBooks(from documents: [QueryDocumentSnapshot]) -> [Book] {
        return documents.compactMap { document in
            let data = document.data()
            print("DEBUG BookViewModel: Processing document \(document.documentID), data keys: \(data.keys.sorted())")
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

            let coverData: Data? = nil // Compressed in Book init
            let coverImageURL = data["coverImageURL"] as? String
            let teaser = data["teaser"] as? String
            let authorBio = data["authorBio"] as? String
            let pageCount = data["pageCount"] as? Int
            let currentPage = data["currentPage"] as? Int ?? 0
            let totalPages = data["totalPages"] as? Int

            var dateStartedReading: Date? = nil
            if let ts = data["dateStartedReading"] as? Timestamp {
                dateStartedReading = ts.dateValue()
            }

            var dateFinishedReading: Date? = nil
            if let ts = data["dateFinishedReading"] as? Timestamp {
                dateFinishedReading = ts.dateValue()
            }

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
            book.currentPage = currentPage
            book.totalPages = totalPages
            book.dateStartedReading = dateStartedReading
            book.dateFinishedReading = dateFinishedReading
            return book
        }
    }

    private func syncCache() {
        guard let userId = FirebaseConfig.shared.currentUserId, !isOfflineMode else { return }

        db.collection("users").document(userId).collection("books").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("DEBUG BookViewModel: syncCache error: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            let loadedBooks = self?.decodeBooks(from: documents) ?? []
            OfflineCache.shared.cacheBooks(loadedBooks)
            print("DEBUG BookViewModel: Synced cache with \(loadedBooks.count) books")
            DispatchQueue.main.async {
                self?.totalBooks = loadedBooks.count
            }
        }
    }

    // MARK: - Recommendations

    func generateRecommendations(for currentBook: Book? = nil, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        // Check limits first
        if !UsageTracker.shared.canGetRecommendation() {
            let error = NSError(domain: "BookshelfScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recommendation limit reached. Upgrade to Premium for unlimited recommendations."])
            completion(.failure(error))
            return
        }

        let recommendationStartTime = Date()
        // Use Grok AI to generate personalized recommendations based on user's entire library
        grokService.generateRecommendations(userBooks: books, currentBook: currentBook) { result in
            let responseTime = Date().timeIntervalSince(recommendationStartTime)
            DispatchQueue.main.async {
                switch result {
                case .success(let recommendations):
                    AnalyticsManager.shared.trackAPICall(service: "Grok", endpoint: "generateRecommendations", success: true, responseTime: responseTime)
                    // Remove duplicates and limit to 20 recommendations
                    let uniqueRecommendations = self.removeDuplicates(from: recommendations)
                    let limitedRecommendations = Array(uniqueRecommendations.prefix(20))

                    // Cache recommendations for offline use
                    OfflineCache.shared.cacheRecommendations(limitedRecommendations)

                    // Track usage
                    UsageTracker.shared.incrementRecommendations()

                    // Trigger feature usage for surveys
                    NotificationCenter.default.post(
                        name: Notification.Name("FeatureUsed"),
                        object: nil,
                        userInfo: ["feature": "recommendations", "context": "successful_generation"]
                    )

                    completion(.success(limitedRecommendations))
                case .failure(let error):
                    AnalyticsManager.shared.trackAPICall(service: "Grok", endpoint: "generateRecommendations", success: false, responseTime: responseTime, errorMessage: error.localizedDescription)
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