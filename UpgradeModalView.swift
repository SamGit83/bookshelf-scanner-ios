import SwiftUI
import FirebaseAnalytics

struct UpgradeModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var abTestingService = ABTestingService.shared
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var variantConfig: UpgradeVariantConfig?

    enum SubscriptionPlan {
        case monthly, annual
    }

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundGradients.heroGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SpacingSystem.xl) {
                        headerSection
                        socialProofSection
                        featureComparisonSection
                        pricingSection
                        urgencySection
                        ctaSection
                    }
                    .padding(.vertical, SpacingSystem.xl)
                }
            }
            .navigationBarItems(trailing: closeButton)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadVariantConfig()
                trackModalView()
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: SpacingSystem.md) {
            ZStack {
                Circle()
                    .fill(PrimaryColors.vibrantPurple.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(PrimaryColors.vibrantPurple)
            }

            Text(variantConfig?.headline ?? "Unlock Premium Features")
                .font(TypographySystem.displayMedium)
                .foregroundColor(AdaptiveColors.primaryText)
                .multilineTextAlignment(.center)

            Text(variantConfig?.subheadline ?? "Join thousands of readers who have upgraded to unlock unlimited access to all features.")
                .font(TypographySystem.bodyLarge)
                .foregroundColor(AdaptiveColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingSystem.lg)
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var socialProofSection: some View {
        VStack(spacing: SpacingSystem.sm) {
            HStack(spacing: SpacingSystem.xs) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(AccentColors.neonYellow)
                        .font(.system(size: 16))
                }
                Text("4.9/5")
                    .font(TypographySystem.captionBold)
                    .foregroundColor(AdaptiveColors.primaryText)
            }

            Text(variantConfig?.socialProof ?? "\"This app has transformed how I organize my library!\"")
                .font(TypographySystem.bodyMedium)
                .foregroundColor(AdaptiveColors.primaryText)
                .italic()
                .multilineTextAlignment(.center)

            Text("- Sarah M., Premium User")
                .font(TypographySystem.captionMedium)
                .foregroundColor(AdaptiveColors.secondaryText)
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var featureComparisonSection: some View {
        VStack(spacing: SpacingSystem.lg) {
            Text("Why Upgrade?")
                .font(TypographySystem.headlineLarge)
                .foregroundColor(AdaptiveColors.primaryText)

            VStack(spacing: SpacingSystem.md) {
                FeatureComparisonRow(
                    icon: "camera.fill",
                    feature: "Unlimited AI Scans",
                    freeText: "\(UsageTracker.shared.variantScanLimit)/month",
                    premiumText: "Unlimited",
                    isPremium: true
                )

                FeatureComparisonRow(
                    icon: "book.fill",
                    feature: "Books in Library",
                    freeText: "\(UsageTracker.shared.variantBookLimit) books",
                    premiumText: "Unlimited",
                    isPremium: true
                )

                FeatureComparisonRow(
                    icon: "sparkles",
                    feature: "AI Recommendations",
                    freeText: "\(UsageTracker.shared.variantRecommendationLimit)/month",
                    premiumText: "Unlimited",
                    isPremium: true
                )

                FeatureComparisonRow(
                    icon: "chart.bar.fill",
                    feature: "Advanced Analytics",
                    freeText: "Basic",
                    premiumText: "Detailed Insights",
                    isPremium: true
                )

                FeatureComparisonRow(
                    icon: "square.and.arrow.up.fill",
                    feature: "Export Features",
                    freeText: "Limited",
                    premiumText: "Full Export",
                    isPremium: true
                )
            }
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var pricingSection: some View {
        VStack(spacing: SpacingSystem.lg) {
            Text("Choose Your Plan")
                .font(TypographySystem.headlineLarge)
                .foregroundColor(AdaptiveColors.primaryText)

            HStack(spacing: SpacingSystem.md) {
                PricingCard(
                    plan: .monthly,
                    price: variantConfig?.monthlyPrice ?? 2.99,
                    period: "month",
                    savings: nil,
                    isSelected: selectedPlan == .monthly,
                    action: { selectedPlan = .monthly }
                )

                PricingCard(
                    plan: .annual,
                    price: variantConfig?.annualPrice ?? 29.99,
                    period: "year",
                    savings: "Save 17%",
                    isSelected: selectedPlan == .annual,
                    action: { selectedPlan = .annual }
                )
            }
            .padding(.horizontal, SpacingSystem.lg)
        }
    }

    private var urgencySection: some View {
        VStack(spacing: SpacingSystem.sm) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(SemanticColors.warningPrimary)
                Text(variantConfig?.urgencyMessage ?? "Limited Time: 50% off your first month!")
                    .font(TypographySystem.bodyMedium)
                    .foregroundColor(SemanticColors.warningPrimary)
                    .bold()
            }

            Text("Offer ends in 24 hours")
                .font(TypographySystem.captionMedium)
                .foregroundColor(AdaptiveColors.secondaryText)
        }
        .padding(.horizontal, SpacingSystem.lg)
        .padding(.vertical, SpacingSystem.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.warningSecondary)
        )
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var ctaSection: some View {
        VStack(spacing: SpacingSystem.md) {
            Button(action: startSubscription) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(variantConfig?.ctaText ?? "Start Premium Trial")
                        .frame(maxWidth: .infinity)
                        .padding(SpacingSystem.lg)
                        .background(UIGradients.primaryButton)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .font(TypographySystem.buttonLarge)
                        .shadow(color: PrimaryColors.vibrantPink.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .disabled(isLoading)
            .padding(.horizontal, SpacingSystem.lg)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Maybe Later")
                    .font(TypographySystem.buttonMedium)
                    .foregroundColor(AdaptiveColors.secondaryText)
            }
        }
    }

    private var closeButton: some View {
        Button(action: {
            trackModalDismiss()
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(AdaptiveColors.primaryText)
                .font(.system(size: 16, weight: .medium))
        }
    }

    private func loadVariantConfig() {
        Task {
            guard let userId = AuthService.shared.currentUser?.id else { return }
            do {
                if let variant = try await abTestingService.getVariant(for: "upgrade_flow_experiment", userId: userId) {
                    variantConfig = UpgradeVariantConfig.fromVariant(variant)
                }
            } catch {
                print("Failed to load variant config: \(error)")
            }
        }
    }

    private func startSubscription() {
        isLoading = true
        trackCTAClick()

        // TODO: Integrate with RevenueCat
        // For now, simulate subscription process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            // Simulate success/failure
            if Bool.random() {
                trackSubscriptionSuccess()
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = "Subscription failed. Please try again."
                showError = true
                trackSubscriptionFailure()
            }
        }
    }

    // Analytics tracking
    private func trackModalView() {
        Analytics.logEvent("upgrade_modal_viewed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default"
        ])
    }

    private func trackModalDismiss() {
        Analytics.logEvent("upgrade_modal_dismissed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default"
        ])
    }

    private func trackCTAClick() {
        Analytics.logEvent("upgrade_cta_clicked", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "selected_plan": selectedPlan == .monthly ? "monthly" : "annual"
        ])
    }

    private func trackSubscriptionSuccess() {
        Analytics.logEvent("subscription_started", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "plan": selectedPlan == .monthly ? "monthly" : "annual"
        ])
    }

    private func trackSubscriptionFailure() {
        Analytics.logEvent("subscription_failed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "plan": selectedPlan == .monthly ? "monthly" : "annual"
        ])
    }
}

struct FeatureComparisonRow: View {
    let icon: String
    let feature: String
    let freeText: String
    let premiumText: String
    let isPremium: Bool

    var body: some View {
        HStack(spacing: SpacingSystem.md) {
            Image(systemName: icon)
                .foregroundColor(isPremium ? PrimaryColors.vibrantGreen : AdaptiveColors.secondaryText)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: SpacingSystem.xs) {
                Text(feature)
                    .font(TypographySystem.bodyMedium)
                    .foregroundColor(AdaptiveColors.primaryText)

                HStack {
                    Text(freeText)
                        .font(TypographySystem.captionMedium)
                        .foregroundColor(AdaptiveColors.secondaryText)

                    Image(systemName: "arrow.right")
                        .foregroundColor(AdaptiveColors.secondaryText)
                        .font(.system(size: 12))

                    Text(premiumText)
                        .font(TypographySystem.captionMedium)
                        .foregroundColor(PrimaryColors.vibrantGreen)
                        .bold()
                }
            }

            Spacer()

            if isPremium {
                Image(systemName: "crown.fill")
                    .foregroundColor(PrimaryColors.vibrantPurple)
                    .font(.system(size: 16))
            }
        }
        .padding(SpacingSystem.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.glassBackground)
        )
    }
}

struct PricingCard: View {
    let plan: UpgradeModalView.SubscriptionPlan
    let price: Double
    let period: String
    let savings: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: SpacingSystem.sm) {
                if let savings = savings {
                    Text(savings)
                        .font(TypographySystem.captionBold)
                        .foregroundColor(SemanticColors.successPrimary)
                        .padding(.horizontal, SpacingSystem.sm)
                        .padding(.vertical, SpacingSystem.xs)
                        .background(SemanticColors.successSecondary)
                        .cornerRadius(8)
                }

                Text("$\(String(format: "%.2f", price))")
                    .font(TypographySystem.displaySmall)
                    .foregroundColor(AdaptiveColors.primaryText)

                Text("per \(period)")
                    .font(TypographySystem.captionMedium)
                    .foregroundColor(AdaptiveColors.secondaryText)

                if plan == .annual {
                    Text("$\(String(format: "%.2f", price/12))/month")
                        .font(TypographySystem.captionSmall)
                        .foregroundColor(AdaptiveColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(SpacingSystem.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? UIGradients.primaryButton : AdaptiveColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? PrimaryColors.vibrantPink : AdaptiveColors.glassBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UpgradeVariantConfig {
    let variantId: String
    let headline: String
    let subheadline: String
    let socialProof: String
    let monthlyPrice: Double
    let annualPrice: Double
    let urgencyMessage: String
    let ctaText: String

    static func fromVariant(_ variant: Variant) -> UpgradeVariantConfig {
        let config = variant.config

        return UpgradeVariantConfig(
            variantId: variant.id,
            headline: config["headline"]?.value as? String ?? "Unlock Premium Features",
            subheadline: config["subheadline"]?.value as? String ?? "Join thousands of readers who have upgraded",
            socialProof: config["socialProof"]?.value as? String ?? "\"This app has transformed my library!\"",
            monthlyPrice: config["monthlyPrice"]?.value as? Double ?? 2.99,
            annualPrice: config["annualPrice"]?.value as? Double ?? 29.99,
            urgencyMessage: config["urgencyMessage"]?.value as? String ?? "Limited Time: Special offer!",
            ctaText: config["ctaText"]?.value as? String ?? "Start Premium Trial"
        )
    }
}

struct UpgradeModalView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeModalView()
    }
}