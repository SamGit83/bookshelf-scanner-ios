import SwiftUI

struct CurrentlyReadingView: View {
    @ObservedObject var viewModel: BookViewModel
    @Binding var isShowingCamera: Bool

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.currentlyReadingBooks.isEmpty {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .blur(radius: 10)

                            Image(systemName: "book.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                        }

                        Text("No books currently reading")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Move books from library or scan new ones!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.currentlyReadingBooks) { book in
                                BookCard(book: book, viewModel: viewModel)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }

                Spacer()

                Button(action: {
                    isShowingCamera = true
                }) {
                    Text("Scan Bookshelf")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
            .navigationTitle("Currently Reading")
            .overlay(
                Group {
                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Analyzing image...")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal, 32)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
        }
    }
}

// MARK: - Book Card (Shared Component)

struct BookCard: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @State private var showActionSheet = false

    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 90)

                if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 86)
                        .cornerRadius(6)
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .frame(width: 32, height: 40)
                        .foregroundColor(.gray)
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            // Book Details
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(book.author)
                    .font(.body)
                    .foregroundColor(.secondary)

                if let genre = book.genre {
                    Text(genre)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                // Reading status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(book.status == .currentlyReading ? Color.blue : Color.gray)
                        .frame(width: 8, height: 8)

                    Text(book.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action Menu
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text(book.title),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Move to Currently Reading")) {
                        withAnimation(.spring()) {
                            viewModel.moveBook(book, to: .currentlyReading)
                        }
                    },
                    .default(Text("Move to Library")) {
                        withAnimation(.spring()) {
                            viewModel.moveBook(book, to: .library)
                        }
                    },
                    .destructive(Text("Delete Book")) {
                        withAnimation(.spring()) {
                            viewModel.deleteBook(book)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
}