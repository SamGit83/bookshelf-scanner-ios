import SwiftUI

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
                LiquidGlass.primary.opacity(0.05)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LiquidGlass.Spacing.space24) {
                        // Header
                        VStack(spacing: LiquidGlass.Spacing.space16) {
                            ZStack {
                                Circle()
                                    .fill(LiquidGlass.secondary.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 10)

                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }

                            Text("Edit Book")
                                .font(LiquidGlass.Typography.headlineLarge)
                                .foregroundColor(.white)

                            Text("Update book details and status")
                                .font(LiquidGlass.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)

                        // Book Cover Preview
                        if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                            ZStack {
                                RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                                    .fill(LiquidGlass.glassBackground)
                                    .frame(width: 120, height: 160)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )

                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 112, height: 152)
                                    .cornerRadius(LiquidGlass.CornerRadius.medium)
                            }
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                            .padding(.horizontal, LiquidGlass.Spacing.space32)
                        }

                        // Edit Form
                        LiquidGlassCard {
                            VStack(spacing: LiquidGlass.Spacing.space20) {
                                // Title Field
                                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                    Text("Title *")
                                        .font(LiquidGlass.Typography.captionLarge)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("Book Title", text: $title)
                                        .textFieldStyle(LiquidTextFieldStyle())
                                }

                                // Author Field
                                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                    Text("Author *")
                                        .font(LiquidGlass.Typography.captionLarge)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("Author Name", text: $author)
                                        .textFieldStyle(LiquidTextFieldStyle())
                                }

                                // ISBN Field
                                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                    Text("ISBN")
                                        .font(LiquidGlass.Typography.captionLarge)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("ISBN (Optional)", text: $isbn)
                                        .textFieldStyle(LiquidTextFieldStyle())
                                        .keyboardType(.numberPad)
                                }

                                // Genre Field
                                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                    Text("Genre")
                                        .font(LiquidGlass.Typography.captionLarge)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("Genre (Optional)", text: $genre)
                                        .textFieldStyle(LiquidTextFieldStyle())
                                }

                                // Reading Status
                                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space12) {
                                    Text("Reading Status")
                                        .font(LiquidGlass.Typography.captionLarge)
                                        .foregroundColor(.white.opacity(0.8))

                                    Picker("Status", selection: $selectedStatus) {
                                        ForEach(BookStatus.allCases, id: \.self) { status in
                                            Text(status.rawValue)
                                                .tag(status)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .background(LiquidGlass.glassBackground.opacity(0.5))
                                    .cornerRadius(LiquidGlass.CornerRadius.medium)
                                }

                                // Action Buttons
                                HStack(spacing: LiquidGlass.Spacing.space12) {
                                    LiquidGlassButton(
                                        title: "Cancel",
                                        style: .secondary,
                                        isLoading: false
                                    ) {
                                        presentationMode.wrappedValue.dismiss()
                                    }

                                    LiquidGlassButton(
                                        title: "Save Changes",
                                        style: .primary,
                                        isLoading: isLoading
                                    ) {
                                        saveChanges()
                                    }
                                    .disabled(title.isEmpty || author.isEmpty || isLoading)
                                }
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)

                        Spacer(minLength: LiquidGlass.Spacing.space32)
                    }
                    .padding(.vertical, LiquidGlass.Spacing.space16)
                }
            }
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
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

        // Update in Firestore
        let bookRef = viewModel.db.collection("users").document(FirebaseConfig.shared.currentUserId ?? "").collection("books").document(book.id.uuidString)

        do {
            try bookRef.setData(from: updatedBook) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        errorMessage = "Failed to save changes: \(error.localizedDescription)"
                    } else {
                        // If status changed, update it separately
                        if updatedBook.status != selectedStatus {
                            viewModel.moveBook(updatedBook, to: selectedStatus)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode book data: \(error.localizedDescription)"
        }
    }
}