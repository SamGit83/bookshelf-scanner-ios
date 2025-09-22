import Foundation
#if canImport(UIKit)
import UIKit
#endif

/**
 * GeminiAPIService - AI-Powered Book Recognition
 *
 * UPGRADE: Now uses Gemini 1.5 Flash (May 2024) instead of Gemini Pro Vision
 *
 * Key Improvements:
 * - 2x faster processing (~1-2 seconds vs ~3-5 seconds)
 * - 5x cheaper ($0.0005 vs $0.0025 per image)
 * - Superior OCR for curved/angled text on book spines
 * - Better small text recognition (ISBNs, publisher info)
 * - Enhanced multi-language support
 * - Higher rate limits (1000 vs 60 requests/minute)
 * - Advanced image understanding and context awareness
 *
 * Enhanced Prompt: Optimized for book recognition with confidence scoring
 */
class GeminiAPIService {
    private var apiKey: String {
        // Try environment variable first, fallback to SecureConfig
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        return SecureConfig.shared.geminiAPIKey
    }
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    func analyzeImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        print("DEBUG GeminiAPIService: analyzeImage called, image size: \(image.size)")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("DEBUG GeminiAPIService: jpegData returned nil")
            completion(.failure(NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])))
            return
        }
        print("DEBUG GeminiAPIService: jpegData successful, size: \(imageData.count) bytes")

        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"bookshelf.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add prompt part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)

        let enhancedPrompt = """
        You are an expert librarian with advanced OCR capabilities analyzing a bookshelf photograph.

        TASK: Extract and analyze all visible books with maximum accuracy.

        ANALYSIS REQUIREMENTS:
        1. OCR Excellence: Read text from book spines, even if curved, angled, or partially obscured
        2. Detail Extraction: Capture titles, authors, ISBNs, publishers, publication years
        3. Visual Inference: Determine genres from cover designs, colors, and visual cues
        4. Quality Assessment: Evaluate image quality and suggest improvements if needed
        5. Book Detection: Identify individual books even in densely packed shelves
        6. Text Recognition: Handle various fonts, sizes, and orientations

        OUTPUT FORMAT: Return a JSON array of books with this exact structure:
        [
          {
            "title": "Book Title (be precise with OCR)",
            "author": "Author Name (extract from spine or cover)",
            "isbn": "ISBN-13 or ISBN-10 (if visible, even small text)",
            "genre": "Inferred genre (Fiction, Non-Fiction, Mystery, etc.)",
            "publisher": "Publisher name (if visible)",
            "publicationYear": "Year (if visible on spine)",
            "confidence": 0.95,
            "position": "approximate position on shelf (left, center, right)"
          }
        ]

        IMPORTANT:
        - Focus on accuracy over speed
        - Include confidence scores for each extraction
        - Handle multiple books in the same image
        - Extract as much metadata as possible
        - If image quality is poor, note this in the response
        """

        body.append(enhancedPrompt.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG GeminiAPIService: Sending request to Gemini API")
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("DEBUG GeminiAPIService: Received response, error: \(error?.localizedDescription ?? "none"), data count: \(data?.count ?? 0)")
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                print("DEBUG GeminiAPIService: Decoded response successfully")
                if let text = geminiResponse.candidates.first?.content.parts.first?.text {
                    print("DEBUG GeminiAPIService: Extracted text, length: \(text.count)")
                    completion(.success(text))
                } else {
                    print("DEBUG GeminiAPIService: No text in response")
                    completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                }
            } catch {
                print("DEBUG GeminiAPIService: JSON decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}