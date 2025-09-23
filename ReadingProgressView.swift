import SwiftUI

struct ReadingProgressView: View {
    @ObservedObject var viewModel: BookViewModel
    let book: Book
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage: String = ""
    @State private var isLoggingSession = false
    @State private var showGoalSetup = false

    init(book: Book, viewModel: BookViewModel) {
        self.book = book
        self.viewModel = viewModel
        _currentPage = State(initialValue: String(book.currentPage))
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppleBooksColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppleBooksSpacing.space32) {
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
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 80, height: 120)
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray)
                                    }
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
                                    if let totalPages = book.totalPages {
                                        // Progress Circle
                                        ZStack {
                                            Circle()
                                                .stroke(AppleBooksColors.textTertiary, lineWidth: 8)
                                                .frame(width: 140, height: 140)

                                            Circle()
                                                .trim(from: 0, to: min(CGFloat(book.currentPage) / CGFloat(totalPages), 1.0))
                                                .stroke(AppleBooksColors.success, lineWidth: 8)
                                                .frame(width: 140, height: 140)
                                                .rotationEffect(.degrees(-90))

                                            VStack(spacing: AppleBooksSpacing.space4) {
                                                Text("\(book.currentPage)")
                                                    .font(AppleBooksTypography.displayLarge)
                                                    .foregroundColor(AppleBooksColors.text)
                                                    .fontWeight(.bold)

                                                Text("of \(totalPages)")
                                                    .font(AppleBooksTypography.bodySmall)
                                                    .foregroundColor(AppleBooksColors.textSecondary)
                                            }
                                        }

                                        let progressPercentage = totalPages > 0 ? Int((Double(book.currentPage) / Double(totalPages)) * 100) : 0
                                        Text("\(progressPercentage)% Complete")
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.success)
                                            .fontWeight(.semibold)
                                    } else {
                                        VStack(spacing: AppleBooksSpacing.space12) {
                                            Image(systemName: "chart.pie")
                                                .font(.system(size: 60))
                                                .foregroundColor(AppleBooksColors.textTertiary)

                                            Text("No page count set")
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                        }
                                    }
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

                            HStack(spacing: AppleBooksSpacing.space16) {
                                // Total Pages Read
                                AppleBooksCard(
                                    cornerRadius: 12,
                                    padding: AppleBooksSpacing.space16,
                                    shadowStyle: .subtle
                                ) {
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
                            }

                            HStack(spacing: AppleBooksSpacing.space16) {
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
            }
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(AppleBooksColors.text)
                        .font(.system(size: 16, weight: .medium))
                }
            )
            .navigationBarTitle("Reading Progress", displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func updateCurrentPage() {
        guard let page = Int(currentPage), page >= 0 else {
            // TODO: Show error
            return
        }

        // TODO: Update book progress in Firestore
        presentationMode.wrappedValue.dismiss()
    }

    private func markBookComplete() {
        // TODO: Mark book as completed and move to library
        presentationMode.wrappedValue.dismiss()
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
