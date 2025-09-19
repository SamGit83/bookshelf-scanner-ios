import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import FirebaseFirestore

struct EditBookView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BookViewModel
    @State private var book: Book
    @State private var title: String
    @State private var author: String
    @State private var isbn: String
    @State private var genre: String
    @State private var selectedStatus: BookStatus
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(book: Book, viewModel: BookViewModel) {
        self.book = book
        self.viewModel = viewModel
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _isbn = State(initialValue: book.isbn ?? "")
        _genre = State(initialValue: book.genre ?? "")
        _selectedStatus = State(initialValue: book.status)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 10)

                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.primary)
                            }

                            Text("Edit Book")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Update book details and status")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 32)

                        // Book Cover Preview
                        if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 120, height: 160)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )

                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 112, height: 152)
                                    .cornerRadius(8)
                            }
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                            .padding(.horizontal, 32)
                        }

                        // Edit Form
                        VStack(spacing: 20) {
                            // Title Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title *")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("Book Title", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            // Author Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Author *")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("Author Name", text: $author)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            // ISBN Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ISBN")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("ISBN (Optional)", text: $isbn)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            // Genre Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Genre")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("Genre (Optional)", text: $genre)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            // Reading Status
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reading Status")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Picker("Status", selection: $selectedStatus) {
                                    ForEach(BookStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue)
                                            .tag(status)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }

                            // Action Buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Cancel")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    saveChanges()
                                }) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Save Changes")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .disabled(title.isEmpty || author.isEmpty || isLoading)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)

                        Spacer(minLength: 32)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .medium))
                }
            )
            .alert(item: Binding(
                get: { errorMessage.map { ErrorWrapper(error: $0) } },
                set: { _ in errorMessage = nil }
            )) { errorWrapper in
                Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveChanges() {
        guard !title.isEmpty && !author.isEmpty else {
            errorMessage = "Title and author are required"
            return
        }

        isLoading = true
        errorMessage = nil

        // Create updated book
        var updatedBook = book
        updatedBook.title = title
        updatedBook.author = author
        updatedBook.isbn = isbn.isEmpty ? nil : isbn
        updatedBook.genre = genre.isEmpty ? nil : genre

        // Update in Firestore (access db via FirebaseConfig since viewModel.db is private)
        let bookRef = FirebaseConfig.shared.db
            .collection("users")
            .document(FirebaseConfig.shared.currentUserId ?? "")
            .collection("books")
            .document(book.id.uuidString)

        let data: [String: Any] = [
            "id": updatedBook.id.uuidString,
            "title": updatedBook.title,
            "author": updatedBook.author,
            "isbn": updatedBook.isbn as Any,
            "genre": updatedBook.genre as Any,
            "status": updatedBook.status.rawValue,
            "dateAdded": Timestamp(date: updatedBook.dateAdded),
            "coverImageData": updatedBook.coverImageData as Any
        ]
        bookRef.setData(data) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Failed to save changes: \(error.localizedDescription)"
                } else {
                    if updatedBook.status != selectedStatus {
                        viewModel.moveBook(updatedBook, to: selectedStatus)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}