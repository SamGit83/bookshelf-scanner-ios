import Foundation

/**
 * GrokAPIService - AI-Powered Book Recommendations
 *
 * Uses Grok-3-mini model for personalized book recommendations based on user's library
 * and reading preferences.
 */
class GrokAPIService {
    private var apiKey: String {
        // Try environment variable first, fallback to SecureConfig
        if let envKey = ProcessInfo.processInfo.environment["GROK_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        return SecureConfig.shared.grokAPIKey
    }

    private let baseURL = "https://api.x.ai/v1/chat/completions"

    func generateRecommendations(userBooks: [Book], currentBook: Book?, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        let startTime = Date()
        let traceId = PerformanceMonitoringService.shared.trackAPICall(service: "grok", endpoint: "chat/completions", method: "POST")

        print("DEBUG GrokAPIService: generateRecommendations called with \(userBooks.count) books")

        let prompt = buildRecommendationPrompt(userBooks: userBooks, currentBook: currentBook)

        let requestBody: [String: Any] = [
            "model": "grok-3-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]

        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        print("DEBUG GrokAPIService: Sending request to Grok API")
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            let dataSize = Int64(data?.count ?? 0)

            if let error = error {
                print("DEBUG GrokAPIService: Network error: \(error.localizedDescription)")

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
                print("DEBUG GrokAPIService: Response string: \(responseString)")
            }

            do {
                let grokResponse = try JSONDecoder().decode(GrokResponse.self, from: data)

                if let error = grokResponse.error {
                    print("DEBUG GrokAPIService: API error: \(error.message)")
                    let apiError = NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])

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

                if let choices = grokResponse.choices, let content = choices.first?.message.content {
                    print("DEBUG GrokAPIService: Extracted content, length: \(content.count)")
                    print("DEBUG GrokAPIService: Content: \(content)")

                    // Track successful API call and cost ($0.001 per request for Grok)
                    PerformanceMonitoringService.shared.completeAPICall(
                        traceId: traceId,
                        success: true,
                        responseTime: responseTime,
                        dataSize: dataSize
                    )

                    CostTracker.shared.recordCost(service: "grok", cost: 0.001)

                    self.parseRecommendations(from: content, completion: completion)
                } else {
                    print("DEBUG GrokAPIService: No content in response")
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
                print("DEBUG GrokAPIService: JSON decode error: \(error)")

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

    private func buildRecommendationPrompt(userBooks: [Book], currentBook: Book?) -> String {
        var prompt = """
        You are an expert librarian and book recommender. Based on a user's book library, provide personalized book recommendations.

        USER'S LIBRARY:
        """

        // Add user's books
        for book in userBooks.prefix(20) { // Limit to avoid token limits
            if let title = book.title, let author = book.author {
                let genre = book.genre ?? "Unknown"
                prompt += "\n- \"\(title)\" by \(author) (Genre: \(genre))"
            }
        }

        if let currentBook = currentBook, let title = currentBook.title, let author = currentBook.author {
            let genre = currentBook.genre ?? "Unknown"
            prompt += """

            CURRENT BOOK BEING VIEWED:
            - \"\(title)\" by \(author) (Genre: \(genre))
            """
        }

        prompt += """

        TASK: Recommend 10-15 books that this user would likely enjoy based on their reading patterns, favorite genres, and authors. Focus on:
        1. Books by similar authors they already enjoy
        2. Books in their favorite genres
        3. Books with similar themes or styles to their current reading
        4. Popular and well-regarded books in their preferred categories

        IMPORTANT: Only recommend real, existing books. Do not invent books or authors.

        OUTPUT FORMAT: Return a JSON array of book recommendations with this exact structure:
        [
          {
            "id": "unique_id_here",
            "title": "Book Title",
            "author": "Author Name",
            "genre": "Genre/Category",
            "description": "Brief description (2-3 sentences)",
            "publishedDate": "YYYY",
            "pageCount": 300
          }
        ]

        Make sure the JSON is valid and properly formatted. Focus on quality recommendations that match the user's tastes.
        """

        return prompt
    }

    func fetchAuthorBiography(author: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        Provide a concise biography of the author \(author). Include their birth/death dates if applicable, major works, and key achievements. Keep it to 2-3 paragraphs.
        """

        let requestBody: [String: Any] = [
            "model": "grok-3-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.3
        ]

        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }

            do {
                let grokResponse = try JSONDecoder().decode(GrokResponse.self, from: data)

                if let error = grokResponse.error {
                    completion(.failure(NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])))
                    return
                }

                if let choices = grokResponse.choices, let content = choices.first?.message.content {
                    print("DEBUG GrokAPIService: Fetched bio/teaser content: \(content)")
                    completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    print("DEBUG GrokAPIService: No content in bio/teaser response")
                    completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchBookSummary(title: String, author: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        Provide a short, engaging summary/teaser for the book "\(title)" by \(author). Keep it to 2-3 sentences that capture the essence of the story without spoilers. Make it enticing and informative.
        """

        let requestBody: [String: Any] = [
            "model": "grok-3-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.5
        ]

        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }

            do {
                let grokResponse = try JSONDecoder().decode(GrokResponse.self, from: data)

                if let error = grokResponse.error {
                    completion(.failure(NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])))
                    return
                }

                if let choices = grokResponse.choices, let content = choices.first?.message.content {
                    completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func analyzeAgeRating(title: String?, author: String?, description: String?, genre: String?, completion: @escaping (Result<String, Error>) -> Void) {
        var prompt = """
        Analyze the following book and determine its appropriate age rating based on content, themes, and target audience. Return only one of these categories: "Children", "Teen", "Adult", "Mature", or "Unknown" if insufficient information.

        Book Details:
        """

        if let title = title {
            prompt += "\nTitle: \(title)"
        }
        if let author = author {
            prompt += "\nAuthor: \(author)"
        }
        if let description = description {
            prompt += "\nDescription: \(description)"
        }
        if let genre = genre {
            prompt += "\nGenre: \(genre)"
        }

        prompt += """

        Age Rating Guidelines:
        - Children: Books suitable for ages 8-12, with simple themes, no mature content
        - Teen: Books for ages 13-17, may include coming-of-age themes, mild romance, some violence
        - Adult: Books for ages 18+, with complex themes, mature relationships, moderate violence/language
        - Mature: Books with explicit content, graphic violence, strong language, or controversial themes
        - Unknown: Insufficient information to determine rating

        Return only the category name, nothing else.
        """

        let requestBody: [String: Any] = [
            "model": "grok-3-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 50,
            "temperature": 0.3
        ]

        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }

            do {
                let grokResponse = try JSONDecoder().decode(GrokResponse.self, from: data)

                if let error = grokResponse.error {
                    completion(.failure(NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])))
                    return
                }

                if let choices = grokResponse.choices, let content = choices.first?.message.content {
                    let rating = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Validate the response is one of the expected categories
                    let validRatings = ["Children", "Teen", "Adult", "Mature", "Unknown"]
                    if validRatings.contains(rating) {
                        completion(.success(rating))
                    } else {
                        completion(.success("Unknown"))
                    }
                } else {
                    completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func parseRecommendations(from content: String, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        // Extract JSON from response (might be wrapped in markdown)
        var jsonString = content
        if let jsonStart = content.range(of: "```json\n"), let jsonEnd = content.range(of: "\n```", options: .backwards) {
            jsonString = String(content[jsonStart.upperBound..<jsonEnd.lowerBound])
        } else if let jsonStart = content.range(of: "["), let jsonEnd = content.range(of: "]", options: .backwards) {
            // Try to extract JSON array directly
            let startIndex = content.distance(from: content.startIndex, to: jsonStart.lowerBound)
            let endIndex = content.distance(from: content.startIndex, to: jsonEnd.upperBound)
            if startIndex < endIndex {
                jsonString = String(content[jsonStart.lowerBound..<jsonEnd.upperBound])
            }
        }

        print("DEBUG GrokAPIService: Extracted JSON string: \(jsonString)")

        do {
            if let data = jsonString.data(using: .utf8) {
                let recommendations = try JSONDecoder().decode([BookRecommendation].self, from: data)
                print("DEBUG GrokAPIService: Successfully parsed \(recommendations.count) recommendations")
                completion(.success(recommendations))
            } else {
                completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])))
            }
        } catch {
            print("DEBUG GrokAPIService: JSON decode error: \(error)")
            completion(.failure(error))
        }
    }
}

// Grok API Response Models
struct GrokResponse: Codable {
    let choices: [GrokChoice]?
    let error: GrokError?
}

struct GrokChoice: Codable {
    let message: GrokMessage
}

struct GrokMessage: Codable {
    let content: String
}

struct GrokError: Codable {
    let message: String
    let type: String?
}