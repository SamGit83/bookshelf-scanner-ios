import Foundation

class GoogleBooksAPIService {
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"

    private var apiKey: String {
        // Try environment variable first, fallback to SecureConfig
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"], !envKey.isEmpty {
            print("DEBUG GoogleBooksAPIService: Using Google Books API key from environment variable")
            return envKey
        }
        let configKey = SecureConfig.shared.googleBooksAPIKey
        print("DEBUG GoogleBooksAPIService: Using Google Books API key from SecureConfig: '\(configKey.prefix(10))...' (length: \(configKey.count))")
        return configKey
    }

    func searchBooks(query: String, maxResults: Int = 10, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        let startTime = Date()
        let traceId = PerformanceMonitoringService.shared.trackAPICall(service: "google_books", endpoint: "volumes", method: "GET")

        print("DEBUG GoogleBooksAPIService: searchBooks called with query: '\(query)', maxResults: \(maxResults)")
        print("DEBUG GoogleBooksAPIService: Making request without API key (public access)")

        guard var urlComponents = URLComponents(string: baseURL) else {
            print("DEBUG GoogleBooksAPIService: Invalid base URL")
            let urlError = NSError(domain: "InvalidURL", code: 0, userInfo: nil)

            PerformanceMonitoringService.shared.completeAPICall(
                traceId: traceId,
                success: false,
                responseTime: Date().timeIntervalSince(startTime),
                error: urlError
            )

            completion(.failure(urlError))
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: String(maxResults))
        ]

        guard let url = urlComponents.url else {
            print("DEBUG GoogleBooksAPIService: Failed to construct URL")
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        print("DEBUG GoogleBooksAPIService: Making request to: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            let dataSize = Int64(data?.count ?? 0)

            print("DEBUG GoogleBooksAPIService: Received response, error: \(error?.localizedDescription ?? "none")")

            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG GoogleBooksAPIService: HTTP status code: \(httpResponse.statusCode)")
            }

            if let error = error {
                print("DEBUG GoogleBooksAPIService: Network error: \(error.localizedDescription)")

                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: false,
                    responseTime: responseTime,
                    dataSize: dataSize,
                    error: error
                )

                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("DEBUG GoogleBooksAPIService: No data received")
                let noDataError = NSError(domain: "NoData", code: 0, userInfo: nil)

                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: false,
                    responseTime: responseTime,
                    error: noDataError
                )

                completion(.failure(noDataError))
                return
            }

            print("DEBUG GoogleBooksAPIService: Received \(data.count) bytes of data")

            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("DEBUG GoogleBooksAPIService: Raw response (first 1000 chars): \(responseString.prefix(1000))")
                // Also print if it contains imageLinks
                if responseString.contains("imageLinks") {
                    print("DEBUG GoogleBooksAPIService: Response contains 'imageLinks'")
                } else {
                    print("DEBUG GoogleBooksAPIService: Response does NOT contain 'imageLinks'")
                }
            }

            do {
                let googleBooksResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                print("DEBUG GoogleBooksAPIService: Successfully decoded response, items count: \(googleBooksResponse.items?.count ?? 0)")
                let recommendations = googleBooksResponse.items?.compactMap { self.convertToBookRecommendation($0) } ?? []
                print("DEBUG GoogleBooksAPIService: Converted to \(recommendations.count) recommendations")

                // Track successful API call (Google Books is free, so no cost tracking)
                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: true,
                    responseTime: responseTime,
                    dataSize: dataSize
                )

                completion(.success(recommendations))
            } catch {
                print("DEBUG GoogleBooksAPIService: JSON decode error: \(error)")

                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: false,
                    responseTime: responseTime,
                    dataSize: dataSize,
                    error: error
                )

                completion(.failure(error))
            }
        }.resume()
    }

    private func convertToBookRecommendation(_ volume: GoogleBookVolume) -> BookRecommendation? {
        print("DEBUG GoogleBooksAPIService: Converting volume with ID: \(volume.id)")
        print("DEBUG GoogleBooksAPIService: Volume info - title: '\(volume.volumeInfo.title ?? "nil")', authors: \(volume.volumeInfo.authors ?? [])")

        guard let title = volume.volumeInfo.title,
              let authors = volume.volumeInfo.authors else {
            print("DEBUG GoogleBooksAPIService: Missing title or authors, skipping")
            return nil
        }

        var thumbnailURL = volume.volumeInfo.imageLinks?.thumbnail
        print("DEBUG GoogleBooksAPIService: Original thumbnail URL: '\(thumbnailURL ?? "nil")'")
        print("DEBUG GoogleBooksAPIService: ImageLinks object exists: \(volume.volumeInfo.imageLinks != nil)")
        print("DEBUG GoogleBooksAPIService: Full imageLinks: \(String(describing: volume.volumeInfo.imageLinks))")

        // Convert HTTP URLs to HTTPS for better security and iOS compatibility
        if let originalURL = thumbnailURL, originalURL.hasPrefix("http://") {
            thumbnailURL = originalURL.replacingOccurrences(of: "http://", with: "https://")
            print("DEBUG GoogleBooksAPIService: Converted to HTTPS: '\(thumbnailURL ?? "nil")'")
        }

        print("DEBUG GoogleBooksAPIService: Final thumbnail URL: '\(thumbnailURL ?? "nil")'")

        let recommendation = BookRecommendation(
            id: volume.id,
            title: title,
            author: authors.joined(separator: ", "),
            genre: volume.volumeInfo.categories?.first ?? "Unknown",
            description: volume.volumeInfo.description,
            thumbnailURL: thumbnailURL,
            publishedDate: volume.volumeInfo.publishedDate,
            pageCount: volume.volumeInfo.pageCount
        )

        print("DEBUG GoogleBooksAPIService: Created recommendation: \(recommendation.title) by \(recommendation.author), thumbnail: \(recommendation.thumbnailURL ?? "nil")")
        return recommendation
    }

    func getRecommendationsBasedOnAuthor(_ author: String, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        let query = "inauthor:\(author)"
        searchBooks(query: query, maxResults: 5, completion: completion)
    }

    func getRecommendationsBasedOnGenre(_ genre: String, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        let query = "subject:\(genre)"
        searchBooks(query: query, maxResults: 5, completion: completion)
    }

    func getRecommendationsBasedOnTitle(_ title: String, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        // Extract keywords from title and search for similar books
        let keywords = title.components(separatedBy: " ").prefix(3).joined(separator: " ")
        let query = keywords
        searchBooks(query: query, maxResults: 5, completion: completion)
    }

    func fetchBookDetails(isbn: String?, title: String?, author: String?, completion: @escaping (Result<BookRecommendation?, Error>) -> Void) {
        print("DEBUG GoogleBooksAPIService: fetchBookDetails called with isbn: '\(isbn ?? "nil")', title: '\(title ?? "nil")', author: '\(author ?? "nil")'")

        // Clean and prepare search parameters
        let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: " ")
        let cleanAuthor = author?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: " ")
        let cleanISBN = isbn?.trimmingCharacters(in: .whitespacesAndNewlines)

        print("DEBUG GoogleBooksAPIService: Cleaned params - title: '\(cleanTitle ?? "nil")', author: '\(cleanAuthor ?? "nil")', isbn: '\(cleanISBN ?? "nil")'")

        // Try different search strategies in order of preference
        let searchStrategies = createSearchStrategies(isbn: cleanISBN, title: cleanTitle, author: cleanAuthor)

        trySearchStrategies(searchStrategies, completion: completion)
    }

    private func createSearchStrategies(isbn: String?, title: String?, author: String?) -> [(query: String, description: String)] {
        var strategies: [(query: String, description: String)] = []

        // Strategy 1: ISBN (most accurate)
        if let isbn = isbn, !isbn.isEmpty {
            strategies.append(("isbn:\(isbn)", "ISBN search"))
        }

        // Strategy 2: Title + Author (very accurate)
        if let title = title, !title.isEmpty, let author = author, !author.isEmpty {
            // Try exact title + author
            strategies.append(("intitle:\"\(title)\" inauthor:\"\(author)\"", "Exact title + author"))

            // Try partial author name (first word only)
            let authorFirstWord = author.components(separatedBy: " ").first ?? author
            if authorFirstWord != author {
                strategies.append(("intitle:\"\(title)\" inauthor:\(authorFirstWord)", "Title + author first name"))
            }

            // Try title + author without quotes
            strategies.append(("intitle:\(title) inauthor:\(author)", "Title + author (no quotes)"))
        }

        // Strategy 3: Title only (less accurate but better than nothing)
        if let title = title, !title.isEmpty {
            strategies.append(("intitle:\"\(title)\"", "Exact title only"))
            strategies.append((title, "Title keywords"))
        }

        // Strategy 4: Author + partial title (if we have both)
        if let author = author, !author.isEmpty, let title = title, !title.isEmpty {
            let titleWords = title.components(separatedBy: " ").prefix(2).joined(separator: " ")
            strategies.append(("inauthor:\"\(author)\" \(titleWords)", "Author + title keywords"))
        }

        return strategies
    }

    private func trySearchStrategies(_ strategies: [(query: String, description: String)], completion: @escaping (Result<BookRecommendation?, Error>) -> Void) {
        guard !strategies.isEmpty else {
            print("DEBUG GoogleBooksAPIService: No search strategies available")
            completion(.success(nil))
            return
        }

        let strategy = strategies.first!
        print("DEBUG GoogleBooksAPIService: Trying strategy: \(strategy.description) - query: '\(strategy.query)'")

        searchBooks(query: strategy.query, maxResults: 1) { [weak self] result in
            switch result {
            case .success(let recommendations):
                if let book = recommendations.first {
                    print("DEBUG GoogleBooksAPIService: ✅ Strategy '\(strategy.description)' found: \(book.title) by \(book.author)")
                    completion(.success(book))
                } else {
                    print("DEBUG GoogleBooksAPIService: ❌ Strategy '\(strategy.description)' found no results, trying next strategy")
                    // Try next strategy
                    let remainingStrategies = Array(strategies.dropFirst())
                    self?.trySearchStrategies(remainingStrategies, completion: completion)
                }
            case .failure(let error):
                print("DEBUG GoogleBooksAPIService: ❌ Strategy '\(strategy.description)' failed: \(error.localizedDescription), trying next strategy")
                // Try next strategy
                let remainingStrategies = Array(strategies.dropFirst())
                self?.trySearchStrategies(remainingStrategies, completion: completion)
            }
        }
    }

    func fetchCoverURL(isbn: String?, title: String?, author: String?, completion: @escaping (Result<String?, Error>) -> Void) {
        print("DEBUG GoogleBooksAPIService: fetchCoverURL called with isbn: '\(isbn ?? "nil")', title: '\(title ?? "nil")', author: '\(author ?? "nil")'")

        // Try Google Books first
        fetchBookDetails(isbn: isbn, title: title, author: author) { [weak self] result in
            switch result {
            case .success(let book):
                if let googleURL = book?.thumbnailURL {
                    print("DEBUG GoogleBooksAPIService: fetchCoverURL success from Google Books: '\(googleURL)'")
                    completion(.success(googleURL))
                    return
                }
                // Fall back to Open Library
                print("DEBUG GoogleBooksAPIService: No cover from Google Books, trying Open Library")
                self?.fetchOpenLibraryCover(isbn: isbn, title: title, author: author, completion: completion)
            case .failure(let error):
                print("DEBUG GoogleBooksAPIService: Google Books failed: \(error.localizedDescription), trying Open Library")
                // Fall back to Open Library
                self?.fetchOpenLibraryCover(isbn: isbn, title: title, author: author, completion: completion)
            }
        }
    }

    private func fetchOpenLibraryCover(isbn: String?, title: String?, author: String?, completion: @escaping (Result<String?, Error>) -> Void) {
        print("DEBUG GoogleBooksAPIService: fetchOpenLibraryCover called with isbn: '\(isbn ?? "nil")', title: '\(title ?? "nil")', author: '\(author ?? "nil")'")

        // Open Library API: https://openlibrary.org/dev/docs/api/covers
        // Format: https://covers.openlibrary.org/b/isbn/{ISBN}-L.jpg
        // Or: https://covers.openlibrary.org/b/olid/{OLID}-L.jpg
        // Or search by title: https://openlibrary.org/search.json?title={title}&author={author}

        if let isbn = isbn, !isbn.isEmpty {
            // Try ISBN first - most reliable
            let coverURL = "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg"
            print("DEBUG GoogleBooksAPIService: Trying Open Library ISBN cover: \(coverURL)")

            // Test if the URL actually works by making a HEAD request
            testImageURL(coverURL) { exists in
                if exists {
                    print("DEBUG GoogleBooksAPIService: Open Library ISBN cover exists: \(coverURL)")
                    completion(.success(coverURL))
                } else {
                    print("DEBUG GoogleBooksAPIService: Open Library ISBN cover not found, trying title search")
                    self.searchOpenLibraryByTitle(title: title, author: author, completion: completion)
                }
            }
            return
        }

        // Fall back to title search
        searchOpenLibraryByTitle(title: title, author: author, completion: completion)
    }

    private func searchOpenLibraryByTitle(title: String?, author: String?, completion: @escaping (Result<String?, Error>) -> Void) {
        guard let title = title, !title.isEmpty else {
            print("DEBUG GoogleBooksAPIService: No title provided for Open Library search")
            completion(.success(nil))
            return
        }

        // Try multiple Open Library search strategies
        let searchStrategies = createOpenLibraryStrategies(title: title, author: author)
        tryOpenLibraryStrategies(searchStrategies, completion: completion)
    }

    private func createOpenLibraryStrategies(title: String, author: String?) -> [(query: String, description: String)] {
        var strategies: [(query: String, description: String)] = []

        // Strategy 1: Title + Author (most specific)
        if let author = author, !author.isEmpty {
            strategies.append(("title:\(title) author:\(author)", "Title + Author"))
        }

        // Strategy 2: Title only
        strategies.append(("title:\(title)", "Title only"))

        // Strategy 3: Title keywords (first 3 words)
        let titleWords = title.components(separatedBy: " ").prefix(3).joined(separator: " ")
        if titleWords != title {
            strategies.append((titleWords, "Title keywords"))
        }

        // Strategy 4: Author + title keywords
        if let author = author, !author.isEmpty {
            let authorFirstWord = author.components(separatedBy: " ").first ?? author
            strategies.append(("author:\(authorFirstWord) \(titleWords)", "Author + title keywords"))
        }

        return strategies
    }

    private func tryOpenLibraryStrategies(_ strategies: [(query: String, description: String)], completion: @escaping (Result<String?, Error>) -> Void) {
        guard !strategies.isEmpty else {
            print("DEBUG GoogleBooksAPIService: No Open Library search strategies available")
            completion(.success(nil))
            return
        }

        let strategy = strategies.first!
        guard let encodedQuery = strategy.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?\(encodedQuery)&limit=5") else {
            print("DEBUG GoogleBooksAPIService: Failed to create Open Library search URL for strategy: \(strategy.description)")
            let remainingStrategies = Array(strategies.dropFirst())
            tryOpenLibraryStrategies(remainingStrategies, completion: completion)
            return
        }

        print("DEBUG GoogleBooksAPIService: Trying Open Library strategy: \(strategy.description) - URL: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("DEBUG GoogleBooksAPIService: Open Library strategy '\(strategy.description)' failed: \(error.localizedDescription)")
                let remainingStrategies = Array(strategies.dropFirst())
                self?.tryOpenLibraryStrategies(remainingStrategies, completion: completion)
                return
            }

            guard let data = data else {
                print("DEBUG GoogleBooksAPIService: No data from Open Library strategy: \(strategy.description)")
                let remainingStrategies = Array(strategies.dropFirst())
                self?.tryOpenLibraryStrategies(remainingStrategies, completion: completion)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let docs = json["docs"] as? [[String: Any]] {

                    print("DEBUG GoogleBooksAPIService: Open Library strategy '\(strategy.description)' found \(docs.count) results")

                    // Try each result to find one with a cover
                    for (index, doc) in docs.enumerated() {
                        if let olid = doc["key"] as? String {
                            let cleanOLID = olid.replacingOccurrences(of: "/works/", with: "").replacingOccurrences(of: "/books/", with: "")
                            let coverURL = "https://covers.openlibrary.org/b/olid/\(cleanOLID)-L.jpg"

                            print("DEBUG GoogleBooksAPIService: Testing cover for result \(index + 1): \(coverURL)")

                            // Test if this cover exists
                            self?.testImageURL(coverURL) { exists in
                                if exists {
                                    print("DEBUG GoogleBooksAPIService: ✅ Found working cover: \(coverURL)")
                                    completion(.success(coverURL))
                                } else if index == docs.count - 1 {
                                    // Last result, try next strategy
                                    print("DEBUG GoogleBooksAPIService: ❌ No covers found for strategy '\(strategy.description)', trying next")
                                    let remainingStrategies = Array(strategies.dropFirst())
                                    self?.tryOpenLibraryStrategies(remainingStrategies, completion: completion)
                                }
                            }
                            return // Wait for cover test result
                        }
                    }

                    // No OLID found in any result
                    print("DEBUG GoogleBooksAPIService: No OLID found in Open Library results for strategy: \(strategy.description)")
                    let remainingStrategies = Array(strategies.dropFirst())
                    self?.tryOpenLibraryStrategies(remainingStrategies, completion: completion)

                } else {
                    print("DEBUG GoogleBooksAPIService: Invalid Open Library response for strategy: \(strategy.description)")
                    let remainingStrategies = Array(strategies.dropFirst())
                    self?.tryOpenLibraryStrategies(remainingStrategies, completion: completion)
                }
            } catch {
                print("DEBUG GoogleBooksAPIService: Failed to parse Open Library response for strategy '\(strategy.description)': \(error.localizedDescription)")
                let remainingStrategies = Array(strategies.dropFirst())
                self?.tryOpenLibraryStrategies(remainingStrategies, completion: completion)
            }
        }.resume()
    }

    private func testImageURL(_ urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // Just check if URL exists without downloading

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}

// Google Books API Response Models
struct GoogleBooksResponse: Codable {
    let items: [GoogleBookVolume]?
}

struct GoogleBookVolume: Codable {
    let id: String
    let volumeInfo: GoogleBookVolumeInfo
}

struct GoogleBookVolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let categories: [String]?
    let description: String?
    let imageLinks: GoogleBookImageLinks?
    let publishedDate: String?
    let pageCount: Int?
}

struct GoogleBookImageLinks: Codable {
    let thumbnail: String?
}

// Recommendation Model
struct BookRecommendation: Identifiable, Codable {
    let id: String
    let title: String
    let author: String
    let genre: String
    let description: String?
    let thumbnailURL: String?
    let publishedDate: String?
    let pageCount: Int?

    var displayDescription: String {
        if let description = description, !description.isEmpty {
            return String(description.prefix(150)) + "..."
        }
        return "No description available"
    }
}