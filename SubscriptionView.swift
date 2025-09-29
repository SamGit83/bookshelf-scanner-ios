import SwiftUI
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(RevenueCat)
import RevenueCat
#endif

struct SubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var abTestingService = ABTestingService.shared
    @ObservedObject var revenueCatManager = RevenueCatManager.shared
    @State private var offerings: [SubscriptionOffering] = []
    @State private var selectedPackage: SubscriptionPackage?
    @State private var isLoading = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var variantConfig: SubscriptionVariantConfig?

    var body: some View {
        NavigationView {
            ZStack {
                AppleBooksColors.background
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: SpacingSystem.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading subscription options...")
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: SpacingSystem.xl) {
                            headerSection
                            currentPlanSection
                            offeringsSection
                            featuresSection
                            faqSection
                            restorePurchasesSection
                        }
                        .padding(.vertical, SpacingSystem.xl)
                    }
                }
            }
            .navigationBarTitle("Premium Subscription", displayMode: .large)
            .navigationBarItems(trailing: closeButton)
            .onAppear {
                loadVariantConfig()
                loadOfferings()
                trackView()
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
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(PrimaryColors.vibrantPurple)
            }

            Text(variantConfig?.headerTitle ?? "Unlock Unlimited Access")
                .font(AppleBooksTypography.displayLarge)
                .foregroundColor(AppleBooksColors.text)
                .multilineTextAlignment(.center)

            Text(variantConfig?.headerSubtitle ?? "Get unlimited scans, recommendations, and premium features")
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)

            // Social proof badges
            HStack(spacing: SpacingSystem.sm) {
                SocialProofBadge(count: "10,000+", label: "Happy Readers")
                SocialProofBadge(count: "4.9★", label: "App Store Rating")
                SocialProofBadge(count: "95%", label: "Satisfaction")
            }
            .padding(.top, SpacingSystem.sm)
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var currentPlanSection: some View {
        Group {
            if revenueCatManager.isSubscribed, let subscription = revenueCatManager.getSubscriptionInfo() {
                AppleBooksCard {
                    VStack(spacing: SpacingSystem.md) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(SemanticColors.successPrimary)
                            Text("Current Plan")
                                .font(AppleBooksTypography.headlineMedium)
                                .foregroundColor(AppleBooksColors.text)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                            Text(subscription.productName)
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.text)

                            Text("Renews on \(formattedDate(subscription.expirationDate))")
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.textSecondary)

                            if subscription.isTrial {
                                Text("Free Trial")
                                    .font(AppleBooksTypography.captionBold)
                                    .foregroundColor(SemanticColors.infoPrimary)
                                    .padding(.horizontal, SpacingSystem.sm)
                                    .padding(.vertical, SpacingSystem.xs)
                                    .background(SemanticColors.infoSecondary)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(.horizontal, SpacingSystem.lg)
            }
        }
    }

    private var offeringsSection: some View {
        VStack(spacing: SpacingSystem.lg) {
            Text("Choose Your Plan")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)

            VStack(spacing: SpacingSystem.md) {
                ForEach(offerings) { offering in
                    SubscriptionOfferingCard(
                        offering: offering,
                        isSelected: selectedPackage?.id == offering.packages.first?.id,
                        variantConfig: variantConfig,
                        onSelect: { selectedPackage = $0 }
                    )
                }
            }
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var featuresSection: some View {
        VStack(spacing: SpacingSystem.lg) {
            Text("Premium Features")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)

            VStack(spacing: SpacingSystem.sm) {
                PremiumFeatureRow(
                    icon: "camera.fill",
                    title: "Unlimited AI Scans",
                    description: "Scan as many bookshelves as you want"
                )

                PremiumFeatureRow(
                    icon: "book.fill",
                    title: "Unlimited Library",
                    description: "Add unlimited books to your collection"
                )

                PremiumFeatureRow(
                    icon: "sparkles",
                    title: "Unlimited Recommendations",
                    description: "Get personalized book suggestions powered by AI"
                )

                PremiumFeatureRow(
                    icon: "chart.bar.fill",
                    title: "Advanced Analytics",
                    description: "Detailed reading statistics and insights"
                )

                PremiumFeatureRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Full Export",
                    description: "Export your entire library and reading data"
                )

                PremiumFeatureRow(
                    icon: "person.fill.questionmark",
                    title: "Priority Support",
                    description: "Direct access to customer support"
                )
            }
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var faqSection: some View {
        VStack(spacing: SpacingSystem.lg) {
            Text("Frequently Asked Questions")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)

            VStack(spacing: SpacingSystem.sm) {
                FAQItem(
                    question: "Can I cancel anytime?",
                    answer: "Yes, you can cancel your subscription at any time. You'll continue to have access until the end of your billing period."
                )

                FAQItem(
                    question: "Is there a free trial?",
                    answer: "Yes, we offer a 7-day free trial for new subscribers. No payment required to start."
                )

                FAQItem(
                    question: "What payment methods do you accept?",
                    answer: "We accept all major credit cards, PayPal, and Apple Pay through the App Store."
                )

                FAQItem(
                    question: "Can I change plans?",
                    answer: "Yes, you can upgrade or downgrade your plan at any time. Changes take effect immediately."
                )
            }
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var restorePurchasesSection: some View {
        VStack(spacing: SpacingSystem.md) {
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(AppleBooksTypography.buttonMedium)
                    .foregroundColor(AppleBooksColors.accent)
                    .padding(.vertical, SpacingSystem.sm)
            }
            .disabled(isPurchasing)

            Text("If you've already purchased a subscription, tap here to restore your access.")
                .font(AppleBooksTypography.caption)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, SpacingSystem.lg)
    }

    private var closeButton: some View {
        Button(action: {
            trackDismiss()
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(AppleBooksColors.text)
                .font(.system(size: 16, weight: .medium))
        }
    }

    private func loadVariantConfig() {
        Task {
            guard let userId = AuthService.shared.currentUser?.id else { return }
            do {
                if let variant = try await abTestingService.getVariant(for: "subscription_flow_experiment", userId: userId) {
                    variantConfig = SubscriptionVariantConfig.fromVariant(variant)
                }
            } catch {
                print("Failed to load subscription variant config: \(error)")
            }
        }
    }

    private func loadOfferings() {
        isLoading = true

        #if canImport(RevenueCat)
        // Use RevenueCat offerings
        if let offering = revenueCatManager.offerings["premium"] {
            // Convert RevenueCat packages to our SubscriptionPackage format
            let packages = offering.packages.map { rcPackage in
                SubscriptionPackage(
                    id: rcPackage.identifier,
                    productId: rcPackage.storeProduct.productIdentifier,
                    title: rcPackage.storeProduct.localizedTitle,
                    price: rcPackage.storeProduct.price.doubleValue,
                    currency: rcPackage.storeProduct.currencyCode ?? "USD",
                    period: rcPackage.storeProduct.subscriptionPeriod?.unit.rawValue == "year" ? "year" : "month",
                    isPopular: rcPackage.identifier.contains("annual") // Simple heuristic
                )
            }

            let subscriptionOffering = SubscriptionOffering(
                id: offering.identifier,
                packages: packages
            )

            self.offerings = [subscriptionOffering]
            // Default to the most expensive (likely annual) or first package
            self.selectedPackage = packages.max(by: { $0.price < $1.price }) ?? packages.first
            self.isLoading = false
        } else {
            // Fallback to simulated offerings if RevenueCat not available
            loadSimulatedOfferings()
        }
        #else
        // Fallback for development
        loadSimulatedOfferings()
        #endif
    }

    private func loadSimulatedOfferings() {
        let monthlyPackage = SubscriptionPackage(
            id: "monthly",
            productId: "bookshelf_scanner_monthly",
            title: "Monthly",
            price: variantConfig?.monthlyPrice ?? 2.99,
            currency: "USD",
            period: "month",
            isPopular: false
        )

        let annualPackage = SubscriptionPackage(
            id: "annual",
            productId: "bookshelf_scanner_annual",
            title: "Annual",
            price: variantConfig?.annualPrice ?? 29.99,
            currency: "USD",
            period: "year",
            isPopular: true
        )

        let offering = SubscriptionOffering(
            id: "premium",
            packages: [monthlyPackage, annualPackage]
        )

        self.offerings = [offering]
        self.selectedPackage = annualPackage // Default to annual
        self.isLoading = false
    }

    private func restorePurchases() {
        isPurchasing = true

        revenueCatManager.restorePurchases { result in
            DispatchQueue.main.async {
                self.isPurchasing = false

                switch result {
                case .success:
                    if self.revenueCatManager.isSubscribed {
                        self.presentationMode.wrappedValue.dismiss()
                    } else {
                        self.errorMessage = "No previous purchases found to restore."
                        self.showError = true
                    }

                case .failure(let error):
                    self.errorMessage = "Restore failed: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    private func purchasePackage(_ package: SubscriptionPackage) {
        isPurchasing = true
        trackPurchaseStart(package: package)

        #if canImport(RevenueCat)
        // Find the corresponding RevenueCat package
        guard let offering = revenueCatManager.offerings["premium"],
              let rcPackage = offering.packages.first(where: { $0.identifier == package.id }) else {
            self.isPurchasing = false
            self.errorMessage = "Package not found. Please try again."
            self.showError = true
            return
        }

        revenueCatManager.purchase(package: rcPackage) { result in
            DispatchQueue.main.async {
                self.isPurchasing = false

                switch result {
                case .success(let customerInfo):
                    self.trackPurchaseSuccess(package: package)
                    self.presentationMode.wrappedValue.dismiss()

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.trackPurchaseFailure(package: package)
                }
            }
        }
        #else
        // Fallback for development - simulate purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isPurchasing = false

            if Bool.random() { // Simulate success/failure
                // Success
                self.updateUserTierToPremium()
                self.trackPurchaseSuccess(package: package)
                self.presentationMode.wrappedValue.dismiss()
            } else {
                // Failure
                self.errorMessage = "Purchase failed. Please try again or contact support."
                self.showError = true
                self.trackPurchaseFailure(package: package)
            }
        }
        #endif
    }

    private func updateUserTierToPremium() {
        AuthService.shared.updateUserTier(.premium)
        UsageTracker.shared.refreshOnUserChange()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // Analytics
    private func trackView() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_view_opened", parameters: [
            "variant_id": variantConfig?.variantId ?? "default"
        ])
        #endif
    }

    private func trackDismiss() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_view_dismissed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default"
        ])
        #endif
    }

    private func trackPurchaseStart(package: SubscriptionPackage) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_purchase_started", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "package_id": package.id,
            "price": package.price,
            "currency": package.currency
        ])
        #endif
    }

    private func trackPurchaseSuccess(package: SubscriptionPackage) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_purchase_success", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "package_id": package.id,
            "price": package.price,
            "currency": package.currency
        ])
        #endif
    }

    private func trackPurchaseFailure(package: SubscriptionPackage) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("subscription_purchase_failed", parameters: [
            "variant_id": variantConfig?.variantId ?? "default",
            "package_id": package.id,
            "price": package.price,
            "currency": package.currency
        ])
        #endif
    }
}

// MARK: - Supporting Types

struct SubscriptionOffering: Identifiable {
    let id: String
    let packages: [SubscriptionPackage]
}

struct SubscriptionPackage: Identifiable {
    let id: String
    let productId: String
    let title: String
    let price: Double
    let currency: String
    let period: String
    let isPopular: Bool
}


struct SubscriptionVariantConfig {
    let variantId: String
    let headerTitle: String
    let headerSubtitle: String
    let monthlyPrice: Double
    let annualPrice: Double

    static func fromVariant(_ variant: Variant) -> SubscriptionVariantConfig {
        let config = variant.config

        return SubscriptionVariantConfig(
            variantId: variant.id,
            headerTitle: config["headerTitle"]?.value as? String ?? "Unlock Unlimited Access",
            headerSubtitle: config["headerSubtitle"]?.value as? String ?? "Get unlimited scans and premium features",
            monthlyPrice: config["monthlyPrice"]?.value as? Double ?? 2.99,
            annualPrice: config["annualPrice"]?.value as? Double ?? 29.99
        )
    }
}

// MARK: - UI Components

struct SubscriptionOfferingCard: View {
    let offering: SubscriptionOffering
    let isSelected: Bool
    let variantConfig: SubscriptionVariantConfig?
    let onSelect: (SubscriptionPackage) -> Void

    var body: some View {
        ForEach(offering.packages, id: \.id) { package in
            PackageButton(package: package, isSelected: isSelected, onSelect: onSelect)
        }
    }
}

private struct PackageButton: View {
    let package: SubscriptionPackage
    let isSelected: Bool
    let onSelect: (SubscriptionPackage) -> Void

    var body: some View {
        Button(action: { onSelect(package) }) {
            packageCardContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var packageCardContent: some View {
        AppleBooksCard {
            VStack(spacing: SpacingSystem.md) {
                packageHeader
                if package.isPopular {
                    popularBadge
                }
            }
        }
    }

    private var packageHeader: some View {
        HStack {
            packageDetails
            Spacer()
            selectionIndicator
        }
    }

    private var packageDetails: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.xs) {
            titleRow
            priceText
            if package.period == "year" {
                monthlyEquivalentText
            }
        }
    }

    private var titleRow: some View {
        HStack {
            Text(package.title)
                .font(AppleBooksTypography.headlineMedium)
                .foregroundColor(AppleBooksColors.text)

            if package.isPopular {
                popularLabel
            }
        }
    }

    private var popularLabel: some View {
        Text("Most Popular")
            .font(AppleBooksTypography.captionBold)
            .foregroundColor(.white)
            .padding(.horizontal, SpacingSystem.sm)
            .padding(.vertical, SpacingSystem.xs)
            .background(AdaptiveColors.vibrantPink)
            .cornerRadius(8)
    }

    private var priceText: some View {
        Text("$\(String(format: "%.2f", package.price))/\(package.period)")
            .font(AppleBooksTypography.bodyLarge)
            .foregroundColor(AppleBooksColors.accent)
    }

    private var monthlyEquivalentText: some View {
        Text("$\(String(format: "%.2f", package.price/12))/month")
            .font(AppleBooksTypography.caption)
            .foregroundColor(AppleBooksColors.textSecondary)
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? AppleBooksColors.accent : AppleBooksColors.textTertiary, lineWidth: 2)
                .frame(width: 24, height: 24)

            if isSelected {
                Circle()
                    .fill(AppleBooksColors.accent)
                    .frame(width: 16, height: 16)
            }
        }
    }

    private var popularBadge: some View {
        Text("Save 17% with annual billing")
            .font(AppleBooksTypography.caption)
            .foregroundColor(SemanticColors.successPrimary)
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        AppleBooksCard(padding: AppleBooksSpacing.space16) {
            HStack(spacing: AppleBooksSpacing.space12) {
                Image(systemName: icon)
                    .font(AppleBooksTypography.bodyLarge)
                    .foregroundColor(AppleBooksColors.accent)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text(title)
                        .font(AppleBooksTypography.bodyLarge)
                        .foregroundColor(AppleBooksColors.text)

                    Text(description)
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "checkmark")
                    .foregroundColor(SemanticColors.successPrimary)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        AppleBooksCard {
            VStack(spacing: AppleBooksSpacing.space12) {
                Button(action: { isExpanded.toggle() }) {
                    HStack {
                        Text(question)
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .font(.system(size: 14))
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if isExpanded {
                    Text(answer)
                        .font(AppleBooksTypography.bodyMedium)
                        .foregroundColor(AppleBooksColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct SocialProofBadge: View {
    let count: String
    let label: String

    var body: some View {
        VStack(spacing: SpacingSystem.xs) {
            Text(count)
                .font(AppleBooksTypography.headlineMedium)
                .foregroundColor(AppleBooksColors.accent)
                .bold()

            Text(label)
                .font(AppleBooksTypography.caption)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingSystem.sm)
        .background(AppleBooksColors.accent.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
}