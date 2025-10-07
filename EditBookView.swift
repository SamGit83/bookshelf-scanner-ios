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
    @State private var errorMessage: Error?

    init(book: Book, viewModel: BookViewModel) {
        self.book = book
        self.viewModel = viewModel
        _title = State(initialValue: book.title ?? "")
        _author = State(initialValue: book.author ?? "")
        _isbn = State(initialValue: book.isbn ?? "")
        _genre = State(initialValue: book.genre ?? "")
        _selectedStatus = State(initialValue: book.status)
    }

    private var headerSection: some View {
        HStack {
            Spacer()
            VStack(spacing: AppleBooksSpacing.space8) {
                Text("Edit Book")
                    .font(AppleBooksTypography.displayMedium)
                    .foregroundColor(AppleBooksColors.text)

                Text("Update book details and status")
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
            }
            Spacer()
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(AppleBooksColors.text)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
    }

    private var coverPreview: some View {
        Group {
            if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppleBooksColors.card)
                        .frame(width: 120, height: 160)
                        .shadow(color: AppleBooksShadow.subtle.color, radius: AppleBooksShadow.subtle.radius, x: AppleBooksShadow.subtle.x, y: AppleBooksShadow.subtle.y)

                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 112, height: 152)
                        .cornerRadius(8)
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
            }
        }
    }

    private var editForm: some View {
        AppleBooksCard(
            cornerRadius: 16,
            padding: AppleBooksSpacing.space24,
            shadowStyle: .subtle
        ) {
            VStack(spacing: AppleBooksSpacing.space20) {
                // Title Field
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                    Text("Title *")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    TextField("Book Title", text: $title)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .padding(AppleBooksSpacing.space12)
                        .background(AppleBooksColors.background)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                // Author Field
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                    Text("Author *")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    TextField("Author Name", text: $author)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .padding(AppleBooksSpacing.space12)
                        .background(AppleBooksColors.background)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                // ISBN Field
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                    Text("ISBN")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    TextField("ISBN (Optional)", text: $isbn)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .padding(AppleBooksSpacing.space12)
                        .background(AppleBooksColors.background)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .keyboardType(.numberPad)
                }

                // Genre Field
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                    Text("Genre")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    TextField("Genre (Optional)", text: $genre)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                        .padding(AppleBooksSpacing.space12)
                        .background(AppleBooksColors.background)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                // Reading Status
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space12) {
                    Text("Reading Status")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    Picker("Status", selection: $selectedStatus) {
                        ForEach(BookStatus.allCases, id: \.self) { status in
                            Text(status.rawValue)
                                .tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Action Buttons
                HStack(spacing: AppleBooksSpacing.space16) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(AppleBooksTypography.buttonLarge)
                            .frame(maxWidth: .infinity)
                            .padding(AppleBooksSpacing.space16)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(AppleBooksColors.text)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        saveChanges()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Changes")
                                .font(AppleBooksTypography.buttonLarge)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppleBooksSpacing.space16)
                    .background(AppleBooksColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(title.isEmpty || author.isEmpty || isLoading)
                }
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
    }

    var body: some View {
        ZStack {
            AppleBooksColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppleBooksSpacing.space32) {
                    headerSection
                    coverPreview
                    editForm
                    Spacer(minLength: AppleBooksSpacing.space32)
                }
                .padding(.vertical, AppleBooksSpacing.space16)
            }
            .alert(item: Binding(
                get: { errorMessage.map { ErrorWrapper(error: $0, guidance: nil) } },
                set: { _ in errorMessage = nil }
            )) { errorWrapper in
                Alert(title: Text("Error"), message: Text(errorWrapper.error.localizedDescription), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveChanges() {
        guard !title.isEmpty && !author.isEmpty else {
            errorMessage = NSError(domain: "ValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Title and author are required"])
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

        bookRef.setData(from: updatedBook) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = NSError(domain: "SaveError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save changes: \(error.localizedDescription)"])
                } else {
                    // If status changed, update it separately
                    if updatedBook.status != selectedStatus {
                        viewModel.moveBook(updatedBook, to: selectedStatus)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: Error
    let guidance: String?
}