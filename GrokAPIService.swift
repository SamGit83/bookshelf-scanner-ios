import Foundation

/**
 * GrokAPIService - AI-Powered Book Recommendations
 *
 * Uses Grok-3-mini model for personalized book recommendations based on user's library
 * and reading preferences.
 */
class GrokAPIService {
    private let baseURL = "https://api.x.ai/v1/chat/completions"

    func generateRecommendations(userBooks: [Book], currentBook: Book?, quizResponses: [String: Any]?, completion: @escaping (Result<[BookRecommendation], Error>) -> Void) {
        let startTime = Date()
        let traceId = PerformanceMonitoringService.shared.trackAPICall(service: "grok", endpoint: "chat/completions", method: "POST")

        // Get API key synchronously
        let apiKey = SecureConfig.shared.grokAPIKey

        // Validate API key
        let isValidKey = !apiKey.isEmpty && !apiKey.contains("YOUR_") && apiKey.count > 20
        if !isValidKey {
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

        let prompt = self.buildRecommendationPrompt(userBooks: userBooks, currentBook: currentBook, quizResponses: quizResponses)
        self.performGrokRequest(prompt: prompt, apiKey: apiKey, maxTokens: 2000, temperature: 0.7) { result in
            switch result {
            case .success(let content):
                self.parseRecommendations(from: content, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performGrokRequest(prompt: String, apiKey: String, maxTokens: Int, temperature: Double, completion: @escaping (Result<String, Error>) -> Void) {
        // Generate timestamp for replay attack prevention
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let timeWindow = SecureConfig.shared.requestTimeWindowSeconds
        let requestStartTime = Date()

        let requestBody: [String: Any] = [
            "model": "grok-3-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": maxTokens,
            "temperature": temperature
        ]

        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Validate response timestamp for replay attack prevention
            let responseTime = Date().timeIntervalSince(requestStartTime)
            if responseTime > timeWindow {
                let timestampError = NSError(domain: "TimestampValidation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Response received outside acceptable time window"])
                completion(.failure(timestampError))
                return
            }

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
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


    private func buildRecommendationPrompt(userBooks: [Book], currentBook: Book?, quizResponses: [String: Any]?) -> String {
        var prompt = """
        You are an expert librarian and book recommender. Based on a user's book library and reading preferences, provide personalized book recommendations.

        USER'S LIBRARY:
        """

        // Add user's books
        for book in userBooks.prefix(20) { // Limit to avoid token limits
            if let title = book.title, let author = book.author {
                let genre = book.genre ?? "Unknown"
                prompt += "\n- \"\(title)\" by \(author) (Genre: \(genre))"
            }
        }

        // Add quiz preferences if available
        if let quizResponses = quizResponses, !quizResponses.isEmpty {
            prompt += """

            USER'S READING PREFERENCES (from quiz):
            """
            // Parse quiz responses and add relevant preferences
            if let ageGroup = quizResponses["0"] as? [String], let age = ageGroup.first {
                prompt += "\n- Age group: \(age)"
            }
            if let gender = quizResponses["1"] as? [String], let genderValue = gender.first {
                prompt += "\n- Gender: \(genderValue)"
            }
            if let readingFrequency = quizResponses["2"] as? [String], let frequency = readingFrequency.first {
                prompt += "\n- Reading frequency: \(frequency)"
            }
            if let favoriteGenres = quizResponses["3"] as? [String], !favoriteGenres.isEmpty {
                prompt += "\n- Favorite genres: \(favoriteGenres.joined(separator: ", "))"
            }
            if let bookType = quizResponses["4"] as? [String], let type = bookType.first {
                prompt += "\n- Preferred book format: \(type)"
            }
            if let booksPerYear = quizResponses["5"] as? [String], let count = booksPerYear.first {
                prompt += "\n- Books read per year: \(count)"
            }
            if let motivations = quizResponses["6"] as? [String], !motivations.isEmpty {
                prompt += "\n- Reading motivations: \(motivations.joined(separator: ", "))"
            }
            if let tracking = quizResponses["7"] as? [String], let track = tracking.first {
                prompt += "\n- Progress tracking: \(track)"
            }
            if let favoriteAuthors = quizResponses["8"] as? [String], !favoriteAuthors.isEmpty {
                prompt += "\n- Favorite authors: \(favoriteAuthors.joined(separator: ", "))"
            }
            if let preferredFormat = quizResponses["9"] as? [String], let format = preferredFormat.first {
                prompt += "\n- Preferred format: \(format)"
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

        TASK: Recommend 10-15 books that this user would likely enjoy based on their reading patterns, favorite genres, authors, and stated preferences. Focus on:
        1. Books by their favorite authors or similar authors they already enjoy
        2. Books in their favorite genres from the quiz
        3. Books with themes/styles that match their reading motivations and preferences
        4. Books appropriate for their age group and reading level
        5. Books in their preferred format when possible
        6. Popular and well-regarded books that align with their stated interests

        IMPORTANT: Only recommend real, existing books. Do not invent books or authors. Prioritize recommendations that strongly match their quiz preferences.

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

        Make sure the JSON is valid and properly formatted. Focus on quality recommendations that match the user's tastes and preferences.
        """

        return prompt
    }

    func fetchAuthorBiography(author: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Get API key synchronously
        let apiKey = SecureConfig.shared.grokAPIKey

        // Validate API key
        let isValidKey = !apiKey.isEmpty && !apiKey.contains("YOUR_") && apiKey.count > 20
        if !isValidKey {
            completion(.failure(NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI-based features are temporarily unavailable due to high free API usage. You can still manually add books to your library, and other non-AI functionality remains available. AI features will be restored after a period of time."])))
            return
        }

        let prompt = """
        Provide a concise biography of the author \(author). Include their birth/death dates if applicable, major works, and key achievements. Keep it to 2-3 paragraphs.
        """

        self.performGrokRequest(prompt: prompt, apiKey: apiKey, maxTokens: 500, temperature: 0.3) { result in
            switch result {
            case .success(let content):
                completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchBookSummary(title: String, author: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Get API key synchronously
        let apiKey = SecureConfig.shared.grokAPIKey

        // Validate API key
        let isValidKey = !apiKey.isEmpty && !apiKey.contains("YOUR_") && apiKey.count > 20
        if !isValidKey {
            completion(.failure(NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Grok API key is not configured or invalid"])))
            return
        }

        let prompt = """
        Provide a short, engaging summary/teaser for the book "\(title)" by \(author). Keep it to 2-3 sentences that capture the essence of the story without spoilers. Make it enticing and informative.
        """

        self.performGrokRequest(prompt: prompt, apiKey: apiKey, maxTokens: 300, temperature: 0.5) { result in
            switch result {
            case .success(let content):
                completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func analyzeAgeRating(title: String?, author: String?, description: String?, genre: String?, completion: @escaping (Result<String, Error>) -> Void) {
        // Get API key synchronously
        let apiKey = SecureConfig.shared.grokAPIKey

        // Validate API key
        let isValidKey = !apiKey.isEmpty && !apiKey.contains("YOUR_") && apiKey.count > 20
        if !isValidKey {
            completion(.failure(NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI-based features are temporarily unavailable due to high free API usage. You can still manually add books to your library, and other non-AI functionality remains available. AI features will be restored after a period of time."])))
            return
        }

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

        self.performGrokRequest(prompt: prompt, apiKey: apiKey, maxTokens: 50, temperature: 0.3) { result in
            switch result {
            case .success(let content):
                let rating = content.trimmingCharacters(in: .whitespacesAndNewlines)
                // Validate the response is one of the expected categories
                let validRatings = ["Children", "Teen", "Adult", "Mature", "Unknown"]
                if validRatings.contains(rating) {
                    completion(.success(rating))
                } else {
                    completion(.success("Unknown"))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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

        do {
            if let data = jsonString.data(using: .utf8) {
                let recommendations = try JSONDecoder().decode([BookRecommendation].self, from: data)
                completion(.success(recommendations))
            } else {
                completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])))
            }
        } catch {
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