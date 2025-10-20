import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Reading Progress Book Card
struct ReadingProgressBookCard: View {
    let book: Book
    let onTap: () -> Void
    let onMarkComplete: () -> Void

    @State private var showPageNumber = false
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

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
                    } else if let coverURL = book.coverImageURL,
                              let url = URL(string: coverURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(8)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.5)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            case .failure:
                                Rectangle()
                                    .fill(Color.red.opacity(0.3))
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(8)
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.red)
                                                .font(.system(size: 16))
                                            Text("Failed")
                                                .font(.system(size: 8))
                                                .foregroundColor(.red)
                                        }
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(8)
                            }
                        }
                        .id(book.coverImageURL)
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
                            .bold()
                            .foregroundColor(AppleBooksColors.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(book.author ?? "Unknown Author")
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(AppleBooksColors.text)

                        // Row 1: Page count, reading time, and age rating badges
                        HStack(spacing: AppleBooksSpacing.space6) {
                            if let pageCount = book.pageCount {
                                Text("\(pageCount) pages")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.promotional)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(AppleBooksColors.promotional.opacity(0.1))
                                    .cornerRadius(4)
                            } else {
                                Text("Page count unavailable")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.promotional)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(AppleBooksColors.promotional.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            if let estimatedReadingTime = book.estimatedReadingTime {
                                Text(estimatedReadingTime)
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.success)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(AppleBooksColors.success.opacity(0.1))
                                    .cornerRadius(4)
                            } else {
                                Text("Reading time unavailable")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.success)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(AppleBooksColors.success.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            // Age rating badge
                            if let ageRating = book.ageRating {
                                let isChildren = ageRating.lowercased().contains("children") || ageRating.lowercased().contains("general")
                                let isTeen = ageRating.lowercased().contains("teen")
                                let isAdult = ageRating.lowercased().contains("adult") || ageRating.lowercased().contains("mature")
                                let (bgColor, fgColor): (Color, Color) = {
                                    if isChildren {
                                        return (AppleBooksColors.success.opacity(0.1), AppleBooksColors.success)
                                    } else if isTeen {
                                        return (AppleBooksColors.accent.opacity(0.1), AppleBooksColors.accent)
                                    } else if isAdult {
                                        return (Color(hex: "FF9500").opacity(0.1), Color(hex: "FF9500"))
                                    } else {
                                        return (AppleBooksColors.card.opacity(0.8), AppleBooksColors.text)
                                    }
                                }()
                                Text(ageRating)
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(fgColor)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(bgColor)
                                    .cornerRadius(4)
                            } else {
                                Text("Unrated")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.text)
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(AppleBooksColors.card.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                        // Row 2: Sub-genre badge
                        if let subGenre = book.subGenre {
                            HStack(spacing: AppleBooksSpacing.space6) {
                                Text(subGenre)
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(Color(hex: "B19CD9"))
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(Color(hex: "B19CD9").opacity(0.1))
                                    .cornerRadius(4)
                                Spacer()
                            }
                        } else {
                            HStack(spacing: AppleBooksSpacing.space6) {
                                Text("Sub-genre unavailable")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(Color(hex: "B19CD9"))
                                    .padding(.horizontal, AppleBooksSpacing.space6)
                                    .padding(.vertical, AppleBooksSpacing.space2)
                                    .background(Color(hex: "B19CD9").opacity(0.1))
                                    .cornerRadius(4)
                                Spacer()
                            }
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
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    if book.currentPage > 0 {
                        ZStack {
                            if showPageNumber {
                                Text("\(book.currentPage)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(AppleBooksColors.accent.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            } else {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(AppleBooksColors.accent.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(8)
                    }
                }
                Spacer()
            }
        )
        .onReceive(timer) { _ in
            showPageNumber.toggle()
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
            VStack(spacing: AppleBooksSpacing.space32) {
                AppleBooksSectionHeader(
                    title: "Currently Reading",
                    subtitle: "\(viewModel.readingBooks.count) books",
                    showSeeAll: false,
                    seeAllAction: nil
                )
                LazyVStack(spacing: AppleBooksSpacing.space16) {
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
            }
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