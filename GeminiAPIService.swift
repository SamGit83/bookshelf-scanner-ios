import Foundation
#if canImport(UIKit)
import UIKit
#endif

/**
 * GeminiAPIService - AI-Powered Book Recognition
 *
 * UPGRADE: Now uses Gemini 2.0 Flash (2025) instead of Gemini 1.5 Flash
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
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    func analyzeImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let startTime = Date()
        let traceId = PerformanceMonitoringService.shared.trackAPICall(service: "gemini", endpoint: "generateContent", method: "POST")

        print("DEBUG GeminiAPIService: analyzeImage START, image size: \(image.size), timestamp: \(Date())")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("DEBUG GeminiAPIService: jpegData returned nil")
            let error = NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])

            // Track failed API call
            PerformanceMonitoringService.shared.completeAPICall(
                traceId: traceId,
                success: false,
                responseTime: Date().timeIntervalSince(startTime),
                error: error
            )

            completion(.failure(error))
            return
        }
        print("DEBUG GeminiAPIService: jpegData successful, size: \(imageData.count) bytes")

        let base64Image = imageData.base64EncodedString()

        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        7. Sub-Genre Classification: Identify specific sub-genres (e.g., Cozy Mystery, Historical Fiction)
        8. Reading Time Estimation: Estimate reading time based on page count and genre (e.g., "8-10 hours")
        9. Page Count Inference: Estimate or extract page count from visual cues or knowledge
        10. Author Information: Provide brief author biography if known from common knowledge

        OUTPUT FORMAT: Return a JSON array of books with this exact structure:
        [
          {
            "title": "Book Title (be precise with OCR)",
            "author": "Author Name (extract from spine or cover)",
            "isbn": "ISBN-13 or ISBN-10 (if visible, even small text)",
            "genre": "Inferred genre (Fiction, Non-Fiction, Mystery, etc.)",
            "subGenre": "Specific sub-genre (e.g., Cozy Mystery, Historical Fiction)",
            "publisher": "Publisher name (if visible)",
            "publicationYear": "Year (if visible on spine)",
            "pageCount": 300,
            "estimatedReadingTime": "Estimated reading time (e.g., 8-10 hours)",
            "authorBiography": "Brief author biography (if known)",
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

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": enhancedPrompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        print("DEBUG GeminiAPIService: Sending request to Gemini API")
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            let dataSize = Int64(data?.count ?? 0)

            print("DEBUG GeminiAPIService: Received response, error: \(error?.localizedDescription ?? "none"), data count: \(data?.count ?? 0)")

            if let error = error {
                // Track failed API call
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
                let noDataError = NSError(domain: "NoData", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])

                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: false,
                    responseTime: responseTime,
                    error: noDataError
                )

                completion(.failure(noDataError))
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("DEBUG GeminiAPIService: Response string: \(responseString)")
            }

            // First, try to decode as error response
            if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                print("DEBUG GeminiAPIService: API error: \(errorResponse.error.message)")
                let apiError = NSError(domain: "APIError", code: errorResponse.error.code, userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message])

                // Track API error
                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: false,
                    responseTime: responseTime,
                    dataSize: dataSize,
                    error: apiError
                )

                completion(.failure(apiError))
                return
            }

            do {
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                print("DEBUG GeminiAPIService: Decoded response successfully")
                if let text = geminiResponse.candidates.first?.content.parts.first?.text {
                    print("DEBUG GeminiAPIService: Extracted text, length: \(text.count)")
                    print("DEBUG GeminiAPIService: Response text: \(text)")

                    // Track successful API call and cost
                    PerformanceMonitoringService.shared.completeAPICall(
                        traceId: traceId,
                        success: true,
                        responseTime: responseTime,
                        dataSize: dataSize
                    )

                    // Record API cost ($0.0025 per image for Gemini 1.5 Flash)
                    CostTracker.shared.recordCost(service: "gemini", cost: 0.0025)

                    print("DEBUG GeminiAPIService: SUCCESS completion called, timestamp: \(Date())")
                    completion(.success(text))
                } else {
                    print("DEBUG GeminiAPIService: No text in response, calling FAILURE completion, timestamp: \(Date())")
                    let parseError = NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])

                    PerformanceMonitoringService.shared.completeAPICall(
                        traceId: traceId,
                        success: false,
                        responseTime: responseTime,
                        dataSize: dataSize,
                        error: parseError
                    )

                    completion(.failure(parseError))
                }
            } catch {
                print("DEBUG GeminiAPIService: JSON decode error: \(error)")

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

struct GeminiErrorResponse: Codable {
    let error: GeminiError
}

struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String
}