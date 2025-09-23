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
    @State private var selectedBook: Book?
    @State private var isShowingDetail = false

    private var emptyStateView: some View {
        VStack(spacing: AppleBooksSpacing.space20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 72, weight: .light))
                .foregroundColor(AppleBooksColors.textSecondary)

            VStack(spacing: AppleBooksSpacing.space8) {
                Text("No books in your library")
                    .font(AppleBooksTypography.headlineLarge)
                    .foregroundColor(AppleBooksColors.text)
                    .multilineTextAlignment(.center)

                Text("Scan a bookshelf or add books manually to get started")
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
    }

    private var libraryContentView: some View {
        ScrollView {
            VStack(spacing: AppleBooksSpacing.space32) {
                // Reading Section (Currently Reading + Legacy)
                let readingBooks = viewModel.books.filter {
                    $0.status == .reading || $0.status == .currentlyReading
                }.sorted(by: selectedSort.sortFunction)
                if !readingBooks.isEmpty {
                    AppleBooksSectionHeader(
                        title: "Reading",
                        subtitle: "\(readingBooks.count) books",
                        showSeeAll: false,
                        seeAllAction: nil
                    )

                    LazyVStack(spacing: AppleBooksSpacing.space16) {
                        ForEach(readingBooks) { book in
                            AppleBooksBookCard(
                                book: book,
                                onTap: { selectedBook = book; isShowingDetail = true },
                                showAddButton: false,
                                onAddTap: nil,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }

                // To Read Section (New books + Legacy Library)
                let toReadBooks = viewModel.books.filter {
                    $0.status == .toRead || $0.status == .library
                }.sorted(by: selectedSort.sortFunction)
                if !toReadBooks.isEmpty {
                    AppleBooksSectionHeader(
                        title: "To Read",
                        subtitle: "\(toReadBooks.count) books",
                        showSeeAll: false,
                        seeAllAction: nil
                    )

                    LazyVStack(spacing: AppleBooksSpacing.space16) {
                        ForEach(toReadBooks) { book in
                            AppleBooksBookCard(
                                book: book,
                                onTap: { selectedBook = book; isShowingDetail = true },
                                showAddButton: false,
                                onAddTap: nil,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }

                // Read Section (Completed books)
                let readBooks = viewModel.books.filter { $0.status == .read }.sorted(by: selectedSort.sortFunction)
                if !readBooks.isEmpty {
                    AppleBooksSectionHeader(
                        title: "Read",
                        subtitle: "\(readBooks.count) books",
                        showSeeAll: false,
                        seeAllAction: nil
                    )

                    LazyVStack(spacing: AppleBooksSpacing.space16) {
                        ForEach(readBooks) { book in
                            AppleBooksBookCard(
                                book: book,
                                onTap: { selectedBook = book; isShowingDetail = true },
                                showAddButton: false,
                                onAddTap: nil,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }
            }
            .padding(.vertical, AppleBooksSpacing.space24)
        }
    }

    private var actionButtonsView: some View {
        VStack(spacing: AppleBooksSpacing.space16) {
            HStack(spacing: AppleBooksSpacing.space16) {
                Button(action: {
                    isShowingCamera = true
                }) {
                    HStack(spacing: AppleBooksSpacing.space8) {
                        Image(systemName: "camera")
                            .font(AppleBooksTypography.buttonMedium)
                        Text("Scan Bookshelf")
                            .font(AppleBooksTypography.buttonLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppleBooksSpacing.space16)
                    .background(AppleBooksColors.accent)
                    .cornerRadius(12)
                }

                Button(action: {
                    isShowingAddBook = true
                }) {
                    HStack(spacing: AppleBooksSpacing.space8) {
                        Image(systemName: "plus")
                            .font(AppleBooksTypography.buttonMedium)
                        Text("Add Manually")
                            .font(AppleBooksTypography.buttonLarge)
                    }
                    .foregroundColor(AppleBooksColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppleBooksSpacing.space16)
                    .background(AppleBooksColors.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppleBooksColors.accent, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
        .padding(.bottom, AppleBooksSpacing.space24)
    }

    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: AppleBooksSpacing.space16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppleBooksColors.accent))
                        .scaleEffect(1.2)

                    Text("Analyzing image...")
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)
                }
                .padding(AppleBooksSpacing.space20)
                .background(AppleBooksColors.card)
                .cornerRadius(16)
                .shadow(color: AppleBooksShadow.subtle.color, radius: AppleBooksShadow.subtle.radius, x: AppleBooksShadow.subtle.x, y: AppleBooksShadow.subtle.y)
                .padding(.horizontal, AppleBooksSpacing.space24)
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            }
        }
    }

    var body: some View {
        ZStack {
            // Apple Books clean background
            AppleBooksColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.books.isEmpty {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else {
                    libraryContentView
                }

                actionButtonsView
            }
        }
        .overlay(loadingOverlay)
        .background(
            NavigationLink("", destination: BookDetailView(book: selectedBook!, viewModel: viewModel), isActive: Binding(get: { isShowingDetail }, set: { isShowingDetail = $0; if !$0 { selectedBook = nil } }))
        )
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: AppleBooksSpacing.space12) {
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .font(AppleBooksTypography.buttonMedium)
                            .padding(AppleBooksSpacing.space8)
                            .background(AppleBooksColors.card)
                            .clipShape(Circle())
                    }

                    Menu {
                        Picker("Sort by", selection: $selectedSort) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(AppleBooksColors.accent)
                            .font(AppleBooksTypography.buttonMedium)
                            .padding(AppleBooksSpacing.space8)
                            .background(AppleBooksColors.accent.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        isShowingSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppleBooksColors.accent)
                            .font(AppleBooksTypography.buttonMedium)
                            .padding(AppleBooksSpacing.space8)
                            .background(AppleBooksColors.accent.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
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
