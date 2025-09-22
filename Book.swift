import Foundation

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

    init(title: String?, author: String?, isbn: String? = nil, genre: String? = nil, status: BookStatus = .library, coverImageData: Data? = nil, coverImageURL: String? = nil) {
        self.title = title ?? ""
        self.author = author ?? ""
        self.isbn = isbn
        self.genre = genre
        self.status = status
        self.dateAdded = Date()
        self.coverImageData = coverImageData
        self.coverImageURL = coverImageURL
    }

    // Custom decoder to handle missing 'id', 'status', and 'dateAdded' from Gemini API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate UUID if 'id' is missing
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()

        print("DEBUG Book decoder: Attempting to decode title")
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        print("DEBUG Book decoder: Successfully decoded title: \(self.title)")
        print("DEBUG Book decoder: Attempting to decode author")
        self.author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
        print("DEBUG Book decoder: Successfully decoded author: \(self.author)")
        self.isbn = try container.decodeIfPresent(String.self, forKey: .isbn)
        self.genre = try container.decodeIfPresent(String.self, forKey: .genre)
        self.subGenre = try container.decodeIfPresent(String.self, forKey: .subGenre)
        print("DEBUG Book decoder: subGenre: \(String(describing: self.subGenre))")
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        self.publicationYear = try container.decodeIfPresent(String.self, forKey: .publicationYear)
        self.pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount)
        self.estimatedReadingTime = try container.decodeIfPresent(String.self, forKey: .estimatedReadingTime)
        print("DEBUG Book decoder: estimatedReadingTime: \(String(describing: self.estimatedReadingTime))")
        self.authorBiography = try container.decodeIfPresent(String.self, forKey: .authorBiography)
        self.teaser = try container.decodeIfPresent(String.self, forKey: .teaser)
        self.authorBio = try container.decodeIfPresent(String.self, forKey: .authorBio)
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.position = try container.decodeIfPresent(String.self, forKey: .position)

        // Default to .library if 'status' is missing
        self.status = try container.decodeIfPresent(BookStatus.self, forKey: .status) ?? .library

        // Default to current date if 'dateAdded' is missing
        self.dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()

        self.coverImageData = try container.decodeIfPresent(Data.self, forKey: .coverImageData)
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