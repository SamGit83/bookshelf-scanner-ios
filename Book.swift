import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct Book: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String?
    var author: String?
    var isbn: String?
    var genre: String?
    var subGenre: String?
    var publisher: String?
    var publicationYear: String?
    var pageCount: Int?
    var estimatedReadingTime: String?
    var authorBiography: String?
    var teaser: String?
    var authorBio: String?
    var confidence: Double?
    var position: String?
    var ageRating: String?
    var status: BookStatus
    var dateAdded: Date
    var coverImageData: Data?
    var coverImageURL: String?

    // Reading Progress
    var totalPages: Int?
    var currentPage: Int = 0
    var readingGoal: ReadingGoal?
    var readingSessions: [ReadingSession] = []
    var dateStartedReading: Date?
    var dateFinishedReading: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, author, isbn, genre, subGenre, publisher, publicationYear, pageCount, estimatedReadingTime, authorBiography, teaser, authorBio, confidence, position, ageRating, status, dateAdded, coverImageData, coverImageURL, totalPages, currentPage, readingGoal, readingSessions, dateStartedReading, dateFinishedReading
    }

    init(title: String?, author: String?, isbn: String? = nil, genre: String? = nil, status: BookStatus = .toRead, coverImageData: Data? = nil, coverImageURL: String? = nil, ageRating: String? = nil) {
        self.title = title ?? ""
        self.author = author ?? ""
        self.isbn = isbn
        self.genre = genre
        self.status = status
        self.dateAdded = Date()
        if let data = coverImageData {
            if let image = UIImage(data: data), let compressed = image.jpegData(compressionQuality: 0.5) {
                self.coverImageData = compressed
            } else {
                self.coverImageData = data
            }
        } else {
            self.coverImageData = nil
        }
        self.coverImageURL = coverImageURL
        self.ageRating = ageRating
    }

    // Custom decoder to handle missing 'id', 'status', and 'dateAdded' from Gemini API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate UUID if 'id' is missing
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()

        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
        self.isbn = try container.decodeIfPresent(String.self, forKey: .isbn)
        self.genre = try container.decodeIfPresent(String.self, forKey: .genre)
        if let rawSubGenre = try container.decodeIfPresent(String.self, forKey: .subGenre) {
            if let range = rawSubGenre.range(of: " (") {
                self.subGenre = String(rawSubGenre[..<range.lowerBound])
            } else {
                self.subGenre = rawSubGenre
            }
        } else {
            self.subGenre = nil
        }
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        self.publicationYear = try container.decodeIfPresent(String.self, forKey: .publicationYear)
        self.pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount)
        self.estimatedReadingTime = try container.decodeIfPresent(String.self, forKey: .estimatedReadingTime)
        self.authorBiography = try container.decodeIfPresent(String.self, forKey: .authorBiography)
        self.teaser = try container.decodeIfPresent(String.self, forKey: .teaser)
        self.authorBio = try container.decodeIfPresent(String.self, forKey: .authorBio)
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.position = try container.decodeIfPresent(String.self, forKey: .position)
        self.ageRating = try container.decodeIfPresent(String.self, forKey: .ageRating)

        // Default to .toRead if 'status' is missing
        self.status = try container.decodeIfPresent(BookStatus.self, forKey: .status) ?? .toRead

        // Default to current date if 'dateAdded' is missing
        self.dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()

        if let rawData = try? container.decodeIfPresent(Data.self, forKey: .coverImageData) {
            if let image = UIImage(data: rawData), let compressed = image.jpegData(compressionQuality: 0.5) {
                self.coverImageData = compressed
            } else {
                self.coverImageData = rawData
            }
        } else {
            self.coverImageData = nil
        }
        self.coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)

        // Reading Progress - use defaults
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
        self.currentPage = try container.decodeIfPresent(Int.self, forKey: .currentPage) ?? 0
        self.readingGoal = try container.decodeIfPresent(ReadingGoal.self, forKey: .readingGoal)
        self.readingSessions = try container.decodeIfPresent([ReadingSession].self, forKey: .readingSessions) ?? []
        self.dateStartedReading = try container.decodeIfPresent(Date.self, forKey: .dateStartedReading)
        self.dateFinishedReading = try container.decodeIfPresent(Date.self, forKey: .dateFinishedReading)
    }
}

enum BookStatus: String, Codable, CaseIterable {
    case toRead = "To Read"
    case reading = "Reading"
    case read = "Read"
    
    // Legacy support for existing data
    case library = "Library"
    case currentlyReading = "Currently Reading"
}

// Reading Progress Models
struct ReadingGoal: Codable, Hashable {
    var targetPages: Int
    var deadline: Date
    var isCompleted: Bool = false
}

struct ReadingSession: Codable, Hashable, Identifiable {
    var id = UUID()
    var date: Date
    var pagesRead: Int
    var duration: TimeInterval // in minutes
    var notes: String?
}