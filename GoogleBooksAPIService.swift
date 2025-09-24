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
        print("DEBUG GoogleBooksAPIService: searchBooks called with query: '\(query)', maxResults: \(maxResults)")
        print("DEBUG GoogleBooksAPIService: Making request without API key (public access)")

        guard var urlComponents = URLComponents(string: baseURL) else {
            print("DEBUG GoogleBooksAPIService: Invalid base URL")
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
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
            print("DEBUG GoogleBooksAPIService: Received response, error: \(error?.localizedDescription ?? "none")")

            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG GoogleBooksAPIService: HTTP status code: \(httpResponse.statusCode)")
            }

            if let error = error {
                print("DEBUG GoogleBooksAPIService: Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("DEBUG GoogleBooksAPIService: No data received")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
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
                completion(.success(recommendations))
            } catch {
                print("DEBUG GoogleBooksAPIService: JSON decode error: \(error)")
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

        var query = ""
        if let isbn = isbn {
            query = "isbn:\(isbn)"
            print("DEBUG GoogleBooksAPIService: Using ISBN query: '\(query)'")
        } else if let title = title, let author = author {
            query = "intitle:\(title) inauthor:\(author)"
            print("DEBUG GoogleBooksAPIService: Using title+author query: '\(query)'")
        } else if let title = title {
            query = title
            print("DEBUG GoogleBooksAPIService: Using title-only query: '\(query)'")
        } else {
            print("DEBUG GoogleBooksAPIService: No valid search parameters provided")
            completion(.success(nil))
            return
        }

        searchBooks(query: query, maxResults: 1) { result in
            switch result {
            case .success(let recommendations):
                print("DEBUG GoogleBooksAPIService: fetchBookDetails got \(recommendations.count) results")
                if let first = recommendations.first {
                    print("DEBUG GoogleBooksAPIService: Returning book: \(first.title) by \(first.author)")
                } else {
                    print("DEBUG GoogleBooksAPIService: No results found")
                }
                completion(.success(recommendations.first))
            case .failure(let error):
                print("DEBUG GoogleBooksAPIService: fetchBookDetails search failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func fetchCoverURL(isbn: String?, title: String?, author: String?, completion: @escaping (Result<String?, Error>) -> Void) {
        print("DEBUG GoogleBooksAPIService: fetchCoverURL called with isbn: '\(isbn ?? "nil")', title: '\(title ?? "nil")', author: '\(author ?? "nil")'")
        fetchBookDetails(isbn: isbn, title: title, author: author) { result in
            switch result {
            case .success(let book):
                print("DEBUG GoogleBooksAPIService: fetchCoverURL success, thumbnailURL: '\(book?.thumbnailURL ?? "nil")'")
                completion(.success(book?.thumbnailURL))
            case .failure(let error):
                print("DEBUG GoogleBooksAPIService: fetchCoverURL failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
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