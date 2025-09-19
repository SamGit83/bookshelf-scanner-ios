import Foundation
import SwiftUI

// MARK: - Error Types

enum BookshelfError: LocalizedError {
    case networkError(String)
    case apiError(String)
    case authenticationError(String)
    case validationError(String)
    case bookNotFound(String)
    case permissionDenied(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .bookNotFound(let message):
            return "Book Not Found: \(message)"
        case .permissionDenied(let message):
            return "Permission Denied: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again."
        case .apiError:
            return "The service might be temporarily unavailable. Please try again later."
        case .authenticationError:
            return "Please sign in again to continue."
        case .validationError:
            return "Please check your input and try again."
        case .bookNotFound:
            return "Try searching with different keywords or add the book manually."
        case .permissionDenied:
            return "Please grant the necessary permissions in Settings."
        case .unknownError:
            return "Something went wrong. Please try again or contact support."
        }
    }

    var iconName: String {
        switch self {
        case .networkError:
            return "wifi.slash"
        case .apiError:
            return "exclamationmark.triangle"
        case .authenticationError:
            return "person.crop.circle.badge.xmark"
        case .validationError:
            return "exclamationmark.circle"
        case .bookNotFound:
            return "magnifyingglass"
        case .permissionDenied:
            return "hand.raised"
        case .unknownError:
            return "questionmark.circle"
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .networkError, .apiError:
            return .medium
        case .authenticationError, .permissionDenied:
            return .high
        case .validationError, .bookNotFound:
            return .low
        case .unknownError:
            return .medium
        }
    }
}

enum ErrorSeverity {
    case low, medium, high

    var color: Color {
        switch self {
        case .low:
            return .orange
        case .medium:
            return .yellow
        case .high:
            return .red
        }
    }
}

// MARK: - Error Handler

class ErrorHandler: ObservableObject {
    @Published var currentError: BookshelfError?
    @Published var showError = false

    static let shared = ErrorHandler()

    private init() {}

    func handle(_ error: Error, context: String = "") {
        let bookshelfError = convertToBookshelfError(error, context: context)
        DispatchQueue.main.async {
            self.currentError = bookshelfError
            self.showError = true
        }

        // Log error for debugging
        print("📱 Bookshelf Error: \(bookshelfError.localizedDescription)")
        if let suggestion = bookshelfError.recoverySuggestion {
            print("💡 Suggestion: \(suggestion)")
        }
    }

    func dismissError() {
        currentError = nil
        showError = false
    }

    private func convertToBookshelfError(_ error: Error, context: String) -> BookshelfError {
        if let bookshelfError = error as? BookshelfError {
            return bookshelfError
        }

        let errorMessage = error.localizedDescription

        // Network-related errors
        if errorMessage.contains("network") || errorMessage.contains("connection") {
            return .networkError(errorMessage)
        }

        // Authentication errors
        if errorMessage.contains("auth") || errorMessage.contains("login") {
            return .authenticationError(errorMessage)
        }

        // API errors
        if errorMessage.contains("api") || errorMessage.contains("server") {
            return .apiError(errorMessage)
        }

        // Permission errors
        if errorMessage.contains("permission") || errorMessage.contains("denied") {
            return .permissionDenied(errorMessage)
        }

        // Validation errors
        if errorMessage.contains("invalid") || errorMessage.contains("required") {
            return .validationError(errorMessage)
        }

        return .unknownError(errorMessage)
    }
}

// MARK: - Error View Components

struct ErrorAlertView: View {
    @ObservedObject var errorHandler = ErrorHandler.shared
    @State private var showDetails = false

    var body: some View {
        if errorHandler.showError, let error = errorHandler.currentError {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: error.iconName)
                        .foregroundColor(error.severity.color)
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(error.localizedDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring()) {
                            showDetails.toggle()
                        }
                    }) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }

                if showDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        if let suggestion = error.recoverySuggestion {
                            Text("💡 Suggestion")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text(suggestion)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            Spacer()

                            Button(action: {
                                errorHandler.dismissError()
                            }) {
                                Text("Dismiss")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }

                            Button(action: {
                                // TODO: Implement retry action
                                errorHandler.dismissError()
                            }) {
                                Text("Retry")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Error Boundary

struct ErrorBoundary<Content: View>: View {
    let content: Content
    @StateObject private var errorHandler = ErrorHandler.shared

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .environmentObject(errorHandler)

            VStack {
                Spacer()
                if errorHandler.showError {
                    ErrorAlertView()
                        .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(), value: errorHandler.showError)
        }
    }
}

// MARK: - Convenience Extensions

extension View {
    func handleError(_ error: Error, context: String = "") -> some View {
        self.onAppear {
            ErrorHandler.shared.handle(error, context: context)
        }
    }

    func withErrorBoundary() -> some View {
        ErrorBoundary {
            self
        }
    }
}

extension BookshelfError {
    static func fromAPIResponse(_ response: URLResponse?, error: Error?) -> BookshelfError {
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 400...499:
                return .validationError("Invalid request. Please check your input.")
            case 500...599:
                return .apiError("Server error. Please try again later.")
            default:
                break
            }
        }

        if let error = error {
            return .networkError(error.localizedDescription)
        }

        return .unknownError("An unexpected error occurred")
    }
}