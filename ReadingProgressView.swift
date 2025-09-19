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
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Book Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 10)

                                Image(systemName: "book.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.primary)
                            }

                            Text(book.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text(book.author)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 32)

                        // Progress Overview
                        VStack(spacing: 16) {
                            Text("Reading Progress")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if let totalPages = book.totalPages {
                                // Progress Circle
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                        .frame(width: 120, height: 120)

                                    Circle()
                                        .trim(from: 0, to: min(CGFloat(book.currentPage) / CGFloat(totalPages), 1.0))
                                        .stroke(Color.blue, lineWidth: 8)
                                        .frame(width: 120, height: 120)
                                        .rotationEffect(.degrees(-90))

                                    VStack {
                                        Text("\(book.currentPage)")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        Text("of \(totalPages)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                let progressPercentage = totalPages > 0 ? Int((Double(book.currentPage) / Double(totalPages)) * 100) : 0
                                Text("\(progressPercentage)% Complete")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            } else {
                                Text("No page count set")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)

                        // Current Page Update
                        VStack(spacing: 16) {
                            Text("Update Progress")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Page")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("Enter current page", text: $currentPage)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    updateCurrentPage()
                                }) {
                                    Text("Update Page")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    markBookComplete()
                                }) {
                                    Text("Mark Complete")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)

                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .medium))
                }
            )
            .navigationBarTitle("Reading Progress", displayMode: .inline)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.pagesRead) pages")
                    .font(.body)
                    .foregroundColor(.primary)

                Text("\(Int(session.duration)) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDate(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
