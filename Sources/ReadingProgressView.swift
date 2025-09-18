import SwiftUI

struct ReadingProgressView: View {
    @ObservedObject var viewModel: BookViewModel
    let book: Book
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage: String = ""
    @State private var sessionPages: String = ""
    @State private var sessionDuration: String = ""
    @State private var sessionNotes: String = ""
    @State private var isLoggingSession = false
    @State private var showGoalSetup = false
    @State private var goalPages: String = ""
    @State private var goalDeadline: Date = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days

    init(book: Book, viewModel: BookViewModel) {
        self.book = book
        self.viewModel = viewModel
        _currentPage = State(initialValue: String(book.currentPage))
    }

    var body: some View {
        NavigationView {
            ZStack {
                LiquidGlass.primary.opacity(0.05)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LiquidGlass.Spacing.space24) {
                        // Book Header
                        VStack(spacing: LiquidGlass.Spacing.space16) {
                            ZStack {
                                Circle()
                                    .fill(LiquidGlass.secondary.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 10)

                                Image(systemName: "book.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            Text(book.title)
                                .font(LiquidGlass.Typography.headlineLarge)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(book.author)
                                .font(LiquidGlass.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)

                        // Progress Overview
                        LiquidGlassCard {
                            VStack(spacing: LiquidGlass.Spacing.space16) {
                                Text("Reading Progress")
                                    .font(LiquidGlass.Typography.headlineMedium)
                                    .foregroundColor(.white)

                                if let totalPages = book.totalPages {
                                    // Progress Circle
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                                            .frame(width: 120, height: 120)

                                        Circle()
                                            .trim(from: 0, to: min(CGFloat(book.currentPage) / CGFloat(totalPages), 1.0))
                                            .stroke(LiquidGlass.accent, lineWidth: 8)
                                            .frame(width: 120, height: 120)
                                            .rotationEffect(.degrees(-90))

                                        VStack {
                                            Text("\(book.currentPage)")
                                                .font(LiquidGlass.Typography.headlineLarge)
                                                .foregroundColor(.white)
                                            Text("of \(totalPages)")
                                                .font(LiquidGlass.Typography.captionLarge)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }

                                    let progressPercentage = totalPages > 0 ? Int((Double(book.currentPage) / Double(totalPages)) * 100) : 0
                                    Text("\(progressPercentage)% Complete")
                                        .font(LiquidGlass.Typography.bodyMedium)
                                        .foregroundColor(LiquidGlass.accent)
                                } else {
                                    Text("No page count set")
                                        .font(LiquidGlass.Typography.bodyMedium)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)

                        // Current Page Update
                        LiquidGlassCard {
                            VStack(spacing: LiquidGlass.Spacing.space16) {
                                Text("Update Progress")
                                    .font(LiquidGlass.Typography.headlineMedium)
                                    .foregroundColor(.white)

                                VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                    Text("Current Page")
                                        .font(LiquidGlass.Typography.captionLarge)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("Enter current page", text: $currentPage)
                                        .textFieldStyle(LiquidTextFieldStyle())
                                        .keyboardType(.numberPad)
                                }

                                HStack(spacing: LiquidGlass.Spacing.space12) {
                                    LiquidGlassButton(
                                        title: "Update Page",
                                        style: .primary,
                                        isLoading: false
                                    ) {
                                        updateCurrentPage()
                                    }

                                    LiquidGlassButton(
                                        title: "Mark Complete",
                                        style: .secondary,
                                        isLoading: false
                                    ) {
                                        markBookComplete()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)

                        // Reading Sessions
                        LiquidGlassCard {
                            VStack(spacing: LiquidGlass.Spacing.space16) {
                                HStack {
                                    Text("Reading Sessions")
                                        .font(LiquidGlass.Typography.headlineMedium)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Button(action: {
                                        isLoggingSession = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(LiquidGlass.accent)
                                            .font(.title2)
                                    }
                                }

                                if book.readingSessions.isEmpty {
                                    Text("No reading sessions logged yet")
                                        .font(LiquidGlass.Typography.bodyMedium)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.vertical, LiquidGlass.Spacing.space16)
                                } else {
                                    ForEach(book.readingSessions.sorted { $0.date > $1.date }.prefix(5)) { session in
                                        ReadingSessionRow(session: session)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)

                        // Reading Goals
                        if let goal = book.readingGoal {
                            LiquidGlassCard {
                                VStack(spacing: LiquidGlass.Spacing.space16) {
                                    Text("Reading Goal")
                                        .font(LiquidGlass.Typography.headlineMedium)
                                        .foregroundColor(.white)

                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("\(goal.targetPages) pages")
                                                .font(LiquidGlass.Typography.headlineSmall)
                                                .foregroundColor(.white)

                                            Text("by \(formattedDate(goal.deadline))")
                                                .font(LiquidGlass.Typography.captionMedium)
                                                .foregroundColor(.white.opacity(0.7))
                                        }

                                        Spacer()

                                        if goal.isCompleted {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title)
                                        } else {
                                            let progress = book.totalPages.map { Double(book.currentPage) / Double($0) } ?? 0
                                            let goalProgress = min(progress, 1.0)
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                                    .frame(width: 40, height: 40)

                                                Circle()
                                                    .trim(from: 0, to: goalProgress)
                                                    .stroke(LiquidGlass.accent, lineWidth: 4)
                                                    .frame(width: 40, height: 40)
                                                    .rotationEffect(.degrees(-90))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, LiquidGlass.Spacing.space32)
                        } else {
                            // Setup Goal Button
                            LiquidGlassButton(
                                title: "Set Reading Goal",
                                style: .secondary,
                                isLoading: false
                            ) {
                                showGoalSetup = true
                            }
                            .padding(.horizontal, LiquidGlass.Spacing.space32)
                        }

                        Spacer(minLength: LiquidGlass.Spacing.space32)
                    }
                    .padding(.vertical, LiquidGlass.Spacing.space16)
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                },
                trailing: Button(action: {
                    // TODO: Add book details/settings
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
            )
            .navigationBarTitle("Reading Progress", displayMode: .inline)
            .sheet(isPresented: $isLoggingSession) {
                ReadingSessionLogView(book: book, viewModel: viewModel)
            }
            .sheet(isPresented: $showGoalSetup) {
                ReadingGoalSetupView(book: book, viewModel: viewModel)
            }
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
        HStack {
            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space4) {
                Text("\(session.pagesRead) pages")
                    .font(LiquidGlass.Typography.bodyMedium)
                    .foregroundColor(.white)

                Text("\(Int(session.duration)) min")
                    .font(LiquidGlass.Typography.captionMedium)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: LiquidGlass.Spacing.space4) {
                Text(formattedDate(session.date))
                    .font(LiquidGlass.Typography.captionMedium)
                    .foregroundColor(.white.opacity(0.7))

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(LiquidGlass.Typography.captionSmall)
                        .foregroundColor(LiquidGlass.accent)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, LiquidGlass.Spacing.space8)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct ReadingSessionLogView: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var pagesRead: String = ""
    @State private var duration: String = ""
    @State private var notes: String = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                LiquidGlass.primary.opacity(0.05)
                    .ignoresSafeArea()

                VStack(spacing: LiquidGlass.Spacing.space24) {
                    // Header
                    VStack(spacing: LiquidGlass.Spacing.space16) {
                        Text("Log Reading Session")
                            .font(LiquidGlass.Typography.headlineLarge)
                            .foregroundColor(.white)

                        Text("Track your reading progress")
                            .font(LiquidGlass.Typography.bodyMedium)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)

                    // Form
                    LiquidGlassCard {
                        VStack(spacing: LiquidGlass.Spacing.space16) {
                            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                Text("Pages Read")
                                    .font(LiquidGlass.Typography.captionLarge)
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("Number of pages", text: $pagesRead)
                                    .textFieldStyle(LiquidTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                Text("Reading Duration (minutes)")
                                    .font(LiquidGlass.Typography.captionLarge)
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("Duration in minutes", text: $duration)
                                    .textFieldStyle(LiquidTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                Text("Notes (Optional)")
                                    .font(LiquidGlass.Typography.captionLarge)
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("Reading notes", text: $notes)
                                    .textFieldStyle(LiquidTextFieldStyle())
                            }

                            LiquidGlassButton(
                                title: "Save Session",
                                style: .primary,
                                isLoading: isLoading
                            ) {
                                saveReadingSession()
                            }
                            .disabled(pagesRead.isEmpty || duration.isEmpty || isLoading)
                        }
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)

                    Spacer()
                }
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(LiquidGlass.accent)
            })
        }
    }

    private func saveReadingSession() {
        guard let pages = Int(pagesRead), let minutes = Int(duration) else {
            // TODO: Show validation error
            return
        }

        // TODO: Save reading session to Firestore
        presentationMode.wrappedValue.dismiss()
    }
}

struct ReadingGoalSetupView: View {
    let book: Book
    @ObservedObject var viewModel: BookViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var targetPages: String = ""
    @State private var deadline: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                LiquidGlass.primary.opacity(0.05)
                    .ignoresSafeArea()

                VStack(spacing: LiquidGlass.Spacing.space24) {
                    // Header
                    VStack(spacing: LiquidGlass.Spacing.space16) {
                        Text("Set Reading Goal")
                            .font(LiquidGlass.Typography.headlineLarge)
                            .foregroundColor(.white)

                        Text("Challenge yourself to read more")
                            .font(LiquidGlass.Typography.bodyMedium)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)

                    // Form
                    LiquidGlassCard {
                        VStack(spacing: LiquidGlass.Spacing.space16) {
                            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                Text("Target Pages")
                                    .font(LiquidGlass.Typography.captionLarge)
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("Number of pages to read", text: $targetPages)
                                    .textFieldStyle(LiquidTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                Text("Deadline")
                                    .font(LiquidGlass.Typography.captionLarge)
                                    .foregroundColor(.white.opacity(0.8))

                                DatePicker("Select deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                    .accentColor(LiquidGlass.accent)
                            }

                            LiquidGlassButton(
                                title: "Set Goal",
                                style: .primary,
                                isLoading: isLoading
                            ) {
                                saveReadingGoal()
                            }
                            .disabled(targetPages.isEmpty || isLoading)
                        }
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)

                    Spacer()
                }
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(LiquidGlass.accent)
            })
        }
    }

    private func saveReadingGoal() {
        guard let pages = Int(targetPages) else {
            // TODO: Show validation error
            return
        }

        // TODO: Save reading goal to Firestore
        presentationMode.wrappedValue.dismiss()
    }
}