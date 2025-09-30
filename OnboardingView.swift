import SwiftUI
#if canImport(RevenueCat)
import RevenueCat
#endif

struct OnboardingView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @ObservedObject private var revenueCatManager = RevenueCatManager.shared
    @State private var currentPage = 0
    @State private var showMainApp = false
    @State private var selectedPeriod: String = "year"
    @State private var isPurchasing = false

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

                                if let offering = revenueCatManager.offerings["default"] ?? revenueCatManager.offerings["premium"] {
                                    // Billing Period Picker
                                    Picker("Billing Period", selection: $selectedPeriod) {
                                        Text("Monthly").tag("month")
                                        Text("Yearly").tag("year")
                                    }
                                    .pickerStyle(.segmented)
                                    .padding(AppleBooksSpacing.space8)

                                    // Find selected package
                                    if let package = offering.availablePackages.first(where: { pkg in
                                        let period = pkg.storeProduct.subscriptionPeriod?.unit.rawValue ?? ""
                                        return (selectedPeriod == "month" && period.contains("month")) || (selectedPeriod == "year" && period.contains("year"))
                                    }) {
                                        VStack(spacing: AppleBooksSpacing.space16) {
                                            Text(package.storeProduct.localizedTitle)
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.text)

                                            Text("\(package.storeProduct.price, specifier: "%.2f") \(package.storeProduct.currencyCode)/\(selectedPeriod == "month" ? "month" : "year")")
                                                .font(AppleBooksTypography.displayLarge)
                                                .foregroundColor(AppleBooksColors.accent)
                                                .bold()

                                            if selectedPeriod == "year" {
                                                let monthlyEquivalent = package.storeProduct.price.doubleValue / 12
                                                Text("Just \(monthlyEquivalent, specifier: "%.2f") per month")
                                                    .font(AppleBooksTypography.bodyLarge)
                                                    .foregroundColor(AppleBooksColors.textSecondary)
                                            }

                                            Button(action: {
                                                purchaseSubscription(package: package)
                                            }) {
                                                Text(isPurchasing ? "Processing..." : "Subscribe & Get Started")
                                                    .font(AppleBooksTypography.buttonLarge)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, AppleBooksSpacing.space16)
                                            }
                                            .disabled(isPurchasing || revenueCatManager.isSubscribed)
                                            .background(revenueCatManager.isSubscribed ? AppleBooksColors.textTertiary : AppleBooksColors.accent)
                                            .cornerRadius(12)
                                            .opacity(isPurchasing ? 0.7 : 1.0)

                                            if revenueCatManager.isSubscribed {
                                                Text("Already Premium - Tap to Continue")
                                                    .font(AppleBooksTypography.caption)
                                                    .foregroundColor(AppleBooksColors.textSecondary)
                                            } else {
                                                Button("Skip for Free Tier") {
                                                    completeOnboarding()
                                                }
                                                .font(AppleBooksTypography.buttonMedium)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                            }
                                        }
                                    } else {
                                        Text("Loading plans...")
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.textSecondary)
                                    }
                                } else {
                                    VStack(spacing: AppleBooksSpacing.space16) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .tint(AppleBooksColors.accent)

                                        Text("Loading subscription options...")
                                            .font(AppleBooksTypography.bodyLarge)
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

    private func purchaseSubscription(package: Package) {
        isPurchasing = true
        revenueCatManager.purchase(package: package) { result in
            DispatchQueue.main.async {
                self.isPurchasing = false
                switch result {
                case .success:
                    self.completeOnboarding()
                case .failure(let error):
                    print("Subscription purchase failed: \(error.localizedDescription)")
                    // Optionally show alert, but for now just log
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