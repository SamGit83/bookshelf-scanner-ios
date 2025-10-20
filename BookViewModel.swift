import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
#if canImport(UIKit)
import UIKit
#endif

// Analytics integration
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// Rate limiting

class BookViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var scanFeedbackMessage: String?
    @Published var approachingLimitWarning: String?
    @Published var partialSuccessMessage: String?
    @Published var successMessage: String?
    @Published var totalBooks: Int = 0
    @Published var currentPage = 0
    @Published var hasMoreBooks = true
    @Published var isLoadingMore = false
    private var isScanning = false
    private var retryCount = 0
    private let maxRetries = 3

    private var authStateCancellable: AnyCancellable?

    private let apiService = GeminiAPIService()
    private let grokService = GrokAPIService()
    private let googleBooksService = GoogleBooksAPIService()
    private let db = FirebaseConfig.shared.db
    private let rateLimiter = RateLimiter()
    private var listener: ListenerRegistration?

    init() {
        setupAuthStateObserver()
        setupFirestoreListener()
        Task { await loadBooksPaginated(page: 0) }
    print("DEBUG BookViewModel: Task started")
    }

    private func setupAuthStateObserver() {
        authStateCancellable = Auth.auth().publisher(for: \.currentUser)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupFirestoreListener()
            }
    }

    func loadBooksPaginated(page: Int, limit: Int = 20) async {
        print("DEBUG BookViewModel: loadBooksPaginated called with page=\(page), limit=\(limit)")
        DispatchQueue.main.async {
            if page == 0 {
                self.isLoading = true
            } else {
                self.isLoadingMore = true
            }
            self.errorMessage = nil
        }

        if let loadedBooks = OfflineCache.shared.loadBooks(page: page, limit: limit) {
            // Cache success - existing logic
            DispatchQueue.main.async {
                if page == 0 {
                    self.books = loadedBooks
                    print("DEBUG BookViewModel: loadBooksPaginated loaded \(self.books.count) books")
                } else {
                    self.books.append(contentsOf: loadedBooks)
                }
                self.currentPage = page + 1
                self.totalBooks = loadedBooks.count
                self.hasMoreBooks = loadedBooks.count == limit
            }
        } else {
            // Cache failed - fallback to database
            print("DEBUG BookViewModel: Cache failed, falling back to database")
            if let dbBooks = await loadBooksFromFirestore(page: page, limit: limit) {
                DispatchQueue.main.async {
                    if page == 0 {
                        self.books = dbBooks
                    } else {
                        self.books.append(contentsOf: dbBooks)
                    }
                    self.currentPage = page + 1
                    // For now, assume we don't know total count without separate query
                    self.hasMoreBooks = dbBooks.count == limit
                }
                // Cache the database results
                OfflineCache.shared.cacheBooks(books)
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load books from cache or database"
                }
            }
        }

        DispatchQueue.main.async {
            self.isLoading = false
            self.isLoadingMore = false
        }
    }
    private func loadBooksFromFirestore(page: Int, limit: Int) async -> [Book]? {
        guard let userId = FirebaseConfig.shared.currentUserId else { return nil }
        
        do {
            let query = db.collection("users").document(userId).collection("books")
                .order(by: "dateAdded", descending: true)
                .limit(to: limit)
            
            let snapshot = try await query.getDocuments()
            
            let books = snapshot.documents.compactMap { document -> Book? in
                let data = document.data()
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

                let coverData: Data? = nil
                let coverImageURL = data["coverImageURL"] as? String
                let teaser = data["teaser"] as? String
                let authorBio = data["authorBio"] as? String
                let ageRating = data["ageRating"] as? String
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
                book.ageRating = ageRating
                book.pageCount = pageCount
                book.currentPage = currentPage
                book.totalPages = totalPages
                book.dateStartedReading = dateStartedReading
                book.dateFinishedReading = dateFinishedReading
                return book
            }
            
            return books
        } catch {
            print("DEBUG BookViewModel: Failed to load from Firestore: \(error.localizedDescription)")
            return nil
        }
    }

    func scanBookshelf(image: UIImage) {
        print("DEBUG BookViewModel: scanBookshelf START, timestamp: \(Date())")

        // Prevent multiple concurrent scans
        guard !isScanning else {
            print("DEBUG BookViewModel: Scan already in progress, ignoring")
            return
        }
        print("DEBUG BookViewModel: isScanning was false, proceeding with scan, timestamp: \(Date())")
        isScanning = true
        retryCount = 0

        // Check for valid API keys
        if !SecureConfig.shared.hasValidGeminiKey || !SecureConfig.shared.hasValidGoogleBooksKey {
            errorMessage = "AI-based features are temporarily unavailable due to high free API usage. You can still manually add books to your library, and other non-AI functionality remains available. AI features will be restored after a period of time."
            scanFeedbackMessage = nil
            isScanning = false
            return
        }

        // Check for approaching scan limit
        if UsageTracker.shared.isApproachingScanLimit() {
            let current = UsageTracker.shared.monthlyScans
            let limit = UsageTracker.shared.variantScanLimit
            approachingLimitWarning = "You're approaching your scan limit (\(current)/\(limit)). Consider upgrading soon."
        } else {
            approachingLimitWarning = nil
        }

        // Check usage limits
        if !UsageTracker.shared.canPerformScan() {
            errorMessage = "Scan limit reached. Upgrade to Premium for unlimited scans."
            scanFeedbackMessage = nil
            // Trigger upgrade prompt
            AnalyticsManager.shared.trackUpgradePromptShown(source: "scan_limit_hit", limitType: "scan")
            NotificationCenter.default.post(
                name: Notification.Name("UpgradePromptShown"),
                object: nil,
                userInfo: ["limit_type": "scan"]
            )
            isScanning = false
            return
        }

        // Check device-based rate limits
        if !rateLimiter.canMakeCall() {
            errorMessage = "API rate limit exceeded. Please try again later."
            scanFeedbackMessage = nil
            isScanning = false
            return
        }

        isLoading = true
        errorMessage = nil
        scanFeedbackMessage = "Scanning bookshelf..."
        partialSuccessMessage = nil
        successMessage = nil

        // Log image details for debugging
        print("DEBUG BookViewModel: Image details - size: \(image.size), scale: \(image.scale), orientation: \(image.imageOrientation.rawValue)")
        if let cgImage = image.cgImage {
            print("DEBUG BookViewModel: CGImage details - width: \(cgImage.width), height: \(cgImage.height), bitsPerComponent: \(cgImage.bitsPerComponent), bitsPerPixel: \(cgImage.bitsPerPixel)")
        }

        performScanWithRetry(image: image)
    }

    private func performScanWithRetry(image: UIImage) {
        let scanStartTime = Date()

        // Record API call for rate limiting
        rateLimiter.recordCall()

        print("DEBUG BookViewModel: Calling Gemini analyzeImage (attempt \(retryCount + 1)/\(maxRetries + 1)), timestamp: \(Date())")
        apiService.analyzeImage(image) { [weak self] result in
            guard let self = self else { return }
            let responseTime = Date().timeIntervalSince(scanStartTime)
            DispatchQueue.main.async {
                switch result {
                case .success(let responseText):
                    print("DEBUG BookViewModel: Gemini analysis success, response length: \(responseText.count), timestamp: \(Date())")
                    self.isLoading = false
                    self.scanFeedbackMessage = nil
                    UsageTracker.shared.incrementScans()
                    // Track API call success
                    AnalyticsManager.shared.trackAPICall(service: "Gemini", endpoint: "analyzeImage", success: true, responseTime: responseTime)

                    // Trigger feature usage for surveys
                    NotificationCenter.default.post(
                        name: Notification.Name("FeatureUsed"),
                        object: nil,
                        userInfo: ["feature": "scan", "context": "successful_scan"]
                    )

                    print("DEBUG BookViewModel: Calling parseAndAddBooks with response length \(responseText.count), timestamp: \(Date())")
                    self.parseAndAddBooks(from: responseText)
                    self.isScanning = false
                case .failure(let error):
                    print("DEBUG BookViewModel: Gemini analysis failed: \(error.localizedDescription), timestamp: \(Date())")
                    if let nsError = error as? NSError {
                        print("DEBUG BookViewModel: Full error details - domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo), shouldRetry: \(self.shouldRetry(error: error)), retryCount: \(self.retryCount)")
                    } else {
                        print("DEBUG BookViewModel: Error is not NSError, shouldRetry: \(self.shouldRetry(error: error)), retryCount: \(self.retryCount)")
                    }
                    ErrorHandler.shared.handle(error, context: "Image Analysis")
                    // Track API call failure
                    AnalyticsManager.shared.trackAPICall(service: "Gemini", endpoint: "analyzeImage", success: false, responseTime: responseTime, errorMessage: error.localizedDescription)

                    // Log additional error context for debugging
                    if let nsError = error as? NSError {
                        print("DEBUG BookViewModel: Error domain: \(nsError.domain), code: \(nsError.code)")
                        if nsError.domain == "APIError" {
                            print("DEBUG BookViewModel: This is an API error from Gemini service")
                        } else if nsError.domain == NSURLErrorDomain {
                            print("DEBUG BookViewModel: This is a network error - \(nsError.code)")
                        }
                    }

                    // Check if we should retry
                    if self.shouldRetry(error: error) && self.retryCount < self.maxRetries {
                        self.retryCount += 1
                        self.scanFeedbackMessage = "Scan failed. Retrying... (\(self.retryCount)/\(self.maxRetries))"
                        print("DEBUG BookViewModel: Retrying scan, attempt \(self.retryCount)/\(self.maxRetries)")
                        // Retry after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.performScanWithRetry(image: image)
                        }
                    } else {
                        // Max retries reached or non-retryable error
                        self.isLoading = false
                        self.scanFeedbackMessage = nil
                        self.errorMessage = "Scan failed after \(self.retryCount + 1) attempts. Please check your connection and try again."
                        print("DEBUG BookViewModel: Max retries reached or non-retryable error. Final error message set.")
                        self.isScanning = false
                    }
                }
            }
        }
    }

    private func shouldRetry(error: Error) -> Bool {
        let errorDescription = error.localizedDescription.lowercased()

        // Check for non-retryable API errors
        if let nsError = error as? NSError {
            // Gemini API auth/quota errors
            if nsError.domain == "APIError" {
                if let isAuthError = nsError.userInfo["isAuthError"] as? Bool, isAuthError {
                    print("DEBUG BookViewModel: Non-retryable auth error detected")
                    return false
                }
                if let isQuotaError = nsError.userInfo["isQuotaError"] as? Bool, isQuotaError {
                    print("DEBUG BookViewModel: Non-retryable quota error detected")
                    return false
                }
            }

            // Google Books parsing errors (DecodingError)
            if error is DecodingError {
                print("DEBUG BookViewModel: Non-retryable parsing error detected")
                return false
            }
        }

        // Retry on network-related errors
        return errorDescription.contains("network") ||
                errorDescription.contains("timeout") ||
                errorDescription.contains("connection") ||
                errorDescription.contains("unreachable") ||
                errorDescription.contains("offline")
    }

    private func normalizeAuthorName(_ author: String?) -> String {
        guard let author = author else { return "" }
        // Normalize author name: lowercase, trim whitespace, remove common prefixes/suffixes
        var normalized = author.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "^(by |written by |author: )", with: "", options: .regularExpression)
            .replacingOccurrences(of: "( jr\\.| sr\\.| iii| ii| iv)$", with: "", options: .regularExpression)
        // Remove extra whitespace and normalize spaces
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        print("DEBUG normalizeAuthorName: '\(author ?? "")' -> '\(normalized)'")
        return normalized
    }

    private func parseAndAddBooks(from responseText: String) {
        print("DEBUG BookViewModel: parseAndAddBooks START, responseText length: \(responseText.count), timestamp: \(Date())")
        print("DEBUG BookViewModel: isScanning during parse: \(isScanning)")
        errorMessage = nil // Clear any previous errors

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
                print("DEBUG BookViewModel: Successfully decoded \(decodedBooks.count) books, timestamp: \(Date())")

                // Handle empty results
                if decodedBooks.isEmpty {
                    print("DEBUG BookViewModel: No books detected in the image")
                    scanFeedbackMessage = "No books detected. Please ensure the bookshelf is clearly visible and try again."
                    return
                }

                // Check for duplicates based on title + author combination (case-insensitive) or ISBN
                let existingISBNs = Set(self.books.compactMap { $0.isbn })
                print("DEBUG BookViewModel: Existing books count: \(self.books.count), ISBNs count: \(existingISBNs.count)")

                // Filter out duplicates
                let nonDuplicateBooks = decodedBooks.filter { book in
                    let normalizedTitle = book.title?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let normalizedAuthor = normalizeAuthorName(book.author)
                    let isDuplicate = self.books.contains { existingBook in
                        let existingNormalizedTitle = existingBook.title?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        if existingNormalizedTitle == normalizedTitle {
                            let existingNormalizedAuthor = normalizeAuthorName(existingBook.author)
                            let isAuthorDuplicate = existingNormalizedAuthor.contains(normalizedAuthor) || normalizedAuthor.contains(existingNormalizedAuthor)
                            print("DEBUG Duplicate Check: Comparing authors for title '\(normalizedTitle)': existing '\(existingNormalizedAuthor)' vs new '\(normalizedAuthor)' -> \(isAuthorDuplicate)")
                            return isAuthorDuplicate
                        }
                        return false
                    }
                    let isISBNDuplicate = book.isbn != nil && existingISBNs.contains(book.isbn!)
                    print("DEBUG Duplicate Check: Checking new book '\(book.title ?? "")' by '\(book.author ?? "")' -> normalizedTitle '\(normalizedTitle)', normalizedAuthor '\(normalizedAuthor)', isDuplicate: \(isDuplicate), isISBNDuplicate: \(isISBNDuplicate)")
                    return !isDuplicate && !isISBNDuplicate
                }
                let duplicateCount = decodedBooks.count - nonDuplicateBooks.count
                print("DEBUG BookViewModel: Non-duplicate books: \(nonDuplicateBooks.count) out of \(decodedBooks.count), duplicates: \(duplicateCount)")

                // Check user tier and apply limit
                let isPremium = AuthService.shared.currentUser?.tier == .premium
                var booksToProcess: [Book]
                if isPremium {
                    booksToProcess = nonDuplicateBooks
                    // Set success message for premium users
                    if duplicateCount > 0 && !booksToProcess.isEmpty {
                        partialSuccessMessage = "Added \(booksToProcess.count) books to your library. \(duplicateCount) books were already in your collection."
                    } else if duplicateCount > 0 && booksToProcess.isEmpty {
                        partialSuccessMessage = "\(duplicateCount) books were already in your collection."
                    } else if booksToProcess.count > 0 {
                        successMessage = booksToProcess.count == 1 ? "Book added to your library." : "Added \(booksToProcess.count) books to your library."
                    } else {
                        partialSuccessMessage = nil
                    }
                } else {
                    let currentBookCount = self.books.count
                    let remainingCapacity = 25 - currentBookCount
                    if remainingCapacity <= 0 {
                        partialSuccessMessage = "You've reached your 25-book limit. Upgrade to Premium for unlimited books."
                        return
                    }
                    booksToProcess = Array(nonDuplicateBooks.prefix(remainingCapacity))
                    let skippedCount = nonDuplicateBooks.count - booksToProcess.count
                    // Set success message for free users
                    if skippedCount > 0 && duplicateCount > 0 {
                        partialSuccessMessage = "Added \(booksToProcess.count) books to your library. \(skippedCount) books were detected but couldn't be added due to your 25-book limit. \(duplicateCount) books were already in your collection. Consider upgrading for unlimited books."
                    } else if skippedCount > 0 {
                        partialSuccessMessage = "Added \(booksToProcess.count) books to your library. \(skippedCount) books were detected but couldn't be added due to your 25-book limit. Consider upgrading for unlimited books."
                    } else if duplicateCount > 0 {
                        partialSuccessMessage = "Added \(booksToProcess.count) books to your library. \(duplicateCount) books were already in your collection."
                    } else if booksToProcess.count > 0 {
                        successMessage = booksToProcess.count == 1 ? "Book added to your library." : "Added \(booksToProcess.count) books to your library."
                    } else {
                        partialSuccessMessage = nil
                    }
                }

                // Process the books to add
                for (index, book) in booksToProcess.enumerated() {
                    print("DEBUG BookViewModel: Processing new book #\(index + 1)/\(booksToProcess.count): \(book.title ?? "") by \(book.author ?? ""), timestamp: \(Date())")
                    let coverFetchStartTime = Date()
                    // Check rate limit before cover fetch
                    if self.rateLimiter.canMakeCall() {
                        self.rateLimiter.recordCall()
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
                                              // Analyze age rating before saving
                                              self?.analyzeAndSaveBook(updatedBook)
                                          }
                                      }.resume()
                                  } else {
                                      // Analyze age rating before saving
                                      self?.analyzeAndSaveBook(updatedBook)
                                  }
                              } else {
                                  print("DEBUG BookViewModel: No cover URL found for \(book.title ?? "")")
                                  // Analyze age rating before saving
                                  self?.analyzeAndSaveBook(updatedBook)
                              }
                          case .failure(let error):
                              AnalyticsManager.shared.trackAPICall(service: "GoogleBooks", endpoint: "fetchCoverURL", success: false, responseTime: coverResponseTime, errorMessage: error.localizedDescription)
                              print("DEBUG BookViewModel: Failed to fetch cover for \(book.title ?? ""): \(error.localizedDescription)")
                              // Analyze age rating before saving
                              self?.analyzeAndSaveBook(updatedBook)
                          }
                      }
                    } else {
                        // Rate limit exceeded, skip cover fetch and proceed to analyze
                        print("DEBUG BookViewModel: Rate limit exceeded, skipping cover fetch for \(book.title ?? "")")
                        self.analyzeAndSaveBook(book)
                    }
                 }
                 // Track bookshelf scan completed
                 AnalyticsManager.shared.trackBookshelfScanCompleted(bookCount: booksToProcess.count)
             } else {
                 print("DEBUG BookViewModel: Failed to convert jsonString to data")
                 errorMessage = "Failed to parse book data. Please try again."
                 scanFeedbackMessage = nil
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
             scanFeedbackMessage = nil
         }
         print("DEBUG BookViewModel: parseAndAddBooks END, timestamp: \(Date())")
     }

    func refreshData() {
        Task { await loadBooksPaginated(page: 0) }
    }

    func refreshBookCovers() {
        print("DEBUG BookViewModel: Manual cover refresh requested")
        migrateExistingHTTPURLs() // First migrate any HTTP URLs to HTTPS
        fetchMissingCoversForExistingBooks()
    }

    func migrateAgeRatings() {
        print("DEBUG BookViewModel: Manual age rating migration requested")
        let booksWithoutAgeRating = books.filter { $0.ageRating == nil || $0.ageRating == "" }
        print("DEBUG BookViewModel: Found \(booksWithoutAgeRating.count) books without age ratings for migration")
        if !booksWithoutAgeRating.isEmpty {
            processBooksForAgeRatings(Array(booksWithoutAgeRating), index: 0)
        }
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

        // Check rate limit before cover fetch
        if rateLimiter.canMakeCall() {
            rateLimiter.recordCall()
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
        } else {
            // Rate limit exceeded, skip cover fetch
            print("DEBUG BookViewModel: Rate limit exceeded, skipping cover fetch for existing book: \(book.title ?? "")")
            // Process next book
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.processBooksForCovers(booksToProcess, index: index + 1)
            }
        }
    }

    private func processBooksForAgeRatings(_ booksToProcess: [Book], index: Int) {
        guard index < booksToProcess.count else {
            print("DEBUG BookViewModel: Finished processing all books for age ratings")
            return
        }

        let book = booksToProcess[index]
        print("DEBUG BookViewModel: Analyzing age rating for existing book (\(index + 1)/\(booksToProcess.count)): \(book.title ?? "") by \(book.author ?? "")")

        // Check rate limit before age rating analysis
        if self.rateLimiter.canMakeCall() {
            self.rateLimiter.recordCall()
            grokService.analyzeAgeRating(title: book.title, author: book.author, description: book.teaser, genre: book.genre) { [weak self] result in
            var updatedBook = book
            switch result {
            case .success(let ageRating):
                print("DEBUG BookViewModel: Age rating analysis successful: \(ageRating) for \(book.title ?? "")")
                updatedBook.ageRating = ageRating
            case .failure(let error):
                print("DEBUG BookViewModel: Age rating analysis failed: \(error.localizedDescription) for \(book.title ?? ""), using Unknown")
                updatedBook.ageRating = "Unknown"
            }
            // Save to Firestore and update local array
            self?.saveBookToFirestore(updatedBook)
            self?.updateLocalBook(updatedBook)

            // Process next book after a delay to rate limit API calls
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1 second delay for rate limiting
                self?.processBooksForAgeRatings(booksToProcess, index: index + 1)
            }
        }
        } else {
            // Rate limit exceeded, save with unknown age rating
            print("DEBUG BookViewModel: Rate limit exceeded, saving existing book without age rating analysis: \(book.title ?? "")")
            var updatedBook = book
            updatedBook.ageRating = "Unknown"
            saveBookToFirestore(updatedBook)
            updateLocalBook(updatedBook)
            // Process next book
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.processBooksForAgeRatings(booksToProcess, index: index + 1)
            }
        }
    }

    func moveBook(_ book: Book, to status: BookStatus) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return
        }
    
        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)
    
        bookRef.updateData(["status": status.rawValue]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to update book: \(error.localizedDescription)"
                } else {
                    // Track book status change
                    AnalyticsManager.shared.trackBookStatusChanged(bookId: book.id.uuidString, fromStatus: book.status, toStatus: status)
                    Task { await self?.loadBooksPaginated(page: 0) }
                }
            }
        }
    }
    
    func markBookAsUnread(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return
        }
    
        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)
    
        var updateData: [String: Any] = [
            "status": BookStatus.toRead.rawValue,
            "currentPage": 0
        ]
    
        // Reset reading dates if they exist
        if book.dateStartedReading != nil {
            updateData["dateStartedReading"] = FieldValue.delete()
        }
        if book.dateFinishedReading != nil {
            updateData["dateFinishedReading"] = FieldValue.delete()
        }
    
        bookRef.updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to mark book as unread: \(error.localizedDescription)"
                } else {
                    // Track book status change
                    AnalyticsManager.shared.trackBookStatusChanged(bookId: book.id.uuidString, fromStatus: book.status, toStatus: .toRead)
                    Task { await self?.loadBooksPaginated(page: 0) }
                }
            }
        }
    }

    func deleteBook(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to delete book: \(error.localizedDescription)"
                } else {
                    // Remove from local array for immediate UI feedback
                    if let self = self, let index = self.books.firstIndex(where: { $0.id == book.id }) {
                        self.books.remove(at: index)
                    }
                    // Clear previous error messages and set success message
                    self?.errorMessage = nil
                    self?.successMessage = "Book '\(book.title ?? "Unknown")' has been deleted."
                }
            }
        }
    }

    func updateBookTeaser(_ book: Book, teaser: String) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.updateData(["teaser": teaser]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to update teaser: \(error.localizedDescription)"
                } else {
                    guard let self = self else { return }
                    // Update local book
                    if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                        self.books[index].teaser = teaser
                    }
                }
            }
        }
    }

    func updateBookAuthorBio(_ book: Book, authorBio: String) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        bookRef.updateData(["authorBio": authorBio]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to update author bio: \(error.localizedDescription)"
                } else {
                    guard let self = self else { return }
                    // Update local book
                    if let index = self.books.firstIndex(where: { $0.id == book.id }) {
                        self.books[index].authorBio = authorBio
                    }
                }
            }
        }
    }

    func updateReadingProgress(_ book: Book, currentPage: Int) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        var updateData: [String: Any] = ["currentPage": currentPage]

        // If this is the first time reading, set the start date
        if book.dateStartedReading == nil {
            updateData["dateStartedReading"] = Timestamp(date: Date())
        }

        bookRef.updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to update reading progress: \(error.localizedDescription)"
                } else {
                    guard let self = self else { return }
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
                }
            }
        }
    }

    func markBookAsComplete(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return
        }

        let bookRef = db.collection("users").document(userId).collection("books").document(book.id.uuidString)

        let updateData: [String: Any] = [
            "status": BookStatus.read.rawValue,
            "dateFinishedReading": Timestamp(date: Date()),
            "currentPage": book.totalPages ?? book.currentPage
        ]

        bookRef.updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to mark book as complete: \(error.localizedDescription)"
                } else {
                    guard let self = self else { return }
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
            print("DEBUG BookViewModel: setupFirestoreListener - user not authenticated (currentUserId is nil), setting books to empty")
            // Do not load from cache for unauthenticated users to prevent showing books from previous sessions
            self.books = []
            return
        }

        print("DEBUG BookViewModel: Setting up Firestore listener for userId=\(userId)")
        listener?.remove()

        listener = db.collection("users").document(userId).collection("books")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("DEBUG BookViewModel: Firestore listener error: \(error.localizedDescription), loading from cache")
                    // Try to load from cache if Firestore fails
                    if let cachedBooks = OfflineCache.shared.loadCachedBooks() {
                        DispatchQueue.main.async {
                            self.books = cachedBooks
                        }
                        print("DEBUG BookViewModel: Loaded \(cachedBooks.count) books from cache due to error")
                    } else {
                        print("DEBUG BookViewModel: No cached books, handling error")
                        ErrorHandler.shared.handle(error, context: "Loading Books")
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("DEBUG BookViewModel: No documents in snapshot")
                    DispatchQueue.main.async {
                        self.books = []
                    }
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
                    let ageRating = data["ageRating"] as? String
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
                    book.ageRating = ageRating
                    book.pageCount = pageCount
                    book.currentPage = currentPage
                    book.totalPages = totalPages
                    book.dateStartedReading = dateStartedReading
                    book.dateFinishedReading = dateFinishedReading
                    return book
                }

                print("DEBUG BookViewModel: Successfully loaded \(loadedBooks.count) books from Firestore for user \(userId)")
                print("DEBUG BookViewModel: Parsed \(books.count) books from listener")
                print("DEBUG BookViewModel: Listener received \(loadedBooks.count) books")
                let libraryBooksCount = loadedBooks.filter { $0.status == .library }.count
                print("DEBUG BookViewModel: Library books count: \(libraryBooksCount)")

                // Memory logging for books
                let booksWithCoverData = loadedBooks.filter { $0.coverImageData != nil }
                let totalCoverDataSize = booksWithCoverData.reduce(0) { $0 + ($1.coverImageData?.count ?? 0) }
                let totalCoverDataSizeMB = Double(totalCoverDataSize) / 1024.0 / 1024.0
                print("DEBUG BookViewModel Memory: \(booksWithCoverData.count) books with cover data, total size: \(String(format: "%.2f", totalCoverDataSizeMB)) MB")

                let totalImageSize = loadedBooks.reduce(0) { $0 + ($1.coverImageData?.count ?? 0) }
                print("DEBUG BookViewModel: Total cover image data size: \(totalImageSize / 1024 / 1024) MB")
                // Sync book count with UsageTracker
                UsageTracker.shared.syncBookCount(loadedBooks.count)
                print("DEBUG BookViewModel: Listener about to update books with \(loadedBooks.count) items, current count: \(self.books.count), timestamp: \(Date())")
                DispatchQueue.main.async {
                    self.books = loadedBooks
                    print("DEBUG BookViewModel: Listener updated books, new count: \(self.books.count), timestamp: \(Date())")
                }
                // Cache the books for offline use
                print("DEBUG BookViewModel: Caching \(loadedBooks.count) books for offline use")
                OfflineCache.shared.cacheBooks(loadedBooks)
                print("DEBUG BookViewModel: Checking if books empty after update: \(self.books.isEmpty), timestamp: \(Date())")
                if self.books.isEmpty == true {
                    Task { await self.loadBooksPaginated(page: 0) }
                }
 
                // Fetch missing covers only if not recently refreshed (e.g., within last 5 minutes)
                let lastCoverRefresh = UserDefaults.standard.double(forKey: "lastCoverRefreshTime")
                let now = Date().timeIntervalSince1970
                if now - lastCoverRefresh > 300 { // 5 minutes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.refreshBookCovers()
                        UserDefaults.standard.set(now, forKey: "lastCoverRefreshTime")
                    }
                } else {
                    print("DEBUG BookViewModel: Skipping cover refresh - recently done")
                }

                // Process age ratings for books without ratings
                let booksWithoutAgeRating = loadedBooks.filter { $0.ageRating == nil || $0.ageRating == "" }
                if !booksWithoutAgeRating.isEmpty {
                    print("DEBUG BookViewModel: Found \(booksWithoutAgeRating.count) books without age ratings, starting lazy analysis")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Delay to avoid overwhelming API
                        self.processBooksForAgeRatings(Array(booksWithoutAgeRating), index: 0)
                    }
                }
            }
    }

    func saveBookToFirestore(_ book: Book) {
        guard let userId = FirebaseConfig.shared.currentUserId else {
            print("DEBUG BookViewModel: saveBookToFirestore failed - user not authenticated")
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
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
            "ageRating": book.ageRating as Any,
            "currentPage": book.currentPage,
            "totalPages": book.totalPages as Any,
            "dateStartedReading": book.dateStartedReading.map { Timestamp(date: $0) } as Any,
            "dateFinishedReading": book.dateFinishedReading.map { Timestamp(date: $0) } as Any
        ]
        print("DEBUG BookViewModel: saveBookToFirestore data keys: \(data.keys.sorted())")
        print("DEBUG BookViewModel: saveBookToFirestore pageCount value: \(String(describing: book.pageCount))")
        bookRef.setData(data) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG BookViewModel: Failed to save book to Firestore: \(error.localizedDescription)")
                    self.errorMessage = "Failed to save book: \(error.localizedDescription)"
                } else {
                    print("DEBUG BookViewModel: Successfully saved book to Firestore")
                }
            }
        }
    }

    private func analyzeAndSaveBook(_ book: Book) {
        print("DEBUG BookViewModel: analyzeAndSaveBook START for book: \(book.title ?? "") by \(book.author ?? ""), timestamp: \(Date())")
        print("DEBUG BookViewModel: isScanning during analyzeAndSaveBook: \(isScanning)")
        // Check rate limit before age rating analysis
        if rateLimiter.canMakeCall() {
            rateLimiter.recordCall()
            grokService.analyzeAgeRating(title: book.title, author: book.author, description: book.teaser, genre: book.genre) { [weak self] result in
            var updatedBook = book
            switch result {
            case .success(let ageRating):
                print("DEBUG BookViewModel: Age rating analysis successful: \(ageRating) for \(book.title ?? "")")
                updatedBook.ageRating = ageRating
            case .failure(let error):
                print("DEBUG BookViewModel: Age rating analysis failed: \(error.localizedDescription) for \(book.title ?? ""), using Unknown")
                updatedBook.ageRating = "Unknown"
            }
            print("DEBUG BookViewModel: Saving book to Firestore: \(updatedBook.title ?? ""), timestamp: \(Date())")
            // Save to Firestore and update local array
            self?.saveBookToFirestore(updatedBook)
            self?.updateLocalBook(updatedBook)
            print("DEBUG BookViewModel: analyzeAndSaveBook END for book: \(book.title ?? ""), timestamp: \(Date())")
        }
        } else {
            // Rate limit exceeded, save with unknown age rating
            print("DEBUG BookViewModel: Rate limit exceeded, saving book without age rating analysis: \(book.title ?? "")")
            var updatedBook = book
            updatedBook.ageRating = "Unknown"
            saveBookToFirestore(updatedBook)
            updateLocalBook(updatedBook)
        }
    }

    private func updateLocalBook(_ updatedBook: Book) {
        DispatchQueue.main.async {
            if let index = self.books.firstIndex(where: { $0.id == updatedBook.id }) {
                self.books[index] = updatedBook
                print("DEBUG BookViewModel: Updated local book with cover image: \(updatedBook.title ?? "")")
            } else {
                self.books.append(updatedBook)
                print("DEBUG BookViewModel: Added new book to local array: \(updatedBook.title ?? "")")
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
        // Check for approaching recommendation limit
        if UsageTracker.shared.isApproachingRecommendationLimit() {
            let current = UsageTracker.shared.monthlyRecommendations
            let limit = UsageTracker.shared.variantRecommendationLimit
            approachingLimitWarning = "You're approaching your recommendation limit (\(current)/\(limit)). Consider upgrading soon."
        } else {
            approachingLimitWarning = nil
        }

        // Check limits first
        if !UsageTracker.shared.canGetRecommendation() {
            let error = NSError(domain: "BookshelfScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recommendation limit reached. Upgrade to Premium for unlimited recommendations."])
            completion(.failure(error))
            return
        }

        let recommendationStartTime = Date()
        // Check rate limit before generating recommendations
        if !rateLimiter.canMakeCall() {
            let error = NSError(domain: "BookshelfScanner", code: 2, userInfo: [NSLocalizedDescriptionKey: "API rate limit exceeded. Please try again later."])
            completion(.failure(error))
            return
        }
        rateLimiter.recordCall()

        // Get user's quiz responses for personalization
        let quizResponses = AuthService.shared.currentUser?.quizResponses

        // Use Grok AI to generate personalized recommendations based on user's entire library and quiz preferences
        grokService.generateRecommendations(userBooks: books, currentBook: currentBook, quizResponses: quizResponses) { result in
            let responseTime = Date().timeIntervalSince(recommendationStartTime)
            DispatchQueue.main.async {
                switch result {
                case .success(let recommendations):
                    AnalyticsManager.shared.trackAPICall(service: "Grok", endpoint: "generateRecommendations", success: true, responseTime: responseTime)
                    // Remove duplicates and limit to 20 recommendations
                    let uniqueRecommendations = self.removeDuplicates(from: recommendations)
                    let limitedRecommendations = Array(uniqueRecommendations.prefix(20))

                    // Fetch covers for recommendations
                    self.fetchCoversForRecommendations(limitedRecommendations) { enrichedRecommendations in
                        // Cache recommendations for offline use
                        OfflineCache.shared.cacheRecommendations(enrichedRecommendations)

                        // Track usage
                        UsageTracker.shared.incrementRecommendations()

                        // Trigger feature usage for surveys
                        NotificationCenter.default.post(
                            name: Notification.Name("FeatureUsed"),
                            object: nil,
                            userInfo: ["feature": "recommendations", "context": "successful_generation"]
                        )

                        completion(.success(enrichedRecommendations))
                    }
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

    private func fetchCoversForRecommendations(_ recommendations: [BookRecommendation], completion: @escaping ([BookRecommendation]) -> Void) {
        var enrichedRecommendations = recommendations
        var index = 0

        func fetchNext() {
            guard index < enrichedRecommendations.count else {
                completion(enrichedRecommendations)
                return
            }

            let recommendation = enrichedRecommendations[index]

            // Check rate limit before fetching cover
            if rateLimiter.canMakeCall() {
                rateLimiter.recordCall()
                googleBooksService.fetchCoverURL(isbn: nil, title: recommendation.title, author: recommendation.author) { [weak self] result in
                    switch result {
                    case .success(let url):
                        if let url = url {
                            enrichedRecommendations[index].thumbnailURL = url
                        }
                    case .failure(let error):
                        print("DEBUG BookViewModel: Failed to fetch cover for recommendation \(recommendation.title): \(error.localizedDescription)")
                    }
                    index += 1
                    // Add a small delay to avoid overwhelming the API
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        fetchNext()
                    }
                }
            } else {
                print("DEBUG BookViewModel: Rate limit exceeded, skipping cover fetch for recommendation: \(recommendation.title)")
                index += 1
                fetchNext()
            }
        }

        fetchNext()
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

    func addBookFromRecommendation(_ recommendation: BookRecommendation, completion: @escaping (Result<Void, Error>) -> Void) {
        print("DEBUG BookViewModel: Adding book from recommendation: \(recommendation.title) by \(recommendation.author)")

        // Check for duplicates
        let existingTitlesAndAuthors = Set(self.books.map {
            ($0.title ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) + "|" + ($0.author ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        })

        let normalizedTitle = recommendation.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAuthor = recommendation.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if existingTitlesAndAuthors.contains(normalizedTitle + "|" + normalizedAuthor) {
            print("DEBUG BookViewModel: Skipping duplicate book from recommendation: \(recommendation.title) by \(recommendation.author)")
            completion(.failure(NSError(domain: "DuplicateBook", code: 0, userInfo: [NSLocalizedDescriptionKey: "Book already exists in library"])))
            return
        }

        var newBook = Book(
            title: recommendation.title,
            author: recommendation.author,
            isbn: recommendation.id, // Using Google Books ID as ISBN fallback
            genre: recommendation.genre,
            status: .library,
            ageRating: recommendation.ageRating
        )

        // Map additional metadata from recommendation
        newBook.pageCount = recommendation.pageCount
        newBook.publicationYear = recommendation.publishedDate
        newBook.teaser = recommendation.description
        newBook.coverImageURL = recommendation.thumbnailURL

        // Check rate limit before age rating analysis
        if rateLimiter.canMakeCall() {
            rateLimiter.recordCall()
            // Analyze age rating
            grokService.analyzeAgeRating(title: recommendation.title, author: recommendation.author, description: recommendation.description, genre: recommendation.genre) { [weak self] result in
            var bookToSave = newBook
            switch result {
            case .success(let ageRating):
                print("DEBUG BookViewModel: Age rating analysis successful: \(ageRating) for \(recommendation.title)")
                bookToSave.ageRating = ageRating
            case .failure(let error):
                print("DEBUG BookViewModel: Age rating analysis failed: \(error.localizedDescription) for \(recommendation.title), using Unknown")
                bookToSave.ageRating = "Unknown"
            }
            // Save to Firestore and update local array
            self?.saveBookToFirestore(bookToSave)
            self?.updateLocalBook(bookToSave)
            self?.successMessage = "Book added to your library."
            completion(.success(()))
        }
        } else {
            // Rate limit exceeded, save with unknown age rating
            print("DEBUG BookViewModel: Rate limit exceeded, saving recommended book without age rating analysis: \(recommendation.title)")
            var bookToSave = newBook
            bookToSave.ageRating = "Unknown"
            saveBookToFirestore(bookToSave)
            updateLocalBook(bookToSave)
            successMessage = "Book added to your library."
            completion(.success(()))
        }
    }
}