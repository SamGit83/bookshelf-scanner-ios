import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum SortOption: String, CaseIterable {
    case titleAZ = "Title A-Z"
    case titleZA = "Title Z-A"
    case dateNewest = "Date Added (Newest)"
    case dateOldest = "Date Added (Oldest)"
    case authorAZ = "Author A-Z"
    
    var sortFunction: (Book, Book) -> Bool {
        switch self {
        case .titleAZ:
            return { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
        case .titleZA:
            return { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedDescending }
        case .dateNewest:
            return { $0.dateAdded > $1.dateAdded }
        case .dateOldest:
            return { $0.dateAdded < $1.dateAdded }
        case .authorAZ:
            return { ($0.author ?? "").localizedCaseInsensitiveCompare($1.author ?? "") == .orderedAscending }
        }
    }
}

struct LibraryView: View {
    @ObservedObject var viewModel: BookViewModel
    @Binding var isShowingCamera: Bool
    @State private var isShowingAddBook = false
    @State private var isShowingSearch = false
    @State private var showingClearConfirmation = false
    @State private var selectedSort: SortOption = .titleAZ

    var body: some View {
        NavigationView {
            ZStack {
                // Vibrant background gradient
                BackgroundGradients.libraryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.books.isEmpty {
                        Spacer()
                        
                        // Enhanced empty state
                        VStack(spacing: SpacingSystem.lg) {
                            ZStack {
                                Circle()
                                    .fill(PrimaryColors.vibrantPurple.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 15)

                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 56, weight: .medium))
                                    .foregroundColor(AdaptiveColors.primaryText.opacity(0.8))
                            }

                            VStack(spacing: SpacingSystem.sm) {
                                Text("No books in your collection")
                                    .font(TypographySystem.displayMedium)
                                    .foregroundColor(AdaptiveColors.primaryText)
                                    .multilineTextAlignment(.center)

                                Text("Scan a bookshelf to get started!")
                                    .font(TypographySystem.bodyLarge)
                                    .foregroundColor(AdaptiveColors.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, SpacingSystem.xl)
                        
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: SpacingSystem.md) {
                                ForEach(viewModel.books.sorted(by: selectedSort.sortFunction)) { book in
                                    LibraryBookCard(book: book, viewModel: viewModel)
                                        .padding(.horizontal, SpacingSystem.md)
                                }
                            }
                            .padding(.vertical, SpacingSystem.md)
                        }
                    }

                    // Action buttons with vibrant styling
                    VStack(spacing: SpacingSystem.md) {
                        HStack(spacing: SpacingSystem.md) {
                            Button(action: {
                                isShowingCamera = true
                            }) {
                                HStack(spacing: SpacingSystem.sm) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Scan Bookshelf")
                                        .font(TypographySystem.buttonLarge)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle()

                            Button(action: {
                                isShowingAddBook = true
                            }) {
                                HStack(spacing: SpacingSystem.sm) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Add Manually")
                                        .font(TypographySystem.buttonLarge)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .secondaryButtonStyle()
                        }
                    }
                    .padding(.horizontal, SpacingSystem.lg)
                    .padding(.bottom, SpacingSystem.md)
                }
            }
            .navigationTitle("Library (\(viewModel.books.count))")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: SpacingSystem.sm) {
                        Button(action: {
                            showingClearConfirmation = true
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(SemanticColors.errorPrimary)
                                .font(.system(size: 18, weight: .semibold))
                                .padding(SpacingSystem.sm)
                                .background(AdaptiveColors.glassBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
                                )
                        }
                        
                        Menu {
                            Picker("Sort by", selection: $selectedSort) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(LibraryColors.sortingAccent)
                                .font(.system(size: 18, weight: .semibold))
                                .padding(SpacingSystem.sm)
                                .background(AdaptiveColors.glassBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            isShowingSearch = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(PrimaryColors.vibrantPurple)
                                .font(.system(size: 18, weight: .semibold))
                                .padding(SpacingSystem.sm)
                                .background(AdaptiveColors.glassBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        VStack(spacing: SpacingSystem.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: PrimaryColors.energeticPink))
                                .scaleEffect(1.2)
                            
                            Text("Analyzing image...")
                                .font(TypographySystem.bodyLarge)
                                .foregroundColor(.white)
                        }
                        .padding(SpacingSystem.lg)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, SpacingSystem.xl)
                        .transition(.scale.combined(with: .opacity))
                        .animation(AnimationTiming.transition, value: viewModel.isLoading)
                    }
                }
            )
            .sheet(isPresented: $isShowingAddBook) {
                AddBookView()
            }
            .sheet(isPresented: $isShowingSearch) {
                SearchView(viewModel: viewModel)
            }
            .alert(isPresented: $showingClearConfirmation) {
                Alert(
                    title: Text("Clear All Books"),
                    message: Text("Are you sure you want to delete all books from your collection? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete All")) {
                        viewModel.clearAllBooks()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct LibraryBookCard: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @State private var showActionSheet = false
    @State private var showEditView = false
    @State private var showProgressView = false

    var body: some View {
        ZStack {
            NavigationLink(destination: BookDetailView(book: book, viewModel: viewModel)) {
                HStack(spacing: SpacingSystem.md) {
                    // Enhanced Book Cover with glass effect
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AdaptiveColors.glassBackground)
                            .frame(width: 70, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
                            )

                        if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: PrimaryColors.energeticPink))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 66, height: 96)
                                        .cornerRadius(10)
                                case .failure:
                                    Image(systemName: "book.fill")
                                        .resizable()
                                        .frame(width: 36, height: 44)
                                        .foregroundColor(AdaptiveColors.secondaryText)
                                @unknown default:
                                    Image(systemName: "book.fill")
                                        .resizable()
                                        .frame(width: 36, height: 44)
                                        .foregroundColor(AdaptiveColors.secondaryText)
                                }
                            }
                        } else if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 66, height: 96)
                                .cornerRadius(10)
                        } else {
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 36, height: 44)
                                .foregroundColor(AdaptiveColors.secondaryText)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)

                    // Enhanced Book Details
                    VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                        Text(book.title ?? "Unknown Title")
                            .font(TypographySystem.headlineSmall)
                            .foregroundColor(AdaptiveColors.primaryText)
                            .lineLimit(2)

                        Text(book.author ?? "Unknown Author")
                            .font(TypographySystem.bodyMedium)
                            .foregroundColor(AdaptiveColors.secondaryText)

                        // Enhanced badges with vibrant colors
                        let timeBadge = book.estimatedReadingTime != nil ? ("time", "~ \(book.estimatedReadingTime!)", PrimaryColors.dynamicOrange) : nil
                        let pagesBadge = book.pageCount != nil ? ("pages", "\(book.pageCount!) pages", PrimaryColors.vibrantPurple) : nil
                        let subGenreBadge = book.subGenre != nil ? ("subGenre", book.subGenre!, PrimaryColors.freshGreen) : nil
                        
                        VStack(spacing: SpacingSystem.xs) {
                            HStack(spacing: SpacingSystem.xs) {
                                if let timeBadge = timeBadge {
                                    Text(timeBadge.1)
                                        .font(TypographySystem.captionLarge)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, SpacingSystem.sm)
                                        .padding(.vertical, SpacingSystem.xs)
                                        .background(timeBadge.2)
                                        .cornerRadius(8)
                                }
                                if let pagesBadge = pagesBadge {
                                    Text(pagesBadge.1)
                                        .font(TypographySystem.captionLarge)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, SpacingSystem.sm)
                                        .padding(.vertical, SpacingSystem.xs)
                                        .background(pagesBadge.2)
                                        .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let subGenreBadge = subGenreBadge {
                                Text(subGenreBadge.1)
                                    .font(TypographySystem.captionLarge)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, SpacingSystem.sm)
                                    .padding(.vertical, SpacingSystem.xs)
                                    .background(subGenreBadge.2)
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Enhanced reading status indicator
                        HStack(spacing: SpacingSystem.xs) {
                            Circle()
                                .fill(book.status == .currentlyReading ? PrimaryColors.electricBlue : AdaptiveColors.secondaryText)
                                .frame(width: 10, height: 10)

                            Text(book.status.rawValue)
                                .font(TypographySystem.captionLarge)
                                .foregroundColor(AdaptiveColors.secondaryText)
                        }
                    }

                    Spacer()
                }
                .padding(SpacingSystem.md)
            }
            .buttonStyle(PlainButtonStyle())
            .bookCardStyle()

            // Enhanced Action Menu Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showActionSheet = true
                    }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(PrimaryColors.energeticPink)
                            .padding(SpacingSystem.sm)
                            .background(AdaptiveColors.glassBackground)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
                            )
                            .shadow(color: PrimaryColors.energeticPink.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(SpacingSystem.sm)
                }
                Spacer()
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            var buttons: [ActionSheet.Button] = [
                .default(Text("Track Progress")) {
                    showProgressView = true
                },
                .default(Text("Edit Book")) {
                    showEditView = true
                }
            ]

            if book.status == .library {
                buttons.append(.default(Text("Start Reading")) {
                    withAnimation(.spring()) {
                        viewModel.moveBook(book, to: .currentlyReading)
                    }
                })
            } else if book.status == .currentlyReading {
                buttons.append(.default(Text("Move to Library")) {
                    withAnimation(.spring()) {
                        viewModel.moveBook(book, to: .library)
                    }
                })
            }

            buttons.append(.destructive(Text("Delete Book")) {
                withAnimation(.spring()) {
                    viewModel.deleteBook(book)
                }
            })
            buttons.append(.cancel())

            return ActionSheet(
                title: Text(book.title ?? "Unknown Title"),
                message: Text("Choose an action"),
                buttons: buttons
            )
        }
        .sheet(isPresented: $showEditView) {
            EditBookView(book: book, viewModel: viewModel)
        }
        .sheet(isPresented: $showProgressView) {
            ReadingProgressView(book: book, viewModel: viewModel)
        }
    }
}