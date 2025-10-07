import SwiftUI

struct SubscriptionOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let price: String
    let period: String
}

struct OnboardingView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @State private var currentPage = 0
    @State private var showMainApp = false
    @State private var selectedOption: SubscriptionOption? = nil
    @State private var showSuccess = false
    @State private var showWaitlistModal = false

    let subscriptionOptions: [SubscriptionOption] = [
        SubscriptionOption(name: "Monthly Premium", price: "$9.99", period: "month"),
        SubscriptionOption(name: "Yearly Premium", price: "$99.99", period: "year")
    ]

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Book Shelfie",
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
                                // Page Indicator
                                HStack(spacing: AppleBooksSpacing.small) {
                                    ForEach(0..<pages.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentPage ? pages[currentPage].accentColor : AppleBooksColors.textTertiary)
                                            .frame(width: index == currentPage ? 10 : 8,
                                                   height: index == currentPage ? 10 : 8)
                                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                                    }
                                }
                                .padding(.top, AppleBooksSpacing.small)

                                if currentPage < pages.count - 1 {
                                    // Icon
                                    Image(systemName: pages[currentPage].imageName)
                                        .font(.system(size: 80, weight: .light))
                                        .foregroundColor(pages[currentPage].accentColor)
                                        .frame(height: 120)

                                    // Text Content
                                    VStack(spacing: AppleBooksSpacing.space16) {
                                        Text(pages[currentPage].title)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(AppleBooksColors.text)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .minimumScaleFactor(0.8)

                                        Text(pages[currentPage].description)
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .minimumScaleFactor(0.8)
                                            .padding(.horizontal, AppleBooksSpacing.space16)
                                    }
                                } else {
                                    SubscriptionSelectionView(
                                        selectedOption: $selectedOption,
                                        showSuccess: $showSuccess,
                                        showWaitlistModal: $showWaitlistModal,
                                        subscriptionOptions: subscriptionOptions,
                                        completeOnboarding: completeOnboarding
                                    )
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
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
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

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(pages[currentPage].accentColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
                .padding(.bottom, AppleBooksSpacing.space32)
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
        .sheet(isPresented: $showWaitlistModal) {
            WaitlistModal(
                initialFirstName: "",
                initialLastName: "",
                initialEmail: "",
                initialUserId: nil
            )
        }
    }

    private func completeOnboarding() {
        authService.completeOnboarding()
        withAnimation(.easeInOut(duration: 0.5)) {
            showMainApp = true
        }
    }
}

struct SubscriptionSelectionView: View {
    @Binding var selectedOption: SubscriptionOption?
    @Binding var showSuccess: Bool
    @Binding var showWaitlistModal: Bool
    let subscriptionOptions: [SubscriptionOption]
    let completeOnboarding: () -> Void

    var body: some View {
        VStack(spacing: AppleBooksSpacing.space24) {
            Text("Unlock Premium")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppleBooksColors.text)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)

            Text("Premium features coming soon! Sign up for Free tier now to get started with basic features.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, AppleBooksSpacing.space16)

            Text("Premium Coming Soon")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppleBooksColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, AppleBooksSpacing.space16)

            HStack(spacing: AppleBooksSpacing.space16) {
                SubscriptionButton(option: subscriptionOptions[0], selectedOption: $selectedOption)
                SubscriptionButton(option: subscriptionOptions[1], selectedOption: $selectedOption)
            }
            .frame(height: 200)

            VStack(spacing: AppleBooksSpacing.space16) {
                Text("Free Tier Selected")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppleBooksColors.text)
                    .lineLimit(nil)
                
                Text("Free Forever")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppleBooksColors.success)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)
                
                if selectedOption?.period == "year" {
                    Text("Just $8.33 per month")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppleBooksColors.textSecondary)
                        .lineLimit(nil)
                }
                
                Button(action: {
                    // Disabled for premium coming soon
                }) {
                    Text("Premium Coming Soon")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppleBooksColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppleBooksSpacing.space16)
                }
                .background(AppleBooksColors.card)
                .cornerRadius(12)
                .disabled(true)

                AppleBooksCard(
                    cornerRadius: 12,
                    padding: AppleBooksSpacing.space16,
                    shadowStyle: .subtle
                ) {
                    VStack(spacing: AppleBooksSpacing.small) {
                        Text("Premium Coming Soon")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppleBooksColors.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)

                        let premiumFeatures = [
                            "Unlimited book scans",
                            "Advanced analytics",
                            "AI-powered recommendations"
                        ]

                        VStack(alignment: .leading, spacing: AppleBooksSpacing.small) {
                            ForEach(premiumFeatures, id: \.self) { feature in
                                HStack(spacing: AppleBooksSpacing.small) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppleBooksColors.success)
                                        .font(.system(size: 12, weight: .medium))

                                    Text(feature)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(AppleBooksColors.textSecondary)
                                        .lineLimit(nil)

                                    Spacer()
                                }
                            }
                        }

                        Button(action: {
                            showWaitlistModal = true
                        }) {
                            Text("Join Waitlist")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppleBooksColors.promotional)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, AppleBooksSpacing.space16)
                
                if showSuccess {
                    Text("Subscription successful!")
                        .font(.system(size: 12))
                        .foregroundColor(AppleBooksColors.success)
                        .lineLimit(nil)
                } else {
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Skip for Free Tier")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppleBooksColors.textSecondary)
                    }
                }
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let accentColor: Color
}

struct SubscriptionButton: View {
    let option: SubscriptionOption
    @Binding var selectedOption: SubscriptionOption?

    private var isSelected: Bool {
        selectedOption == option
    }

    var body: some View {
        Button(action: {
            selectedOption = option
        }) {
            VStack(spacing: 12) {
                // Savings badge for yearly plan
                if option.period == "year" {
                    Text("Save 17%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppleBooksColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppleBooksColors.success.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Color.clear.frame(height: 20)
                }

                // Best Value badge for yearly plan
                if option.period == "year" {
                    Text("BEST VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppleBooksColors.promotional)
                        .cornerRadius(6)
                }

                // Price display
                Text(option.price)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? AppleBooksColors.accent : AppleBooksColors.text)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("per \(option.period)")
                    .font(.system(size: 12))
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .lineLimit(nil)

                // Monthly equivalent for yearly plan
                if option.period == "year" {
                    Text("$8.33/month")
                        .font(.system(size: 11))
                        .foregroundColor(AppleBooksColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                } else {
                    Color.clear.frame(height: 10)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(isSelected ? AppleBooksColors.accent.opacity(0.1) : AppleBooksColors.card)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppleBooksColors.accent : Color.clear, lineWidth: isSelected ? 3 : 0)
            )
            .shadow(color: isSelected ? AppleBooksColors.accent.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 5, x: 0, y: isSelected ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
