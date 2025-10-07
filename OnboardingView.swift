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

    private var pageContent: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let indicatorSpacing = max(8.0, width * 0.02)
            let indicatorSize = max(8.0, width * 0.02)
            let activeIndicatorSize = indicatorSize * 1.25
            let contentSpacing = max(24.0, height * 0.04)
            let iconSize = min(80.0, width * 0.2)
            let iconHeight = min(120.0, height * 0.15)
            let textSpacing = max(16.0, height * 0.03)
            let titleSize = min(28.0, width * 0.08)
            let descSize = min(16.0, width * 0.045)
            let textHPadding = max(16.0, width * 0.05)
            let lineSpacingTitle = max(4.0, titleSize * 0.15)
            let lineSpacingDesc = max(3.0, descSize * 0.2)

            VStack(spacing: contentSpacing) {
                // Page Indicator
                HStack(spacing: indicatorSpacing) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].accentColor : AppleBooksColors.textTertiary)
                            .frame(width: index == currentPage ? activeIndicatorSize : indicatorSize,
                                   height: index == currentPage ? activeIndicatorSize : indicatorSize)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, max(8.0, height * 0.01))

                if currentPage < pages.count - 1 {
                    // Icon
                    Image(systemName: pages[currentPage].imageName)
                        .font(.system(size: iconSize, weight: .light))
                        .foregroundColor(pages[currentPage].accentColor)
                        .frame(height: iconHeight)

                    // Text Content
                    VStack(spacing: textSpacing) {
                        Text(pages[currentPage].title)
                            .font(.system(size: titleSize, weight: .bold))
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .lineSpacing(lineSpacingTitle)

                        Text(pages[currentPage].description)
                            .font(.system(size: descSize, weight: .regular))
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .lineSpacing(lineSpacingDesc)
                            .padding(.horizontal, textHPadding)
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
    }

    private var navigationButtons: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let hSpacing = max(16.0, width * 0.04)
            let buttonFontSize = min(17.0, width * 0.048)
            let buttonVPad = max(16.0, width * 0.045)
            let hPad = max(24.0, width * 0.06)
            let bottomPad = max(48.0, width * 0.11)

            HStack(spacing: hSpacing) {
                if currentPage > 0 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }) {
                        Text("Previous")
                            .font(.system(size: buttonFontSize, weight: .medium))
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonVPad)
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
                            .font(.system(size: buttonFontSize, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonVPad)
                            .background(pages[currentPage].accentColor)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, hPad)
            .padding(.bottom, bottomPad)
        }
    }

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
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let vSpacing = max(32.0, screenHeight * 0.045)
            let topPad = max(40.0, screenHeight * 0.06)
            let contentBottomPad = max(40.0, screenHeight * 0.06)
            let cardCornerRadius = max(20.0, screenWidth * 0.05)
            let cardInnerPadding = max(32.0, screenWidth * 0.08)
            let hPadForCard = max(24.0, screenWidth * 0.06)

            ZStack {
                // Clean Apple Books background
                AppleBooksColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: vSpacing) {
                            Color.clear
                                .frame(height: topPad)

                            // Page Content in Apple Books Card
                            AppleBooksCard(
                                cornerRadius: cardCornerRadius,
                                padding: cardInnerPadding,
                                shadowStyle: .medium
                            ) {
                                pageContent
                            }
                            .padding(.horizontal, hPadForCard)

                            Color.clear
                                .frame(height: contentBottomPad)
                        }
                    }

                    navigationButtons
                }
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
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let mainSpacing = max(24.0, height * 0.04)
            let textHPad = max(16.0, width * 0.045)
            let titleSize = min(32.0, width * 0.085)
            let bodySize = min(17.0, width * 0.048)
            let smallSize = min(15.0, width * 0.042)
            let captionSize = min(12.0, width * 0.035)
            let hSpacingButtons = max(16.0, width * 0.045)
            let buttonVPadMain = max(16.0, height * 0.022)
            let detailSpacing = max(16.0, height * 0.025)
            let topPadForDetails = max(16.0, height * 0.025)
            let premiumCardCorner = max(12.0, width * 0.03)
            let premiumCardPadding = max(16.0, width * 0.045)
            let premiumTitleSize = min(15.0, width * 0.042)
            let featureSpacing = max(8.0, height * 0.015)
            let featureHSpacing = max(8.0, width * 0.025)
            let checkmarkSize = min(12.0, width * 0.035)
            let featureTextSize = min(14.0, width * 0.04)
            let waitlistButtonVPad = max(12.0, height * 0.018)
            let waitlistFontSize = min(15.0, width * 0.042)

            VStack(spacing: mainSpacing) {
                Text("Unlock Premium")
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundColor(AppleBooksColors.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)

                Text("Premium features coming soon! Sign up for Free tier now to get started with basic features.")
                    .font(.system(size: bodySize, weight: .regular))
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, textHPad)

                Text("Premium Coming Soon")
                    .font(.system(size: smallSize, weight: .medium))
                    .foregroundColor(AppleBooksColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, textHPad)

                HStack(spacing: hSpacingButtons) {
                    SubscriptionButton(option: subscriptionOptions[0], selectedOption: $selectedOption)
                    SubscriptionButton(option: subscriptionOptions[1], selectedOption: $selectedOption)
                }

                VStack(spacing: detailSpacing) {
                    Text("Free Tier Selected")
                        .font(.system(size: bodySize, weight: .regular))
                        .foregroundColor(AppleBooksColors.text)
                    Text("Free Forever")
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(AppleBooksColors.success)
                    if selectedOption?.period == "year" {
                        Text("Just $8.33 per month")
                            .font(.system(size: bodySize, weight: .regular))
                            .foregroundColor(AppleBooksColors.textSecondary)
                    }
                    Button(action: {
                        // Disabled for premium coming soon
                    }) {
                        Text("Premium Coming Soon")
                            .font(.system(size: bodySize, weight: .medium))
                            .foregroundColor(AppleBooksColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonVPadMain)
                    }
                    .background(AppleBooksColors.card)
                    .cornerRadius(12)
                    .disabled(true)

                    AppleBooksCard(
                        cornerRadius: premiumCardCorner,
                        padding: premiumCardPadding,
                        shadowStyle: .subtle
                    ) {
                        VStack(spacing: featureSpacing) {
                            Text("Premium Coming Soon")
                                .font(.system(size: premiumTitleSize, weight: .medium))
                                .foregroundColor(AppleBooksColors.textTertiary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)

                            let premiumFeatures = [
                                "Unlimited book scans",
                                "Advanced analytics",
                                "AI-powered recommendations"
                            ]

                            VStack(alignment: .leading, spacing: featureSpacing) {
                                ForEach(premiumFeatures, id: \.self) { feature in
                                    HStack(spacing: featureHSpacing) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppleBooksColors.success)
                                            .font(.system(size: checkmarkSize, weight: .medium))

                                        Text(feature)
                                            .font(.system(size: featureTextSize, weight: .regular))
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
                                    .font(.system(size: waitlistFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, waitlistButtonVPad)
                                    .background(AppleBooksColors.promotional)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.top, topPadForDetails)
                    if showSuccess {
                        Text("Subscription successful!")
                            .font(.system(size: captionSize))
                            .foregroundColor(AppleBooksColors.success)
                    } else {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip for Free Tier")
                                .font(.system(size: smallSize, weight: .medium))
                                .foregroundColor(AppleBooksColors.textSecondary)
                        }
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

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

struct SubscriptionButton: View {
    let option: SubscriptionOption
    @Binding var selectedOption: SubscriptionOption?

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let vStackSpacing = max(12.0, height * 0.08)
            let priceSize = min(32.0, width * 0.12)
            let periodSize = min(12.0, width * 0.035)
            let monthlySize = min(11.0, width * 0.032)
            let saveBadgeSize = min(12.0, width * 0.04)
            let bestValueSize = min(10.0, width * 0.03)
            let paddingInner = max(20.0, width * 0.08)
            let minHeight = max(160.0, height * 0.3)
            let cornerRadius = max(16.0, width * 0.05)
            let shadowRadius = isSelected ? 8 : 5
            let shadowY = isSelected ? 4 : 2
            let saveHPad = max(8.0, width * 0.025)
            let saveVPad = max(4.0, height * 0.01)
            let bestHPad = max(8.0, width * 0.025)
            let bestVPad = max(3.0, height * 0.008)
            let spacerHeightSave = max(20.0, height * 0.05)
            let spacerHeightMonthly = max(10.0, height * 0.025)

            Button(action: {
                selectedOption = option
            }) {
                VStack(spacing: vStackSpacing) {
                    // Savings badge for yearly plan
                    if option.period == "year" {
                        Text("Save 17%")
                            .font(.system(size: saveBadgeSize, weight: .semibold))
                            .foregroundColor(AppleBooksColors.success)
                            .padding(.horizontal, saveHPad)
                            .padding(.vertical, saveVPad)
                            .background(AppleBooksColors.success.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Color.clear.frame(height: spacerHeightSave) // Balance height for monthly card
                    }

                    // Best Value badge for yearly plan
                    if option.period == "year" {
                        Text("BEST VALUE")
                            .font(.system(size: bestValueSize, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, bestHPad)
                            .padding(.vertical, bestVPad)
                            .background(AppleBooksColors.promotional)
                            .cornerRadius(6)
                    }

                    // Price display
                    Text(option.price)
                        .font(.system(size: priceSize, weight: .bold))
                        .foregroundColor(isSelected ? AppleBooksColors.accent : AppleBooksColors.text)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text("per \(option.period)")
                        .font(.system(size: periodSize))
                        .foregroundColor(AppleBooksColors.textSecondary)

                    // Monthly equivalent for yearly plan
                    if option.period == "year" {
                        Text("$8.33/month")
                            .font(.system(size: monthlySize))
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    } else {
                        Color.clear.frame(height: spacerHeightMonthly) // Additional balance
                    }
                }
                .frame(maxWidth: .infinity, minHeight: minHeight) // Fixed height for consistency
                .padding(paddingInner)
                .background(isSelected ? AppleBooksColors.accent.opacity(0.1) : AppleBooksColors.card)
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(isSelected ? AppleBooksColors.accent : Color.clear, lineWidth: isSelected ? 3 : 0)
                )
                .shadow(color: isSelected ? AppleBooksColors.accent.opacity(0.3) : Color.black.opacity(0.05), radius: shadowRadius, x: 0, y: shadowY)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var isSelected: Bool {
        selectedOption == option
    }
}
