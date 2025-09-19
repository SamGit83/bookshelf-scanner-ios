import Foundation

struct Book: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var author: String
    var isbn: String?
    var genre: String?
    var publisher: String?
    var publicationYear: String?
    var confidence: Double?
    var position: String?
    var status: BookStatus
    var dateAdded: Date
    var coverImageData: Data?

    // Reading Progress
    var totalPages: Int?
    var currentPage: Int = 0
    var readingGoal: ReadingGoal?
    var readingSessions: [ReadingSession] = []
    var dateStartedReading: Date?
    var dateFinishedReading: Date?

    init(title: String, author: String, isbn: String? = nil, genre: String? = nil, status: BookStatus = .library, coverImageData: Data? = nil) {
        self.title = title
        self.author = author
        self.isbn = isbn
        self.genre = genre
        self.status = status
        self.dateAdded = Date()
        self.coverImageData = coverImageData
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