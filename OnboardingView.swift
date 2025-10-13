import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    private var horizontalPadding: CGFloat {
        isIPad ? 48 : 24
    }
    
    private var maxContentWidth: CGFloat {
        if isIPad {
            #if canImport(UIKit)
            let screenWidth = UIScreen.main.bounds.width
            #else
            let screenWidth: CGFloat = 1024
            #endif
            return min(screenWidth - 160, 900) // wider card on iPad to reduce side dead space
        } else {
            return .infinity
        }
    }
    
    private var cardMinHeight: CGFloat? {
        isIPad ? 560 : nil // taller card on iPad to reduce vertical dead space
    }

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
                                HStack(spacing: AppleBooksSpacing.space8) {
                                    ForEach(0..<pages.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentPage ? pages[currentPage].accentColor : AppleBooksColors.textTertiary)
                                            .frame(
                                                width: index == currentPage ? (isIPad ? 12 : 10) : (isIPad ? 10 : 8),
                                                height: index == currentPage ? (isIPad ? 12 : 10) : (isIPad ? 10 : 8)
                                            )
                                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                                    }
                                }
                                .padding(.top, AppleBooksSpacing.space8)

                                if currentPage < pages.count - 1 {
                                    // Icon
                                    Image(systemName: pages[currentPage].imageName)
                                        .font(.system(size: isIPad ? 120 : 80, weight: .light))
                                        .foregroundColor(pages[currentPage].accentColor)
                                        .frame(height: isIPad ? 160 : 120)

                                    // Text Content
                                    VStack(spacing: AppleBooksSpacing.space16) {
                                        Text(pages[currentPage].title)
                                            .font(.system(size: isIPad ? 34 : 28, weight: .bold))
                                            .foregroundColor(AppleBooksColors.text)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .minimumScaleFactor(0.8)

                                        Text(pages[currentPage].description)
                                            .font(.system(size: isIPad ? 18 : 16, weight: .regular))
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
                        .frame(minHeight: cardMinHeight)
                        .frame(maxWidth: maxContentWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalPadding)

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
                                .frame(maxWidth: isIPad ? 300 : .infinity)
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
                                .frame(maxWidth: isIPad ? 300 : .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(pages[currentPage].accentColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, AppleBooksSpacing.space32)
            }
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
    }
}

struct SubscriptionSelectionView: View {
    @Binding var selectedOption: SubscriptionOption?
    @Binding var showSuccess: Bool
    @Binding var showWaitlistModal: Bool
    let subscriptionOptions: [SubscriptionOption]
    let completeOnboarding: () -> Void
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

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
                    .frame(maxWidth: isIPad ? 300 : .infinity)
                SubscriptionButton(option: subscriptionOptions[1], selectedOption: $selectedOption)
                    .frame(maxWidth: isIPad ? 300 : .infinity)
            }
            .frame(height: 200)
            .frame(maxWidth: isIPad ? 650 : .infinity)

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
                        .padding(.vertical, AppleBooksSpacing.space16)
                }
                .frame(maxWidth: isIPad ? 500 : .infinity)
                .frame(maxWidth: .infinity)
                .background(AppleBooksColors.card)
                .cornerRadius(12)
                .disabled(true)
                AppleBooksCard(
                    cornerRadius: 12,
                    padding: AppleBooksSpacing.space16,
                    shadowStyle: .subtle
                ) {
                    VStack(spacing: AppleBooksSpacing.space8) {
                        Text("FREE Tier Features")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)

                        let freeFeatures = [
                            "Ad-free experience",
                            "Basic bookshelf scanning (20 scans/month)",
                            "Manual book addition (25 books limit)",
                            "Reading progress tracking",
                            "Offline functionality",
                            "Cross-device synchronization",
                            "Books metadata and AI features (5 recommendations/month)"
                        ]

                        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                            ForEach(freeFeatures, id: \.self) { feature in
                                HStack(spacing: AppleBooksSpacing.space8) {
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
                    }
                }
                .frame(maxWidth: isIPad ? 600 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.top, AppleBooksSpacing.space16)


                AppleBooksCard(
                    cornerRadius: 12,
                    padding: AppleBooksSpacing.space16,
                    shadowStyle: .subtle
                ) {
                    VStack(spacing: AppleBooksSpacing.space8) {
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

                        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                            ForEach(premiumFeatures, id: \.self) { feature in
                                HStack(spacing: AppleBooksSpacing.space8) {
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
                .frame(maxWidth: isIPad ? 600 : .infinity)
                .frame(maxWidth: .infinity)
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
                    .frame(maxWidth: isIPad ? 500 : .infinity)
                    .frame(maxWidth: .infinity)
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
                    .lineLimit(nil)

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
                        .lineLimit(nil)
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
