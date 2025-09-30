import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Reading Progress Book Card
struct ReadingProgressBookCard: View {
    let book: Book
    let onTap: () -> Void
    let onMarkComplete: () -> Void

    private var progress: Double {
        guard let totalPages = book.totalPages, totalPages > 0 else { return 0 }
        return Double(book.currentPage) / Double(totalPages)
    }

    private var progressText: String {
        guard let totalPages = book.totalPages else { return "" }
        return "\(book.currentPage)/\(totalPages) pages"
    }

    var body: some View {
        AppleBooksCard(
            cornerRadius: 12,
            padding: AppleBooksSpacing.space12,
            shadowStyle: .subtle
        ) {
            VStack(spacing: AppleBooksSpacing.space12) {
                HStack(spacing: AppleBooksSpacing.space12) {
                    // Book Cover
                    if let coverData = book.coverImageData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            .overlay(
                                Text("No Cover")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            )
                    }

                    // Book Details
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                        Text(book.title ?? "Unknown Title")
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(book.author ?? "Unknown Author")
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(AppleBooksColors.textSecondary)

                        if let genre = book.genre {
                            Text(genre)
                                .font(AppleBooksTypography.captionBold)
                                .foregroundColor(AppleBooksColors.accent)
                                .padding(.horizontal, AppleBooksSpacing.space8)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(AppleBooksColors.accent.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    Spacer()
                }

                // Progress Bar
                if book.totalPages != nil && book.totalPages! > 0 {
                    VStack(spacing: AppleBooksSpacing.space8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                    .cornerRadius(3)

                                Rectangle()
                                    .fill(AppleBooksColors.success)
                                    .frame(width: geometry.size.width * progress, height: 6)
                                    .cornerRadius(3)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text(progressText)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.textSecondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(AppleBooksTypography.captionBold)
                                .foregroundColor(AppleBooksColors.success)
                        }
                        .onAppear {
                            if book.coverImageData != nil {
                                print("DEBUG ReadingView: Book has coverImageData - \(book.title ?? "Unknown")")
                            } else {
                                print("DEBUG ReadingView: Book missing coverImageData, coverImageURL: \(book.coverImageURL ?? "nil") - \(book.title ?? "Unknown")")
                            }
                        }
                    }
                }
                
                // Action Buttons
                HStack(spacing: AppleBooksSpacing.space12) {
                    Button(action: onTap) {
                        Text("Update Progress")
                            .font(AppleBooksTypography.buttonMedium)
                            .foregroundColor(AppleBooksColors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppleBooksSpacing.space8)
                            .background(AppleBooksColors.accent.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: onMarkComplete) {
                        Text("Mark Complete")
                            .font(AppleBooksTypography.buttonMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppleBooksSpacing.space8)
                            .background(AppleBooksColors.success)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct ReadingView: View {
    @ObservedObject var viewModel: BookViewModel
    @State private var selectedBook: Book?
    @State private var showingProgressView = false

    private var emptyStateView: some View {
        VStack(spacing: AppleBooksSpacing.space20) {
            Image(systemName: "book.closed")
                .font(.system(size: 72, weight: .light))
                .foregroundColor(AppleBooksColors.textSecondary)

            VStack(spacing: AppleBooksSpacing.space8) {
                Text("No books currently reading")
                    .font(AppleBooksTypography.headlineLarge)
                    .foregroundColor(AppleBooksColors.text)
                    .multilineTextAlignment(.center)

                Text("Move books from your library to start tracking your reading progress")
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
    }

    private var readingBooksSection: some View {
        ScrollView {
            VStack(spacing: AppleBooksSpacing.space16) {
                ForEach(viewModel.readingBooks) { book in
                    ReadingProgressBookCard(
                        book: book,
                        onTap: {
                            selectedBook = book
                            showingProgressView = true
                        },
                        onMarkComplete: {
                            // Mark book as read and remove from reading list
                            viewModel.moveBook(book, to: .read)
                        }
                    )
                }
            }
            .padding(.horizontal, AppleBooksSpacing.space24)
            .padding(.vertical, AppleBooksSpacing.space24)
        }
    }

    var body: some View {
        ZStack {
            AppleBooksColors.background
                .ignoresSafeArea()

            if viewModel.readingBooks.isEmpty {
                emptyStateView
            } else {
                readingBooksSection
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingProgressView) {
            if let book = selectedBook {
                ReadingProgressView(book: book, viewModel: viewModel)
            }
        }
    }
}

struct ReadingView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingView(viewModel: BookViewModel())
    }
}