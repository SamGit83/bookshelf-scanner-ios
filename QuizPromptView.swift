import SwiftUI

struct QuizPromptView: View {
    @State private var showQuiz = false
    @State private var showMainApp = false

    var body: some View {
        ZStack {
            // Clean Apple Books background
            AppleBooksColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AppleBooksSpacing.space24) {
                        Color.clear
                            .frame(height: AppleBooksSpacing.space32)

                        // Page Content in Apple Books Card
                        AppleBooksCard(
                            cornerRadius: 20,
                            padding: AppleBooksSpacing.space24,
                            shadowStyle: .medium
                        ) {
                            VStack(spacing: AppleBooksSpacing.space24) {
                                // Icon
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 80, weight: .light))
                                    .foregroundColor(AppleBooksColors.accent)
                                    .frame(height: 120)

                                // Text Content
                                VStack(spacing: AppleBooksSpacing.space16) {
                                    Text("Take the Profile Quiz")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(AppleBooksColors.text)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.8)

                                    Text("Help us personalize your reading experience by answering a few questions about your preferences.")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(AppleBooksColors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.8)
                                        .padding(.horizontal, AppleBooksSpacing.space16)
                                }
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        Color.clear
                            .frame(height: AppleBooksSpacing.space32)
                    }
                }

                // Action Buttons
                VStack(spacing: AppleBooksSpacing.space16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showQuiz = true
                        }
                    }) {
                        Text("Take Quiz")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppleBooksSpacing.space16)
                            .background(AppleBooksColors.accent)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showMainApp = true
                        }
                    }) {
                        Text("Skip for Now")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppleBooksColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
                .padding(.bottom, AppleBooksSpacing.space32)
            }
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
    }
}

// Preview
struct QuizPromptView_Previews: PreviewProvider {
    static var previews: some View {
        QuizPromptView()
    }
}