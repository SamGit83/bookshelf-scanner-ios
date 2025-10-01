import SwiftUI
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
import FirebaseFirestore

struct UpgradeModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var abTestingService = ABTestingService.shared
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var variantConfig: UpgradeVariantConfig?
    @State private var email = ""
    @State private var showEmailInput = false
    @State private var isSubmitting = false
    @State private var showEmailError = false
    @State private var showSuccess = false

    enum SubscriptionPlan {
        case monthly, annual
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        // Premium Coming Soon Banner
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(SemanticColors.warningPrimary.opacity(0.8))
                            
                            Text("Premium Coming Soon")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Stay tuned for unlimited scans, advanced analytics, and exclusive features! We'll notify you when Premium is available.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(24)
                        .glassBackground()
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(SemanticColors.warningPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Premium Coming Soon Banner")
                        
                        socialProofSection
                        featureComparisonSection
                        pricingSection
                        urgencySection
                        ctaSection
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarItems(trailing: closeButton)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("DEBUG UpgradeModal: Modal presented")
                loadVariantConfig()
                trackModalView()
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 120, height: 120)
                    .glassBackground()

                Image(systemName: "crown.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(Color.gray)
                    .accessibilityLabel("Premium Crown Icon")
            }

            Text(variantConfig?.headline ?? "Unlock Premium Features")
                .font(.largeTitle)
                .foregroundColor(Color.primary)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Headline: Unlock Premium Features")

            Text(variantConfig?.subheadline ?? "Join thousands of readers who have upgraded to unlock unlimited access to all features.")
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilityLabel("Subheadline: Join thousands of readers who have upgraded")
        }
        .padding(.horizontal, 16)
        .glassBackground()
        .accessibilityElement(children: .combine)
    }

    private var socialProofSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.gray.opacity(0.5))
                        .font(.system(size: 16))
                }
                Text("4.9/5")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.primary)
            }

            Text(variantConfig?.socialProof ?? "\"This app has transformed how I organize my library!\"")
                .font(.body)
                .foregroundColor(Color.primary)
                .italic()
                .multilineTextAlignment(.center)

            Text("- Sarah M., Premium User")
                .font(.caption)
                .foregroundColor(Color.secondary)
        }
        .padding(.horizontal, 16)
        .glassBackground()
        .accessibilityLabel("Social Proof: 4.9/5 rating, quote from Sarah M.")
    }

    private var featureComparisonSection: some View {
        VStack(spacing: 24) {
            Text("Why Upgrade?")
                .font(.title2)
                .foregroundColor(Color.primary)
                .accessibilityLabel("Why Upgrade Section")

            VStack(spacing: 16) {
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
        .padding(.horizontal, 16)
        .glassBackground()
        .accessibilityElement(children: .combine)
    }

    private var pricingSection: some View {
        VStack(spacing: 24) {
            Text("Choose Your Plan")
                .font(.title2)
                .foregroundColor(Color.primary)
                .accessibilityLabel("Choose Your Plan Section")

            HStack(spacing: 16) {
                PricingCard(
                    plan: .monthly,
                    price: variantConfig?.monthlyPrice ?? 2.99,
                    period: "month",
                    savings: nil,
                    isSelected: selectedPlan == .monthly,
                    action: {
                        // Premium coming soon - no action
                        print("DEBUG UpgradeModalView: Premium coming soon - monthly plan tap ignored")
                    }
                )

                PricingCard(
                    plan: .annual,
                    price: variantConfig?.annualPrice ?? 29.99,
                    period: "year",
                    savings: "Save 17%",
                    isSelected: selectedPlan == .annual,
                    action: {
                        // Premium coming soon - no action
                        print("DEBUG UpgradeModalView: Premium coming soon - annual plan tap ignored")
                    }
                )
            }
            .padding(.horizontal, 16)
        }
        .glassBackground()
        .accessibilityElement(children: .combine)
    }

    private var urgencySection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color.orange)
                Text(variantConfig?.urgencyMessage ?? "Limited Time: 50% off your first month!")
                    .font(.body)
                    .foregroundColor(Color.orange)
                    .bold()
            }

            Text("Offer ends in 24 hours")
                .font(.caption)
                .foregroundColor(Color.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .padding(.horizontal, 16)
        .glassBackground()
        .accessibilityLabel("Urgency: Limited Time Offer ends in 24 hours")
    }

    private var ctaSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showEmailInput = true
            }) {
                Text("Join Waitlist")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 32)
                    .background(
                        LinearGradient(
                            colors: [PrimaryColors.vibrantPurple, PrimaryColors.vibrantPurple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .font(.headline.weight(.semibold))
                    .shadow(color: PrimaryColors.vibrantPurple.opacity(0.4), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .accessibilityLabel("Join Waitlist Button")

            if showEmailInput {
                VStack(spacing: 16) {
                    Text("Enter your email to join the Premium waitlist")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    TextField("your.email@example.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .glassFieldStyle(isValid: !showEmailError)

                    if showEmailError {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundColor(SemanticColors.errorPrimary)
                    }

                    Button(action: {
                        if email.contains("@") && !email.isEmpty {
                            showEmailError = false
                            isSubmitting = true
                            Task {
                                do {
                                    try await AuthService.shared.joinWaitlist(email: email)
                                    isSubmitting = false
                                    showSuccess = true
                                    email = ""
                                    showEmailInput = false
                                } catch {
                                    isSubmitting = false
                                    showEmailError = true
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        } else {
                            showEmailError = true
                        }
                    }) {
                        Text(isSubmitting ? "Joining..." : "Join Waitlist")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    colors: [PrimaryColors.vibrantPurple, PrimaryColors.vibrantPurple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline.weight(.semibold))
                    }
                    .disabled(isSubmitting || email.isEmpty)
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        showEmailInput = false
                        email = ""
                        showEmailError = false
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .glassBackground()
                .cornerRadius(16)
            }

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Maybe Later")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Maybe Later Button")
        }
        .glassBackground()
        .alert(isPresented: $showSuccess) {
            Alert(
                title: Text("Success"),
                message: Text("Thanks for joining the waitlist! We'll notify you when Premium is available."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
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
            print("DEBUG UpgradeModal: Loading variant config for user \(AuthService.shared.currentUser?.id ?? "nil")")
            guard let userId = AuthService.shared.currentUser?.id else {
                print("DEBUG UpgradeModal: No user ID, skipping variant load")
                return
            }
            do {
                if let variant = try await abTestingService.getVariant(for: "upgrade_flow_experiment", userId: userId) {
                    variantConfig = UpgradeVariantConfig.fromVariant(variant)
                    print("DEBUG UpgradeModal: Loaded variant \(variant.id)")
                } else {
                    print("DEBUG UpgradeModal: No variant assigned")
                }
            } catch {
                print("DEBUG UpgradeModal: Failed to load variant config: \(error)")
            }
        }
    }

    private func startSubscription() {
        print("DEBUG UpgradeModal: Premium coming soon - subscription attempt ignored for plan \(selectedPlan)")
        isLoading = false
        errorMessage = "Premium features are coming soon! Stay tuned for updates."
        showError = true
        trackCTAClick() // Keep analytics if needed, but no backend
        // No purchase or backend calls
    }

    // Analytics tracking
    private func trackModalView() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("upgrade_modal_viewed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default"
        ])
        #endif
    }

    private func trackModalDismiss() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("upgrade_modal_dismissed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default"
        ])
        #endif
    }

    private func trackCTAClick() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("upgrade_cta_clicked", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "selected_plan": selectedPlan == .monthly ? "monthly" : "annual"
        ])
        #endif
    }

    private func trackSubscriptionSuccess() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_started", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "plan": selectedPlan == .monthly ? "monthly" : "annual"
        ])
        #endif
    }

    private func trackSubscriptionFailure() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_failed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "plan": selectedPlan == .monthly ? "monthly" : "annual"
        ])
        #endif
    }
}

struct FeatureComparisonRow: View {
    let icon: String
    let feature: String
    let freeText: String
    let premiumText: String
    let isPremium: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(isPremium ? Color.green : Color.secondary)
                .frame(width: 24, height: 24)
                .accessibilityLabel("\(feature) Icon")

            VStack(alignment: .leading, spacing: 4) {
                Text(feature)
                    .font(.body)
                    .foregroundColor(Color.primary)

                HStack {
                    Text(freeText)
                        .font(.caption)
                        .foregroundColor(Color.secondary)

                    Image(systemName: "arrow.right")
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 12))

                    Text(premiumText)
                        .font(.caption)
                        .foregroundColor(Color.green)
                        .bold()
                }
            }

            Spacer()

            if isPremium {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.orange)
                    .font(.system(size: 16))
                    .accessibilityLabel("Premium Feature")
            }
        }
        .padding(16)
        .glassBackground()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
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
            VStack(spacing: 12) {
                if let savings = savings {
                    Text(savings)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Spacer(minLength: 20) // Balance height for monthly card
                }

                Text("$\(String(format: "%.2f", price))")
                    .font(.largeTitle)
                    .foregroundColor(Color.primary)
                    .bold()
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("per \(period)")
                    .font(.caption)
                    .foregroundColor(Color.secondary)

                if plan == .annual {
                    Text("$\(String(format: "%.2f", price/12))/month")
                        .font(.caption2)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                } else {
                    Spacer(minLength: 10) // Additional balance
                }
            }
            .frame(maxWidth: .infinity, minHeight: 140) // Fixed height for consistency
            .padding(24)
            .glassBackground()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
            .background(isSelected ? Color.orange.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(period.capitalized) Plan: $\(price) per \(period)")
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