# Bookshelf Scanner iOS App Architecture Plan

## Overview
A SwiftUI-based iOS application that allows users to scan bookshelves using the device camera, extract book information via Gemini Vision AI API, and organize them into a digital library with "Currently Reading" and "Library" sections.

## Core Requirements
- Camera integration for bookshelf scanning
- Image analysis using Gemini Vision API
- Book data extraction (title, author, etc.)
- Local storage and organization
- Minimal-effort user experience

## Architecture
### Design Pattern: MVVM (Model-View-ViewModel)
- **Model**: Data structures and business logic
- **View**: SwiftUI views for UI
- **ViewModel**: State management and API interactions

### Key Components
1. **Data Models**
   - `Book`: Core entity with book information
   - `BookStatus`: Enum for reading status
   - `ScanResult`: API response structure

2. **Services**
   - `CameraService`: Handles camera operations
   - `GeminiAPIService`: Manages API calls to Gemini Vision
   - `PersistenceService`: Core Data operations

3. **Views**
   - `ScannerView`: Camera interface
   - `LibraryView`: Book collection display
   - `BookDetailView`: Individual book information
   - `MainTabView`: Tab navigation

## Data Models

### Book Model
```swift
struct Book: Identifiable, Codable {
    var id = UUID()
    var title: String
    var author: String
    var isbn: String?
    var genre: String?
    var status: BookStatus
    var dateAdded: Date
    var coverImageData: Data?
}

enum BookStatus: String, Codable {
    case library
    case currentlyReading
}
```

### API Response Model
```swift
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
```

## API Integration
### Gemini Vision API
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent`
- Method: POST
- Content-Type: multipart/form-data
- Parameters:
  - `key`: API key
  - Image file
  - Prompt: "Extract book titles, authors, and other details from this bookshelf image. Return as JSON."

## Persistence
- **Framework**: Core Data
- **Entities**:
  - BookEntity (mirrors Book struct)
- **Operations**: CRUD for books, status updates

## UI Flow
```
App Launch → MainTabView
├── Library Tab → LibraryView (List of books)
│   ├── Scan Button → ScannerView
│   └── Book Row → BookDetailView
└── Currently Reading Tab → CurrentlyReadingView
    ├── Scan Button → ScannerView
    └── Book Row → BookDetailView
```

## Permissions Required
Add to Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan bookshelves</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save book cover images</string>
```

## Error Handling
- Camera access denied
- API failures
- Invalid image data
- Network connectivity issues

## Testing Strategy
- Unit tests for data models and services
- UI tests for main flows
- Integration tests for API calls

## Dependencies
- SwiftUI
- AVFoundation
- Core Data
- URLSession (built-in)

## Implementation Phases
1. Project setup and permissions
2. Data models and persistence
3. Camera integration
4. API service implementation
5. UI development
6. Integration and testing