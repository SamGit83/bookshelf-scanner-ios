import SwiftUI

struct CurrentlyReadingView: View {
    @ObservedObject var viewModel: BookViewModel
    @Binding var isShowingCamera: Bool

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.currentlyReadingBooks.isEmpty {
                    LiquidGlassCard {
                        VStack(spacing: LiquidGlass.Spacing.space20) {
                            ZStack {
                                Circle()
                                    .fill(LiquidGlass.secondary.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)

                                Image(systemName: "book.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            Text("No books currently reading")
                                .font(LiquidGlass.Typography.headlineLarge)
                                .foregroundColor(.white)

                            Text("Move books from library or scan new ones!")
                                .font(LiquidGlass.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)
                } else {
                    ScrollView {
                        LazyVStack(spacing: LiquidGlass.Spacing.space16) {
                            ForEach(viewModel.currentlyReadingBooks) { book in
                                LiquidBookCard(book: book, viewModel: viewModel)
                                    .padding(.horizontal, LiquidGlass.Spacing.space16)
                            }
                        }
                        .padding(.vertical, LiquidGlass.Spacing.space16)
                    }
                }

                Spacer()

                LiquidGlassButton(
                    title: "Scan Bookshelf",
                    style: .secondary,
                    isLoading: false
                ) {
                    isShowingCamera = true
                }
                .padding(.horizontal, LiquidGlass.Spacing.space32)
                .padding(.bottom, LiquidGlass.Spacing.space16)
            }
            .navigationTitle("Currently Reading")
            .overlay(
                Group {
                    if viewModel.isLoading {
                        LiquidGlassCard {
                            HStack(spacing: LiquidGlass.Spacing.space12) {
                                LiquidSpinner()
                                Text("Analyzing image...")
                                    .font(LiquidGlass.Typography.bodyMedium)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
        }
    }
}

// MARK: - Liquid Book Card (Shared Component)

struct LiquidBookCard: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @State private var showActionSheet = false

    var body: some View {
        LiquidGlassCard {
            HStack(spacing: LiquidGlass.Spacing.space16) {
                // Book Cover with Liquid Glass effect
                ZStack {
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                        .fill(LiquidGlass.glassBackground)
                        .frame(width: 60, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )

                    if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 86)
                            .cornerRadius(LiquidGlass.CornerRadius.small)
                    } else {
                        Image(systemName: "book.fill")
                            .resizable()
                            .frame(width: 32, height: 40)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                // Book Details
                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                    Text(book.title)
                        .font(LiquidGlass.Typography.headlineMedium)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(book.author)
                        .font(LiquidGlass.Typography.bodyMedium)
                        .foregroundColor(.white.opacity(0.8))

                    if let genre = book.genre {
                        Text(genre)
                            .font(LiquidGlass.Typography.captionMedium)
                            .foregroundColor(LiquidGlass.accent)
                            .padding(.horizontal, LiquidGlass.Spacing.space8)
                            .padding(.vertical, LiquidGlass.Spacing.space4)
                            .background(LiquidGlass.accent.opacity(0.2))
                            .cornerRadius(LiquidGlass.CornerRadius.small)
                    }

                    // Reading status indicator
                    HStack(spacing: LiquidGlass.Spacing.space4) {
                        Circle()
                            .fill(book.status == .currentlyReading ? LiquidGlass.accent : LiquidGlass.secondary)
                            .frame(width: 8, height: 8)

                        Text(book.status.rawValue)
                            .font(LiquidGlass.Typography.captionSmall)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Action Menu
                Button(action: {
                    showActionSheet = true
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .liquidInteraction()
                }
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text(book.title),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("Move to Currently Reading")) {
                        withAnimation(LiquidGlass.Animation.spring) {
                            viewModel.moveBook(book, to: .currentlyReading)
                        }
                    },
                    .default(Text("Move to Library")) {
                        withAnimation(LiquidGlass.Animation.spring) {
                            viewModel.moveBook(book, to: .library)
                        }
                    },
                    .destructive(Text("Delete Book")) {
                        withAnimation(LiquidGlass.Animation.spring) {
                            viewModel.deleteBook(book)
                        }
                    },
                    .cancel()
                ]
            )
        }
        .liquidInteraction()
    }
}