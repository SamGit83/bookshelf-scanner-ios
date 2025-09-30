import SwiftUI

struct SubscriptionOption {
    let name: String
    let price: String
    let period: String
}

struct OnboardingView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @State private var currentPage = 0
    @State private var showMainApp = false
    @State private var selectedOption = SubscriptionOption(name: "Yearly Premium", price: "$99.99", period: "year")
    @State private var showSuccess = false

    let subscriptionOptions: [SubscriptionOption] = [
        SubscriptionOption(name: "Monthly Premium", price: "$9.99", period: "month"),
        SubscriptionOption(name: "Yearly Premium", price: "$99.99", period: "year")
    ]

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Bookshelf Scanner",
            description: "Transform your physical book collection into a beautiful digital library with AI-powered recognition.",
            imageName: "books.vertical.fill",
            accentColor: AppleBooksColors.accent
        ),
        OnboardingPage(
            title: "Scan Your Books",
            description: "Point your camera at your bookshelf and watch as our AI identifies your books automatically.",
            imageName: "camera.fill",
            accentColor: AppleBooksColors.success
        ),
        OnboardingPage(
            title: "Build Your Library",
            description: "Organize your books into collections, track your reading progress, and discover new favorites.",
            imageName: "building.columns.fill",
            accentColor: AppleBooksColors.accent
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Set reading goals, log your sessions, and watch your reading habits come to life with detailed analytics.",
            imageName: "chart.bar.fill",
            accentColor: AppleBooksColors.success
        ),
        OnboardingPage(
            title: "Smart Recommendations",
            description: "Get personalized book suggestions based on your reading history and preferences.",
            imageName: "sparkles",
            accentColor: AppleBooksColors.promotional
        ),
        OnboardingPage(
            title: "Choose Your Plan",
            description: "Unlock premium features with a subscription. Select monthly or yearly for the best value.",
            imageName: "crown.fill",
            accentColor: AppleBooksColors.promotional
        )
    ]

    var body: some View {
        ZStack {
            // Clean Apple Books background
            AppleBooksColors.background
                .ignoresSafeArea()

            VStack(spacing: AppleBooksSpacing.space32) {
                Spacer()

                // Page Content in Apple Books Card
                AppleBooksCard(
                    cornerRadius: 20,
                    padding: AppleBooksSpacing.space32,
                    shadowStyle: .medium
                ) {
                    VStack(spacing: AppleBooksSpacing.space32) {
                        // Page Indicator
                        HStack(spacing: AppleBooksSpacing.space8) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPage ? pages[currentPage].accentColor : AppleBooksColors.textTertiary)
                                    .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                        }

                        if currentPage < pages.count - 1 {
                            // Icon
                            Image(systemName: pages[currentPage].imageName)
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(pages[currentPage].accentColor)
                                .frame(height: 120)

                            // Text Content
                            VStack(spacing: AppleBooksSpacing.space16) {
                                Text(pages[currentPage].title)
                                    .font(AppleBooksTypography.displayLarge)
                                    .foregroundColor(AppleBooksColors.text)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)

                                Text(pages[currentPage].description)
                                    .font(AppleBooksTypography.bodyLarge)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, AppleBooksSpacing.space16)
                            }
                        } else {
                            // Subscription Selection UI
                            VStack(spacing: AppleBooksSpacing.space24) {
                                Text("Unlock Premium")
                                    .font(AppleBooksTypography.displayLarge)
                                    .foregroundColor(AppleBooksColors.text)
                                    .multilineTextAlignment(.center)

                                Text("Choose your subscription plan to get unlimited scans and features.")
                                    .font(AppleBooksTypography.bodyLarge)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, AppleBooksSpacing.space16)

                                // Subscription Options Buttons
                                HStack(spacing: AppleBooksSpacing.space16) {
                                    ForEach(subscriptionOptions, id: \.period) { option in
                                        Button(action: {
                                            selectedOption = option
                                        }) {
                                            VStack(spacing: AppleBooksSpacing.space8) {
                                                Text(option.name)
                                                    .font(AppleBooksTypography.bodyLarge)
                                                    .foregroundColor(selectedOption.period == option.period ? AppleBooksColors.accent : AppleBooksColors.text)
                                                Text("\(option.price)/\(option.period)")
                                                    .font(AppleBooksTypography.headline)
                                                    .foregroundColor(selectedOption.period == option.period ? AppleBooksColors.accent : AppleBooksColors.textSecondary)
                                            }
                                            .padding(.vertical, AppleBooksSpacing.space16)
                                            .padding(.horizontal, AppleBooksSpacing.space24)
                                            .background(selectedOption.period == option.period ? AppleBooksColors.accent.opacity(0.1) : AppleBooksColors.card)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedOption.period == option.period ? AppleBooksColors.accent : Color.clear, lineWidth: 2)
                                            )
                                        }
                                    }
                                }
                                
                                VStack(spacing: AppleBooksSpacing.space16) {
                                    Text(selectedOption.name)
                                        .font(AppleBooksTypography.bodyLarge)
                                        .foregroundColor(AppleBooksColors.text)
                                    Text("\(selectedOption.price)/\(selectedOption.period)")
                                        .font(AppleBooksTypography.displayLarge)
                                        .foregroundColor(AppleBooksColors.accent)
                                        .bold()
                                    if selectedOption.period == "year" {
                                        Text("Just $8.33 per month")
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                    }
                                    Button(action: {
                                        showSuccess = true
                                    }) {
                                        Text("Subscribe & Get Started")
                                            .font(AppleBooksTypography.buttonLarge)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppleBooksSpacing.space16)
                                    }
                                    .background(AppleBooksColors.accent)
                                    .cornerRadius(12)
                                    if showSuccess {
                                        Text("Subscription successful!")
                                            .font(AppleBooksTypography.caption)
                                            .foregroundColor(AppleBooksColors.success)
                                    } else {
                                        Button("Skip for Free Tier") {
                                            completeOnboarding()
                                        }
                                        .font(AppleBooksTypography.buttonMedium)
                                        .foregroundColor(AppleBooksColors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)

                Spacer()

                // Navigation Buttons
                HStack(spacing: AppleBooksSpacing.space16) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }) {
                            Text("Previous")
                                .font(AppleBooksTypography.buttonMedium)
                                .foregroundColor(AppleBooksColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(AppleBooksColors.card)
                                .cornerRadius(12)
                        }
                    } else {
                        Spacer()
                    }

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(AppleBooksTypography.buttonLarge)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(pages[currentPage].accentColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
                .padding(.bottom, AppleBooksSpacing.space48)
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
    }

    private func completeOnboarding() {
        authService.completeOnboarding()
        withAnimation(.easeInOut(duration: 0.5)) {
            showMainApp = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let accentColor: Color
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}