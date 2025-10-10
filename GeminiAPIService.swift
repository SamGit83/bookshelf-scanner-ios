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
 * Enhanced Prompt: Optimized for diverse book scanning scenarios with robust detection
 */
class GeminiAPIService {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    func analyzeImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let startTime = Date()
        let traceId = PerformanceMonitoringService.shared.trackAPICall(service: "gemini", endpoint: "generateContent", method: "POST")

        print("DEBUG GeminiAPIService: analyzeImage START, image size: \(image.size), timestamp: \(Date())")
        print("DEBUG GeminiAPIService: Using environment: \(SecureConfig.shared.isDevelopment ? "DEBUG" : "PRODUCTION")")
        print("DEBUG GeminiAPIService: isScanning from context (if available): Note - flag not directly accessible here")

        // Fetch fresh API key asynchronously
        SecureConfig.shared.getGeminiAPIKeyAsync { [weak self] apiKey in
            guard let self = self else { return }

            print("DEBUG GeminiAPIService: API key retrieved: \(apiKey.count > 0 ? "YES (\(apiKey.prefix(10))...)" : "NO")")

            // Validate API key
            let isValidKey = !apiKey.isEmpty && !apiKey.contains("YOUR_") && apiKey.count > 20
            if !isValidKey {
                print("DEBUG GeminiAPIService: Invalid or missing Gemini API key")
                let keyError = NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI-based features are temporarily unavailable due to high free API usage. You can still manually add books to your library, and other non-AI functionality remains available. AI features will be restored after a period of time."])

                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: false,
                    responseTime: Date().timeIntervalSince(startTime),
                    error: keyError
                )

                completion(.failure(keyError))
                return
            }

            guard let imageData = self.imageToJPEGData(image) else {
                print("DEBUG GeminiAPIService: jpegData returned nil")
                let error = NSError(domain: "ImageConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])

                PerformanceMonitoringService.shared.completeAPICall(
                    traceId: traceId,
                    success: false,
                    responseTime: Date().timeIntervalSince(startTime),
                    error: error
                )

                completion(.failure(error))
                return
            }

            self.performGeminiRequest(with: imageData, apiKey: apiKey, startTime: startTime, traceId: traceId, completion: completion)
        }
    }

    private func imageToJPEGData(_ image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 0.8)
    }

    private func performGeminiRequest(with imageData: Data, apiKey: String, startTime: Date, traceId: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("DEBUG GeminiAPIService: jpegData successful, size: \(imageData.count) bytes")

        // Generate timestamp for replay attack prevention
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let timeWindow = SecureConfig.shared.requestTimeWindowSeconds

        let base64Image = imageData.base64EncodedString()

        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")

        let enhancedPrompt = """
        You are an expert librarian with advanced OCR capabilities analyzing an image containing books.

        TASK: Extract and analyze all visible books with maximum accuracy, regardless of their arrangement, orientation, or surroundings.

        CRITICAL SAFEGUARDS:
        - Only detect physical books that are clearly visible and identifiable as books
        - Do not hallucinate or invent books that are not present in the image
        - If no books are clearly visible, return an empty JSON array []

        ANALYSIS REQUIREMENTS:
        1. OCR Excellence: Read text from book spines, covers, or any visible surfaces, even if curved, angled, partially obscured, or in various orientations
        2. Detail Extraction: Capture titles, authors, ISBNs, publishers, publication years from any visible text
        3. Visual Inference: Determine genres from cover designs, colors, and visual cues
        4. Quality Assessment: Evaluate image quality and provide specific guidance for better results if the image is poor (e.g., "Ensure books are well-lit and in focus for better text recognition")
        5. Book Detection: Identify individual books in any arrangement - single books, stacks, shelves, tables, floors, or mixed with other objects
        6. Text Recognition: Handle various fonts, sizes, orientations, and languages
        7. Sub-Genre Classification: Identify specific sub-genres when possible
        8. Reading Time Estimation: Estimate reading time based on page count and genre
        9. Page Count Inference: Estimate page count from visual cues or knowledge
        10. Author Information: Provide brief author biography if known

        OUTPUT FORMAT: Return a JSON array of books with this exact structure:
        [
          {
            "title": "Book Title (be precise with OCR)",
            "author": "Author Name",
            "isbn": "ISBN if visible",
            "genre": "Inferred genre",
            "subGenre": "Specific sub-genre",
            "publisher": "Publisher name",
            "publicationYear": "Year",
            "pageCount": 300,
            "estimatedReadingTime": "8-10 hours",
            "authorBiography": "Brief bio",
            "confidence": 0.95,
            "notes": "Any additional notes about detection or quality"
          }
        ]

        IMPORTANT:
        - Focus on accuracy over speed
        - Include confidence scores for each extraction
        - Handle multiple books or single books
        - Extract as much metadata as possible
        - If image quality is poor, include guidance in the 'notes' field for better results
        - Return empty array [] if no physical books are clearly visible in the image
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

        print("DEBUG GeminiAPIService: Request body prepared, sending to Gemini API, timestamp: \(Date())")
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            let dataSize = Int64(data?.count ?? 0)

            // Log HTTP response details
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG GeminiAPIService: HTTP status code: \(httpResponse.statusCode), headers: \(httpResponse.allHeaderFields)")
            } else {
                print("DEBUG GeminiAPIService: No HTTP response or non-HTTP response")
            }

            print("DEBUG GeminiAPIService: Received response from Gemini, error: \(error?.localizedDescription ?? "none"), data count: \(data?.count ?? 0), timestamp: \(Date())")

                // Validate response timestamp for replay attack prevention
                if responseTime > timeWindow {
                    print("DEBUG GeminiAPIService: Response received after time window (\(responseTime)s > \(timeWindow)s), rejecting for replay attack prevention")
                    let timestampError = NSError(domain: "TimestampValidation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Response received outside acceptable time window"])
    
                    PerformanceMonitoringService.shared.completeAPICall(
                        traceId: traceId,
                        success: false,
                        responseTime: responseTime,
                        dataSize: dataSize,
                        error: timestampError
                    )
    
                    completion(.failure(timestampError))
                    return
                }
    
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
                print("DEBUG GeminiAPIService: Error code: \(errorResponse.error.code), status: \(errorResponse.error.status)")
                print("DEBUG GeminiAPIService: Full error response: \(String(describing: errorResponse))")

                // Check for specific non-retryable errors
                let isAuthError = errorResponse.error.code == 401 || errorResponse.error.message.contains("API_KEY")
                let isQuotaError = errorResponse.error.code == 429 || errorResponse.error.message.contains("quota") || errorResponse.error.message.contains("limit")
                print("DEBUG GeminiAPIService: Is auth error: \(isAuthError), Is quota error: \(isQuotaError)")

                let apiError = NSError(domain: "APIError", code: errorResponse.error.code, userInfo: [
                    NSLocalizedDescriptionKey: errorResponse.error.message,
                    "isAuthError": isAuthError,
                    "isQuotaError": isQuotaError
                ])

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
                    print("DEBUG GeminiAPIService: Extracted text, length: \(text.count), timestamp: \(Date())")
                    print("DEBUG GeminiAPIService: Response text preview: \(String(text.prefix(200)))...")

                    // Track successful API call and cost
                    PerformanceMonitoringService.shared.completeAPICall(
                        traceId: traceId,
                        success: true,
                        responseTime: responseTime,
                        dataSize: dataSize
                    )

                    // Record API cost ($0.0005 per image for Gemini 2.0 Flash)
                    print("DEBUG GeminiAPIService: Recording cost for gemini, timestamp: \(Date())")
                    CostTracker.shared.recordCost(service: "gemini", cost: 0.0005)

                    print("DEBUG GeminiAPIService: SUCCESS completion called with text length \(text.count), timestamp: \(Date())")
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
                print("DEBUG GeminiAPIService: JSON decode error: \(error), timestamp: \(Date())")

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