import Foundation

class GoogleBooksAPIService {
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"

    private var apiKey: String {
        // Try environment variable first, fallback to SecureConfig
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        return SecureConfig.shared.googleBooksAPIKey
    }

    func searchBooks(query: String, maxResults: Int = 10, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }

            do {
                let googleBooksResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                let recommendations = googleBooksResponse.items?.compactMap { self.convertToBookRecommendation($0) } ?? []
                completion(.success(recommendations))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func convertToBookRecommendation(_ volume: GoogleBookVolume) -> BookRecommendation? {
        guard let title = volume.volumeInfo.title,
              let authors = volume.volumeInfo.authors else {
            return nil
        }

        return BookRecommendation(
            id: volume.id,
            title: title,
            author: authors.joined(separator: ", "),
            genre: volume.volumeInfo.categories?.first ?? "Unknown",
            description: volume.volumeInfo.description,
            thumbnailURL: volume.volumeInfo.imageLinks?.thumbnail,
            publishedDate: volume.volumeInfo.publishedDate,
            pageCount: volume.volumeInfo.pageCount
        )
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
        var query = ""
        if let isbn = isbn {
            query = "isbn:\(isbn)"
        } else if let title = title, let author = author {
            query = "intitle:\(title) inauthor:\(author)"
        } else if let title = title {
            query = title
        } else {
            completion(.success(nil))
            return
        }

        searchBooks(query: query, maxResults: 1) { result in
            switch result {
            case .success(let recommendations):
                completion(.success(recommendations.first))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchCoverURL(isbn: String?, title: String?, author: String?, completion: @escaping (Result<String?, Error>) -> Void) {
        fetchBookDetails(isbn: isbn, title: title, author: author) { result in
            switch result {
            case .success(let book):
                completion(.success(book?.thumbnailURL))
            case .failure(let error):
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