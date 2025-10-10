import SwiftUI

struct QuizQuestion: Identifiable {
    let id: Int
    let question: String
    let options: [String]
    let multipleSelection: Bool
}

struct QuizView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentQuestionIndex = 0
    @State private var responses: [Int: Set<String>] = [:]
    @State private var showConfetti = false
    @State private var showSummary = false
    @State private var quizSaveError: String?

    let questions: [QuizQuestion] = [
        QuizQuestion(
            id: 0,
            question: "What is your age group?",
            options: ["Under 18", "18-24", "25-34", "35-44", "45-54", "55-64", "65+"],
            multipleSelection: false
        ),
        QuizQuestion(
            id: 1,
            question: "What is your gender?",
            options: ["Male", "Female", "Non-binary", "Prefer not to say"],
            multipleSelection: false
        ),
        QuizQuestion(
            id: 2,
            question: "How often do you read?",
            options: ["Daily", "A few times a week", "Once a week", "A few times a month", "Rarely"],
            multipleSelection: false
        ),
        QuizQuestion(
            id: 3,
            question: "What are your favorite genres?",
            options: ["Fiction", "Non-fiction", "Mystery/Thriller", "Romance", "Science Fiction", "Fantasy", "Biography/Memoir", "History", "Self-help/Personal Development", "Poetry", "Other"],
            multipleSelection: true
        ),
        QuizQuestion(
            id: 4,
            question: "What type of books do you prefer?",
            options: ["Physical books", "E-books", "Audiobooks", "All equally"],
            multipleSelection: false
        ),
        QuizQuestion(
            id: 5,
            question: "How many books do you typically read per year?",
            options: ["0-5", "6-10", "11-20", "21-50", "50+"],
            multipleSelection: false
        ),
        QuizQuestion(
            id: 6,
            question: "What motivates you to read?",
            options: ["Relaxation", "Learning new things", "Entertainment", "Social recommendations", "Professional development", "Other"],
            multipleSelection: true
        ),
        QuizQuestion(
            id: 7,
            question: "Do you track your reading progress?",
            options: ["Yes, regularly", "Sometimes", "No"],
            multipleSelection: false
        ),
        QuizQuestion(
            id: 8,
            question: "Who are some of your favorite authors?",
            options: ["J.K. Rowling", "Stephen King", "Jane Austen", "George Orwell", "Agatha Christie", "Other"],
            multipleSelection: true
        ),
        QuizQuestion(
            id: 9,
            question: "What is your preferred book format?",
            options: ["Paperback", "Hardcover", "Digital (e-book)", "Audio", "Any"],
            multipleSelection: false
        )
    ]

    var currentQuestion: QuizQuestion {
        questions[currentQuestionIndex]
    }

    var body: some View {
        if showSummary {
            QuizSummaryView(questions: questions, responses: responses, dismiss: {
                presentationMode.wrappedValue.dismiss()
            })
        } else {
            ZStack {
                AppleBooksColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AppleBooksSpacing.space24) {
                        Color.clear
                            .frame(height: AppleBooksSpacing.space32)

                        AppleBooksCard(
                            cornerRadius: 20,
                            padding: AppleBooksSpacing.space24,
                            shadowStyle: .medium
                        ) {
                            VStack(spacing: AppleBooksSpacing.space24) {
                                // Progress Indicator
                                HStack(spacing: AppleBooksSpacing.space8) {
                                    ForEach(0..<questions.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentQuestionIndex ? AppleBooksColors.accent : AppleBooksColors.textTertiary)
                                            .frame(width: index == currentQuestionIndex ? 10 : 8,
                                                   height: index == currentQuestionIndex ? 10 : 8)
                                            .animation(.easeInOut(duration: 0.3), value: currentQuestionIndex)
                                    }
                                }
                                .padding(.top, AppleBooksSpacing.space8)

                                // Question Text
                                Text(currentQuestion.question)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppleBooksColors.text)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.8)
                                    .padding(.horizontal, AppleBooksSpacing.space16)

                                // Options
                                VStack(spacing: AppleBooksSpacing.space12) {
                                    ForEach(currentQuestion.options, id: \.self) { option in
                                        OptionButton(
                                            option: option,
                                            isSelected: isSelected(option),
                                            multipleSelection: currentQuestion.multipleSelection,
                                            action: {
                                                toggleSelection(option)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        Color.clear
                            .frame(height: AppleBooksSpacing.space32)
                    }
                }

                // Navigation Buttons
                HStack(spacing: AppleBooksSpacing.space16) {
                    if currentQuestionIndex > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentQuestionIndex -= 1
                            }
                        }) {
                            Text("Previous")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppleBooksColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(AppleBooksColors.card)
                                .cornerRadius(12)
                        }
                    } else {
                        Spacer()
                    }

                    if currentQuestionIndex < questions.count - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentQuestionIndex += 1
                            }
                        }) {
                            Text("Next")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(AppleBooksColors.accent)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            // Quiz completed - save responses and show confetti then summary
                            let quizResponses: [String: [String]] = responses.reduce(into: [:]) { dict, pair in
                                dict["\(pair.key)"] = Array(pair.value)
                            }
                            AuthService.shared.completeQuiz(with: quizResponses) { result in
                                switch result {
                                case .success:
                                    print("Quiz responses saved successfully")
                                case .failure(let error):
                                    print("Error saving quiz responses: \(error.localizedDescription)")
                                    quizSaveError = error.localizedDescription
                                }
                            }
                            showConfetti = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showConfetti = false
                                showSummary = true
                            }
                        }) {
                            Text("Complete Quiz")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(AppleBooksColors.success)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
                .padding(.bottom, AppleBooksSpacing.space32)
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        }
    }

    private func isSelected(_ option: String) -> Bool {
        responses[currentQuestion.id]?.contains(option) ?? false
    }

    private func toggleSelection(_ option: String) {
        if currentQuestion.multipleSelection {
            var currentSelections = responses[currentQuestion.id] ?? Set<String>()
            if currentSelections.contains(option) {
                currentSelections.remove(option)
            } else {
                currentSelections.insert(option)
            }
            responses[currentQuestion.id] = currentSelections
        } else {
            responses[currentQuestion.id] = [option]
        }
    }
}

struct OptionButton: View {
    let option: String
    let isSelected: Bool
    let multipleSelection: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if multipleSelection {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? AppleBooksColors.accent : AppleBooksColors.textSecondary)
                        .font(.system(size: 18))
                } else {
                    Circle()
                        .stroke(isSelected ? AppleBooksColors.accent : AppleBooksColors.textSecondary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .fill(isSelected ? AppleBooksColors.accent : Color.clear)
                                .frame(width: 10, height: 10)
                        )
                }

                Text(option)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppleBooksColors.text)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.vertical, AppleBooksSpacing.space12)
            .padding(.horizontal, AppleBooksSpacing.space16)
            .background(isSelected ? AppleBooksColors.accent.opacity(0.1) : AppleBooksColors.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppleBooksColors.accent : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuizSummaryView: View {
    let questions: [QuizQuestion]
    let responses: [Int: Set<String>]
    let dismiss: () -> Void

    var answeredQuestions: [QuizQuestion] {
        questions.filter { responses[$0.id] != nil }
    }

    var body: some View {
        ZStack {
            AppleBooksColors.background
                .ignoresSafeArea()

            VStack(spacing: AppleBooksSpacing.space24) {
                Text("Quiz Completed!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppleBooksColors.text)
                    .multilineTextAlignment(.center)

                ScrollView {
                    VStack(spacing: AppleBooksSpacing.space16) {
                        ForEach(Array(answeredQuestions.enumerated()), id: \.0) { index, question in
                            if let response = responses[question.id] {
                                AppleBooksCard(
                                    cornerRadius: 12,
                                    padding: AppleBooksSpacing.space16,
                                    shadowStyle: .subtle
                                ) {
                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        Text(question.question)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(AppleBooksColors.text)
                                        Text(response.sorted().joined(separator: ", "))
                                            .font(.system(size: 16))
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                }

                Spacer()

                Button(action: dismiss) {
                    Text("Done")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppleBooksSpacing.space16)
                        .background(AppleBooksColors.success)
                        .cornerRadius(12)
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
                .padding(.bottom, AppleBooksSpacing.space32)
            }
        }
    }
}

// Preview
struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView()
    }
}