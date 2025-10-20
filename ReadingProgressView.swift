import SwiftUI

struct ReadingProgressView: View {
    @ObservedObject var viewModel: BookViewModel
    let bookId: UUID
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage: String = ""
    @State private var isLoggingSession = false
    @State private var showGoalSetup = false
    @State private var showSuccessMessage = false

    private var book: Book? {
        viewModel.books.first { $0.id == bookId }
    }

    init(book: Book, viewModel: BookViewModel) {
        self.bookId = book.id
        self.viewModel = viewModel
        _currentPage = State(initialValue: String(book.currentPage))
        print("DEBUG ReadingProgressView: init called with bookId: \(bookId)")
        print("DEBUG ReadingProgressView: init called with curr page: \(book.currentPage)")
        print("DEBUG ReadingProgressView: init called with tot pages: \(book.totalPages)")
    }

    var body: some View {
        ZStack {
            AppleBooksColors.background
                .ignoresSafeArea()

            let foundBook = book

            if let book = foundBook {
                ScrollView {
                    VStack(spacing: AppleBooksSpacing.space32) {
                        // Header
                        HStack {
                            Spacer()
                            Text("Reading Progress")
                                .font(AppleBooksTypography.headlineLarge)
                                .foregroundColor(AppleBooksColors.text)
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

                        // Book Header
                        AppleBooksCard(
                            cornerRadius: 16,
                            padding: AppleBooksSpacing.space24,
                            shadowStyle: .medium
                        ) {
                            HStack(spacing: AppleBooksSpacing.space16) {
                                // Book Cover
                                if let coverData = book.coverImageData,
                                    let uiImage = UIImage(data: coverData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 120)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                } else if let coverURL = book.coverImageURL,
                                          let url = URL(string: coverURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 80, height: 120)
                                                .cornerRadius(12)
                                                .overlay(
                                                    ProgressView()
                                                        .scaleEffect(0.5)
                                                )
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 120)
                                                .cornerRadius(12)
                                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                        case .failure:
                                            Rectangle()
                                                .fill(Color.red.opacity(0.3))
                                                .frame(width: 80, height: 120)
                                                .cornerRadius(12)
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
                                                .frame(width: 80, height: 120)
                                                .cornerRadius(12)
                                        }
                                    }
                                    .id(book.coverImageURL) // Force refresh when URL changes
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 120)
                                        .cornerRadius(12)
                                        .overlay(
                                            Text("No Cover")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                }

                                // Book Details
                                VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                    Text(book.title ?? "Unknown Title")
                                        .font(AppleBooksTypography.displayMedium)
                                        .foregroundColor(AppleBooksColors.text)
                                        .lineLimit(2)

                                    Text(book.author ?? "Unknown Author")
                                        .font(AppleBooksTypography.bodyMedium)
                                        .foregroundColor(AppleBooksColors.textSecondary)

                                    if let genre = book.genre {
                                        Text(genre)
                                            .font(AppleBooksTypography.captionBold)
                                            .foregroundColor(AppleBooksColors.accent)
                                            .padding(.horizontal, AppleBooksSpacing.space8)
                                            .padding(.vertical, AppleBooksSpacing.space4)
                                            .background(AppleBooksColors.accent.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        // Progress Overview
                        VStack(spacing: AppleBooksSpacing.space20) {
                            Text("Reading Progress")
                                .font(AppleBooksTypography.headlineLarge)
                                .foregroundColor(AppleBooksColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            AppleBooksCard(
                                cornerRadius: 16,
                                padding: AppleBooksSpacing.space24,
                                shadowStyle: .subtle
                            ) {
                                VStack(spacing: AppleBooksSpacing.space16) {
                                    let totalPages = book.totalPages
                                    let progress: CGFloat = totalPages != nil ? min(CGFloat(book.currentPage) / CGFloat(totalPages!), 1.0) : 0.0
                                    ZStack {
                                        if let totalPages = book.totalPages, totalPages > 0 {
                                            let progress = min(CGFloat(book.currentPage) / CGFloat(totalPages), 1.0)
                                            let center = CGPoint(x: 70, y: 70)
                                            let radius: CGFloat = 70
                                            // Read pages sector
                                            Path { path in
                                                path.move(to: center)
                                                path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90.0 + 360.0 * progress), clockwise: false)
                                                path.closeSubpath()
                                            }.fill(AppleBooksColors.success)
                                            // Remaining pages sector
                                            Path { path in
                                                path.move(to: center)
                                                path.addArc(center: center, radius: radius, startAngle: .degrees(-90.0 + 360.0 * progress), endAngle: .degrees(270), clockwise: false)
                                                path.closeSubpath()
                                            }.fill(AppleBooksColors.textTertiary)
                                        } else {
                                            let center = CGPoint(x: 70, y: 70)
                                            let radius: CGFloat = 70
                                            Path { path in
                                                path.move(to: center)
                                                path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(270), clockwise: false)
                                                path.closeSubpath()
                                            }.fill(AppleBooksColors.textTertiary)
                                        }
                                        VStack(spacing: AppleBooksSpacing.space4) {
                                            let progressPercentage = (totalPages != nil && totalPages! > 0) ? min(Int(round((Double(book.currentPage) / Double(totalPages!)) * 100)), 100) : 0
                                            Text("\(progressPercentage)%")
                                                .font(AppleBooksTypography.displayLarge)
                                                .foregroundColor(AppleBooksColors.text)
                                                .fontWeight(.bold)
                                            Text("Pages Read")
                                                .font(AppleBooksTypography.bodySmall)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                        }
                                    }
                                    .frame(width: 140, height: 140)
                                }
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        // Statistics Section
                        VStack(spacing: AppleBooksSpacing.space20) {
                            Text("Reading Statistics")
                                .font(AppleBooksTypography.headlineLarge)
                                .foregroundColor(AppleBooksColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppleBooksSpacing.space16) {
                                // Total Pages Read
                                AppleBooksCard(
                                    cornerRadius: 12,
                                    padding: AppleBooksSpacing.space16,
                                    shadowStyle: .subtle
                                ) {
                                    VStack(spacing: AppleBooksSpacing.space8) {
                                        VStack(spacing: AppleBooksSpacing.space8) {
                                            Image(systemName: "book.pages")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppleBooksColors.accent)

                                            Text("\(book.currentPage)")
                                                .font(AppleBooksTypography.headlineMedium)
                                                .foregroundColor(AppleBooksColors.text)
                                                .fontWeight(.bold)

                                            Text("Pages Read")
                                                .font(AppleBooksTypography.caption)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                        }
                                    }
                                }

                                // Reading Streak
                                AppleBooksCard(
                                    cornerRadius: 12,
                                    padding: AppleBooksSpacing.space16,
                                    shadowStyle: .subtle
                                ) {
                                    VStack(spacing: AppleBooksSpacing.space8) {
                                        Image(systemName: "flame")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppleBooksColors.promotional)

                                        Text("7") // Placeholder for streak
                                            .font(AppleBooksTypography.headlineMedium)
                                            .foregroundColor(AppleBooksColors.text)
                                            .fontWeight(.bold)

                                        Text("Day Streak")
                                            .font(AppleBooksTypography.caption)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                    }
                                }

                                // Average Session
                                AppleBooksCard(
                                    cornerRadius: 12,
                                    padding: AppleBooksSpacing.space16,
                                    shadowStyle: .subtle
                                ) {
                                    VStack(spacing: AppleBooksSpacing.space8) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppleBooksColors.success)

                                        Text("25m") // Placeholder
                                            .font(AppleBooksTypography.headlineMedium)
                                            .foregroundColor(AppleBooksColors.text)
                                            .fontWeight(.bold)

                                        Text("Avg Session")
                                            .font(AppleBooksTypography.caption)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                    }
                                }

                                // Total Time
                                AppleBooksCard(
                                    cornerRadius: 12,
                                    padding: AppleBooksSpacing.space16,
                                    shadowStyle: .subtle
                                ) {
                                    VStack(spacing: AppleBooksSpacing.space8) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppleBooksColors.accent)

                                        Text("3h 45m") // Placeholder
                                            .font(AppleBooksTypography.headlineMedium)
                                            .foregroundColor(AppleBooksColors.text)
                                            .fontWeight(.bold)

                                        Text("Total Time")
                                            .font(AppleBooksTypography.caption)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        // Update Progress Section
                        VStack(spacing: AppleBooksSpacing.space20) {
                            Text("Update Progress")
                                .font(AppleBooksTypography.headlineLarge)
                                .foregroundColor(AppleBooksColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            AppleBooksCard(
                                cornerRadius: 16,
                                padding: AppleBooksSpacing.space24,
                                shadowStyle: .subtle
                            ) {
                                VStack(spacing: AppleBooksSpacing.space20) {
                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        Text("Current Page")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(AppleBooksColors.textSecondary)

                                        TextField("Enter current page", text: $currentPage)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .font(AppleBooksTypography.bodyLarge)
                                    }

                                    HStack(spacing: AppleBooksSpacing.space12) {
                                        Button(action: {
                                            updateCurrentPage()
                                        }) {
                                            Text("Update Page")
                                                .frame(maxWidth: .infinity)
                                                .padding(AppleBooksSpacing.space16)
                                                .background(AppleBooksColors.accent)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                                .font(AppleBooksTypography.buttonLarge)
                                        }

                                        Button(action: {
                                            markBookComplete()
                                        }) {
                                            Text("Mark Complete")
                                                .frame(maxWidth: .infinity)
                                                .padding(AppleBooksSpacing.space16)
                                                .background(AppleBooksColors.card)
                                                .foregroundColor(AppleBooksColors.accent)
                                                .cornerRadius(12)
                                                .font(AppleBooksTypography.buttonLarge)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(AppleBooksColors.accent, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        Spacer(minLength: AppleBooksSpacing.space40)
                    }
                    .padding(.vertical, AppleBooksSpacing.space24)
                }

                // Success Message Overlay
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        AppleBooksCard(
                            cornerRadius: 12,
                            padding: AppleBooksSpacing.space16,
                            shadowStyle: .subtle
                        ) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppleBooksColors.success)
                                    .font(.system(size: 20))

                                Text("Progress updated successfully!")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.text)

                                Spacer()

                                Button(action: {
                                    showSuccessMessage = false
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(AppleBooksColors.textSecondary)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)
                        .padding(.bottom, AppleBooksSpacing.space24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            } else {
                // Book not found
                VStack(spacing: AppleBooksSpacing.space24) {
                    Text("Book not found")
                        .font(AppleBooksTypography.headlineLarge)
                        .foregroundColor(AppleBooksColors.text)
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Go Back")
                            .font(AppleBooksTypography.buttonLarge)
                            .foregroundColor(AppleBooksColors.accent)
                    }
                }
            }
        }
    }

    private func updateCurrentPage() {
        guard let page = Int(currentPage), page >= 0, let book = book else {
            // Show error - could add a state variable for this
            return
        }

        viewModel.updateReadingProgress(book, currentPage: page)

        // Show success message
        withAnimation {
            showSuccessMessage = true
        }

        // Hide success message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showSuccessMessage = false
            }
        }
    }

    private func markBookComplete() {
        guard let book = book else { return }

        viewModel.markBookAsComplete(book)

        // Show success message
        withAnimation {
            showSuccessMessage = true
        }

        // Hide success message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showSuccessMessage = false
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ReadingSessionRow: View {
    let session: ReadingSession

    var body: some View {
        AppleBooksCard(
            cornerRadius: 12,
            padding: AppleBooksSpacing.space16,
            shadowStyle: .subtle
        ) {
            HStack {
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text("\(session.pagesRead) pages")
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)

                    Text("\(Int(session.duration)) min")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppleBooksSpacing.space4) {
                    Text(formattedDate(session.date))
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)

                    if let notes = session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AppleBooksTypography.captionBold)
                            .foregroundColor(AppleBooksColors.accent)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
