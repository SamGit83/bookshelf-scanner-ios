import Foundation
import SwiftUI

/// Offline caching system for books and user data
class OfflineCache {
    static let shared = OfflineCache()

    private let cacheDirectory: URL
    private let booksCacheFile: URL
    private let recommendationsCacheFile: URL
    private let userDataCacheFile: URL

    private init() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("BookshelfCache")

        booksCacheFile = cacheDirectory.appendingPathComponent("books.json")
        recommendationsCacheFile = cacheDirectory.appendingPathComponent("recommendations.json")
        userDataCacheFile = cacheDirectory.appendingPathComponent("userData.json")

        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Books Caching

    func cacheBooks(_ books: [Book]) {
        do {
            let data = try JSONEncoder().encode(books)
            try data.write(to: booksCacheFile, options: .atomic)
        } catch {
            print("Failed to cache books: \(error)")
        }
    }

    func loadCachedBooks() -> [Book]? {
        do {
            let data = try Data(contentsOf: booksCacheFile)
            let books = try JSONDecoder().decode([Book].self, from: data)
            return books
        } catch {
            print("Failed to load cached books: \(error)")
            return nil
        }
    }

    func clearBooksCache() {
        try? FileManager.default.removeItem(at: booksCacheFile)
    }

    // MARK: - Recommendations Caching

    func cacheRecommendations(_ recommendations: [BookRecommendation]) {
        do {
            let data = try JSONEncoder().encode(recommendations)
            try data.write(to: recommendationsCacheFile, options: .atomic)
        } catch {
            print("Failed to cache recommendations: \(error)")
        }
    }

    func loadCachedRecommendations() -> [BookRecommendation]? {
        do {
            let data = try Data(contentsOf: recommendationsCacheFile)
            let recommendations = try JSONDecoder().decode([BookRecommendation].self, from: data)
            return recommendations
        } catch {
            print("Failed to load cached recommendations: \(error)")
            return nil
        }
    }

    func clearRecommendationsCache() {
        try? FileManager.default.removeItem(at: recommendationsCacheFile)
    }

    // MARK: - User Data Caching

    func cacheUserData(_ data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            try jsonData.write(to: userDataCacheFile, options: .atomic)
        } catch {
            print("Failed to cache user data: \(error)")
        }
    }

    func loadCachedUserData() -> [String: Any]? {
        do {
            let data = try Data(contentsOf: userDataCacheFile)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject as? [String: Any]
        } catch {
            print("Failed to load cached user data: \(error)")
            return nil
        }
    }

    func clearUserDataCache() {
        try? FileManager.default.removeItem(at: userDataCacheFile)
    }

    // MARK: - Cache Management

    func clearAllCache() {
        clearBooksCache()
        clearRecommendationsCache()
        clearUserDataCache()
    }

    func cacheSize() -> String {
        let cacheContents = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])

        let totalSize = cacheContents?.compactMap { url -> Int64? in
            try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        }.reduce(0, +) ?? 0

        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    func isCacheExpired(for file: URL, maxAge: TimeInterval = 24 * 60 * 60) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return true
        }

        return Date().timeIntervalSince(modificationDate) > maxAge
    }

    // MARK: - Network Status

    func isOnline() -> Bool {
        // Simple connectivity check - in a real app, you'd use NWPathMonitor
        return true // Placeholder - implement proper network checking
    }

    func shouldUseCache() -> Bool {
        return !isOnline()
    }
}

// MARK: - Cache Extensions

extension OfflineCache {
    func cacheBookImage(_ image: UIImage, for bookId: String) {
        let imageCacheDirectory = cacheDirectory.appendingPathComponent("images")
        if !FileManager.default.fileExists(atPath: imageCacheDirectory.path) {
            try? FileManager.default.createDirectory(at: imageCacheDirectory, withIntermediateDirectories: true)
        }

        let imageFile = imageCacheDirectory.appendingPathComponent("\(bookId).jpg")

        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: imageFile, options: .atomic)
        }
    }

    func loadCachedBookImage(for bookId: String) -> UIImage? {
        let imageFile = cacheDirectory.appendingPathComponent("images").appendingPathComponent("\(bookId).jpg")

        if let data = try? Data(contentsOf: imageFile) {
            return UIImage(data: data)
        }

        return nil
    }

    func clearImageCache() {
        let imageCacheDirectory = cacheDirectory.appendingPathComponent("images")
        try? FileManager.default.removeItem(at: imageCacheDirectory)
    }
}

// MARK: - Observable Cache Status

class CacheManager: ObservableObject {
    @Published var isOnline = true
    @Published var cacheSize = "0 KB"
    @Published var lastSyncDate: Date?

    static let shared = CacheManager()

    private init() {
        updateCacheSize()
        // TODO: Implement network monitoring
    }

    func updateCacheSize() {
        cacheSize = OfflineCache.shared.cacheSize()
    }

    func clearAllCache() {
        OfflineCache.shared.clearAllCache()
        updateCacheSize()
    }

    func syncData() {
        // TODO: Implement data synchronization
        lastSyncDate = Date()
    }
}