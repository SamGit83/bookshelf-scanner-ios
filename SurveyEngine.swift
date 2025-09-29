import SwiftUI
import Combine

/**
 * SurveyEngine - Dynamic survey rendering and response collection
 *
 * Provides SwiftUI views for rendering different types of survey questions
 * and collecting user responses with validation and state management.
 */
class SurveyEngine {
    static let shared = SurveyEngine()

    private init() {}

    // MARK: - Survey View Creation

    func createSurveyView(for survey: Survey) -> some View {
        SurveyView(survey: survey)
    }

    func createQuestionView(for question: SurveyQuestion, response: Binding<String?>) -> some View {
        switch question.type {
        case .rating:
            return AnyView(RatingQuestionView(question: question, response: response))
        case .singleChoice:
            return AnyView(SingleChoiceQuestionView(question: question, response: response))
        case .multipleChoice:
            return AnyView(MultipleChoiceQuestionView(question: question, response: response))
        case .text:
            return AnyView(TextQuestionView(question: question, response: response))
        case .nps:
            return AnyView(NPSQuestionView(question: question, response: response))
        }
    }
}

// MARK: - Survey View

struct SurveyView: View {
    let survey: Survey
    @State private var currentQuestionIndex = 0
    @State private var responses: [String: Any] = [:]
    @State private var isSubmitting = false
    @State private var showValidationError = false
    @State private var validationMessage = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundGradients.heroGradient
                    .ignoresSafeArea()

                VStack(spacing: SpacingSystem.lg) {
                    // Header
                    SurveyHeaderView(
                        title: survey.headline ?? survey.title,
                        progress: Double(currentQuestionIndex + 1) / Double(survey.questions.count)
                    )

                    // Question Content
                    ScrollView {
                        VStack(spacing: SpacingSystem.xl) {
                            if currentQuestionIndex < survey.questions.count {
                                let question = survey.questions[currentQuestionIndex]
                                let response = Binding<String?>(
                                    get: { responses[question.id] as? String },
                                    set: { responses[question.id] = $0 }
                                )

                                SurveyEngine.shared.createQuestionView(for: question, response: response)
                                    .padding(.horizontal, SpacingSystem.lg)
                            }
                        }
                    }

                    // Navigation
                    SurveyNavigationView(
                        currentIndex: currentQuestionIndex,
                        totalQuestions: survey.questions.count,
                        canGoNext: canGoNext,
                        onPrevious: goToPrevious,
                        onNext: goToNext,
                        onSubmit: submitSurvey
                    )
                    .padding(.horizontal, SpacingSystem.lg)
                }
            }
            .navigationBarItems(trailing: dismissButton)
            .alert(isPresented: $showValidationError) {
                Alert(title: Text("Required Question"), message: Text(validationMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var dismissButton: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .foregroundColor(AdaptiveColors.primaryText)
                .font(.system(size: 16, weight: .medium))
        }
    }

    private var canGoNext: Bool {
        guard currentQuestionIndex < survey.questions.count else { return false }
        let question = survey.questions[currentQuestionIndex]
        if !question.required { return true }
        return responses[question.id] != nil && !(responses[question.id] as? String)?.isEmpty ?? true
    }

    private func goToPrevious() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }

    private func goToNext() {
        if currentQuestionIndex < survey.questions.count - 1 {
            currentQuestionIndex += 1
        }
    }

    private func submitSurvey() {
        guard validateResponses() else { return }

        isSubmitting = true

        Task {
            let response = SurveyResponse(
                id: UUID().uuidString,
                surveyId: survey.id,
                surveyType: survey.type.rawValue,
                userId: survey.userId,
                responses: responses,
                completedAt: Date(),
                variantId: survey.variantId,
                context: survey.context
            )

            await FeedbackManager.shared.submitSurveyResponse(response)
            await MainActor.run {
                isSubmitting = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func validateResponses() -> Bool {
        for question in survey.questions {
            if question.required {
                if responses[question.id] == nil || (responses[question.id] as? String)?.isEmpty ?? true {
                    validationMessage = "Please answer: \(question.question)"
                    showValidationError = true
                    return false
                }
            }
        }
        return true
    }

    private func dismiss() {
        FeedbackManager.shared.dismissSurvey()
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Header View

struct SurveyHeaderView: View {
    let title: String
    let progress: Double

    var body: some View {
        VStack(spacing: SpacingSystem.md) {
            Text(title)
                .font(TypographySystem.displaySmall)
                .foregroundColor(AdaptiveColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingSystem.lg)

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: PrimaryColors.vibrantPurple))
                .frame(height: 4)
                .padding(.horizontal, SpacingSystem.lg)
        }
        .padding(.top, SpacingSystem.lg)
    }
}

// MARK: - Navigation View

struct SurveyNavigationView: View {
    let currentIndex: Int
    let totalQuestions: Int
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: SpacingSystem.md) {
            if currentIndex > 0 {
                Button(action: onPrevious) {
                    Text("Previous")
                        .font(TypographySystem.buttonMedium)
                        .foregroundColor(AdaptiveColors.secondaryText)
                        .padding(.horizontal, SpacingSystem.lg)
                        .padding(.vertical, SpacingSystem.sm)
                        .background(AdaptiveColors.glassBackground)
                        .cornerRadius(12)
                }
            }

            Spacer()

            if currentIndex < totalQuestions - 1 {
                Button(action: onNext) {
                    Text("Next")
                        .font(TypographySystem.buttonMedium)
                        .foregroundColor(canGoNext ? .white : AdaptiveColors.secondaryText)
                        .padding(.horizontal, SpacingSystem.lg)
                        .padding(.vertical, SpacingSystem.sm)
                        .background(canGoNext ? UIGradients.primaryButton : AdaptiveColors.glassBackground)
                        .cornerRadius(12)
                }
                .disabled(!canGoNext)
            } else {
                Button(action: onSubmit) {
                    Text("Submit")
                        .font(TypographySystem.buttonMedium)
                        .foregroundColor(canGoNext ? .white : AdaptiveColors.secondaryText)
                        .padding(.horizontal, SpacingSystem.lg)
                        .padding(.vertical, SpacingSystem.sm)
                        .background(canGoNext ? UIGradients.primaryButton : AdaptiveColors.glassBackground)
                        .cornerRadius(12)
                }
                .disabled(!canGoNext)
            }
        }
        .padding(.vertical, SpacingSystem.md)
    }
}

// MARK: - Question Views

struct RatingQuestionView: View {
    let question: SurveyQuestion
    @Binding var response: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.lg) {
            QuestionText(question.question, required: question.required)

            HStack(spacing: SpacingSystem.md) {
                ForEach(question.options ?? [], id: \.self) { option in
                    RatingButton(
                        rating: option,
                        isSelected: response == option,
                        action: { response = option }
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .featureCardStyle()
    }
}

struct RatingButton: View {
    let rating: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(rating)
                .font(TypographySystem.headlineMedium)
                .foregroundColor(isSelected ? .white : AdaptiveColors.primaryText)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? PrimaryColors.vibrantPurple : AdaptiveColors.glassBackground)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? PrimaryColors.vibrantPink : AdaptiveColors.glassBorder, lineWidth: isSelected ? 2 : 1)
                        )
                )
        }
    }
}

struct SingleChoiceQuestionView: View {
    let question: SurveyQuestion
    @Binding var response: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.lg) {
            QuestionText(question.question, required: question.required)

            VStack(spacing: SpacingSystem.sm) {
                ForEach(question.options ?? [], id: \.self) { option in
                    ChoiceButton(
                        text: option,
                        isSelected: response == option,
                        action: { response = option }
                    )
                }
            }
        }
        .featureCardStyle()
    }
}

struct MultipleChoiceQuestionView: View {
    let question: SurveyQuestion
    @Binding var response: String?

    // For multiple choice, we'll store comma-separated values
    private var selectedOptions: Set<String> {
        Set((response ?? "").split(separator: ",").map(String.init))
    }

    private func toggleOption(_ option: String) {
        var current = selectedOptions
        if current.contains(option) {
            current.remove(option)
        } else {
            current.insert(option)
        }
        response = current.sorted().joined(separator: ",")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.lg) {
            QuestionText(question.question, required: question.required)

            VStack(spacing: SpacingSystem.sm) {
                ForEach(question.options ?? [], id: \.self) { option in
                    MultipleChoiceButton(
                        text: option,
                        isSelected: selectedOptions.contains(option),
                        action: { toggleOption(option) }
                    )
                }
            }
        }
        .featureCardStyle()
    }
}

struct MultipleChoiceButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingSystem.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? PrimaryColors.vibrantGreen : AdaptiveColors.secondaryText)
                    .font(.system(size: 20))

                Text(text)
                    .font(TypographySystem.bodyLarge)
                    .foregroundColor(AdaptiveColors.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(SpacingSystem.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? PrimaryColors.vibrantGreen.opacity(0.1) : AdaptiveColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? PrimaryColors.vibrantGreen : AdaptiveColors.glassBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TextQuestionView: View {
    let question: SurveyQuestion
    @Binding var response: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.lg) {
            QuestionText(question.question, required: question.required)

            TextEditor(text: Binding(
                get: { response ?? "" },
                set: { response = $0.isEmpty ? nil : $0 }
            ))
            .font(TypographySystem.bodyLarge)
            .foregroundColor(AdaptiveColors.primaryText)
            .frame(minHeight: 100)
            .padding(SpacingSystem.md)
            .background(AdaptiveColors.glassBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
            )
        }
        .featureCardStyle()
    }
}

struct NPSQuestionView: View {
    let question: SurveyQuestion
    @Binding var response: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.lg) {
            QuestionText(question.question, required: question.required)

            VStack(spacing: SpacingSystem.sm) {
                HStack {
                    Text("Not likely")
                        .font(TypographySystem.captionMedium)
                        .foregroundColor(AdaptiveColors.secondaryText)
                    Spacer()
                    Text("Very likely")
                        .font(TypographySystem.captionMedium)
                        .foregroundColor(AdaptiveColors.secondaryText)
                }

                HStack(spacing: SpacingSystem.xs) {
                    ForEach(0...10, id: \.self) { score in
                        NPSButton(
                            score: score,
                            isSelected: response == "\(score)",
                            action: { response = "\(score)" }
                        )
                    }
                }
            }
        }
        .featureCardStyle()
    }
}

struct NPSButton: View {
    let score: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(score)")
                .font(TypographySystem.captionBold)
                .foregroundColor(isSelected ? .white : AdaptiveColors.primaryText)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? PrimaryColors.vibrantPurple : AdaptiveColors.glassBackground)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? PrimaryColors.vibrantPink : AdaptiveColors.glassBorder, lineWidth: isSelected ? 2 : 1)
                        )
                )
        }
    }
}

struct ChoiceButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(TypographySystem.bodyLarge)
                    .foregroundColor(AdaptiveColors.primaryText)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(PrimaryColors.vibrantGreen)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(SpacingSystem.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? PrimaryColors.vibrantGreen.opacity(0.1) : AdaptiveColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? PrimaryColors.vibrantGreen : AdaptiveColors.glassBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuestionText: View {
    let text: String
    let required: Bool

    init(_ text: String, required: Bool) {
        self.text = text
        self.required = required
    }

    var body: some View {
        HStack(alignment: .top, spacing: SpacingSystem.xs) {
            Text(text)
                .font(TypographySystem.headlineSmall)
                .foregroundColor(AdaptiveColors.primaryText)
                .multilineTextAlignment(.leading)

            if required {
                Text("*")
                    .font(TypographySystem.captionBold)
                    .foregroundColor(SemanticColors.warningPrimary)
            }
        }
    }
}

// MARK: - Survey Modal

struct SurveyModalView: View {
    @ObservedObject var feedbackManager = FeedbackManager.shared
    @State private var showSurvey = false

    var body: some View {
        EmptyView()
            .sheet(isPresented: $showSurvey) {
                if let survey = feedbackManager.currentSurvey {
                    SurveyEngine.shared.createSurveyView(for: survey)
                }
            }
            .onReceive(feedbackManager.$shouldShowSurvey) { shouldShow in
                showSurvey = shouldShow
            }
    }
}

// MARK: - Preview

struct SurveyView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSurvey = Survey(
            id: "sample",
            type: .nps,
            userId: "user123",
            questions: [
                SurveyQuestion(
                    id: "nps",
                    type: .nps,
                    question: "How likely are you to recommend Bookshelf Scanner?",
                    required: true,
                    options: Array(0...10).map { "\($0)" }
                )
            ],
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400),
            context: [:]
        )

        SurveyView(survey: sampleSurvey)
    }
}