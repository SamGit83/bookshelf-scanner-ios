import SwiftUI
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(RevenueCat)
import RevenueCat
#endif
import Foundation

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
    @State private var selectedPeriod: String = "year" // For toggle

    // Memory logging
    private func logMemoryUsage(_ context: String) {
        #if os(iOS)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            let memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0
            print("DEBUG SubscriptionView Memory: \(context) - \(String(format: "%.2f", memoryUsage)) MB")
        } else {
            print("DEBUG SubscriptionView Memory: \(context) - Failed to get memory info")
        }
        #else
        print("DEBUG SubscriptionView Memory: \(context) - Memory logging not available on this platform")
        #endif
    }

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundGradients.heroGradient
                    .ignoresSafeArea()
                AnimatedBackground()
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: SpacingSystem.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(PrimaryColors.vibrantPurple)
                        Text("Loading subscription options...")
                            .font(TypographySystem.bodyLarge)
                            .foregroundColor(AdaptiveColors.secondaryText)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: SpacingSystem.xxl) {
                            headerSection
                            currentPlanSection
                            offeringsSection
                            featuresSection
                            faqSection
                            restorePurchasesSection
                        }
                        .padding(.vertical, SpacingSystem.xl)
                        .animation(AnimationTiming.pageTransition, value: isLoading)
                    }
                }
            }
            .navigationBarTitle("Premium Subscription", displayMode: .large)
            .navigationBarItems(trailing: closeButton)
            .onAppear {
                logMemoryUsage("Before SubscriptionView onAppear")
                loadVariantConfig()
                loadOfferings()
                trackView()
                logMemoryUsage("After SubscriptionView onAppear")
            }
            .onDisappear {
                logMemoryUsage("SubscriptionView onDisappear")
            }
            .onChange(of: selectedPeriod) { _ in
                updateSelectedPackage()
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func updateSelectedPackage() {
        if let offering = offerings.first,
           let package = offering.packages.first(where: { $0.period == selectedPeriod }) {
            selectedPackage = package
        }
    }

    private var headerSection: some View {
        VStack(spacing: SpacingSystem.lg) {
            ZStack {
                Circle()
                    .fill(PrimaryColors.vibrantPurple.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(PrimaryColors.vibrantPurple)
                    .shadow(color: PrimaryColors.vibrantPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            Text(variantConfig?.headerTitle ?? "Unlock Unlimited Access")
                .font(TypographySystem.displayLarge)
                .foregroundColor(AdaptiveColors.primaryText)
                .multilineTextAlignment(.center)

            Text(variantConfig?.headerSubtitle ?? "Get unlimited scans, recommendations, and premium features")
                .font(TypographySystem.bodyLarge)
                .foregroundColor(AdaptiveColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingSystem.md)

            // Social proof badges
            HStack(spacing: SpacingSystem.md) {
                SocialProofBadge(count: "10,000+", label: "Happy Readers")
                SocialProofBadge(count: "4.9★", label: "App Store Rating")
                SocialProofBadge(count: "95%", label: "Satisfaction")
            }
            .padding(.top, SpacingSystem.lg)
        }
        .padding(.horizontal, SpacingSystem.xl)
        .glassEffect()
        .animation(AnimationTiming.feedback, value: variantConfig)
    }

    private var currentPlanSection: some View {
        Group {
            if revenueCatManager.isSubscribed, let subscription = revenueCatManager.getSubscriptionInfo() {
                GlassCard {
                    VStack(spacing: SpacingSystem.md) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(SemanticColors.successPrimary)
                                .font(.system(size: 24))
                            Text("Current Plan")
                                .font(TypographySystem.headlineMedium)
                                .foregroundColor(AdaptiveColors.primaryText)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                            Text(subscription.productName)
                                .font(TypographySystem.bodyLarge)
                                .foregroundColor(AdaptiveColors.primaryText)

                            Text("Renews on \(formattedDate(subscription.expirationDate))")
                                .font(TypographySystem.captionMedium)
                                .foregroundColor(AdaptiveColors.secondaryText)

                            if subscription.isTrial {
                                Text("Free Trial")
                                    .font(TypographySystem.captionLarge)
                                    .foregroundColor(SemanticColors.infoPrimary)
                                    .padding(.horizontal, SpacingSystem.sm)
                                    .padding(.vertical, SpacingSystem.xs)
                                    .background(SemanticColors.infoSecondary)
                                    .cornerRadius(SpacingSystem.xs)
                            }
                        }
                    }
                    .padding(SpacingSystem.lg)
                }
                .padding(.horizontal, SpacingSystem.xl)
            }
        }
    }

    private var offeringsSection: some View {
        VStack(spacing: SpacingSystem.xl) {
            Text("Choose Your Plan")
                .font(TypographySystem.headlineLarge)
                .foregroundColor(AdaptiveColors.primaryText)

            // Toggle for monthly/yearly
            Picker("Billing Period", selection: $selectedPeriod) {
                Text("Monthly").tag("month")
                Text("Yearly").tag("year")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, SpacingSystem.lg)
            .background(AdaptiveColors.glassBackground)
            .cornerRadius(SpacingSystem.md)
            .overlay(
                RoundedRectangle(cornerRadius: SpacingSystem.md)
                    .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
            )

            // Pricing cards with savings highlight
            if let offering = offerings.first {
                let monthlyPrice = offering.packages.first(where: { $0.period == "month" })?.price ?? 2.99
                let annualPrice = offering.packages.first(where: { $0.period == "year" })?.price ?? 29.99
                let savings = ((2.99 * 12 - annualPrice) / (2.99 * 12)) * 100

                VStack(spacing: SpacingSystem.lg) {
                    // Monthly Card
                    GlassCard {
                        VStack(spacing: SpacingSystem.md) {
                            Text(selectedPeriod == "month" ? "Selected" : "Monthly")
                                .font(TypographySystem.headlineSmall)
                                .foregroundColor(selectedPeriod == "month" ? PrimaryColors.vibrantPurple : AdaptiveColors.secondaryText)

                            Text("$\(String(format: "%.2f", monthlyPrice))")
                                .font(TypographySystem.displayMedium)
                                .foregroundColor(PrimaryColors.vibrantPurple)
                                .bold()

                            Text("/month")
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(AdaptiveColors.secondaryText)

                            Button("Subscribe Monthly") {
                                if let package = offering.packages.first(where: { $0.period == "month" }) {
                                    purchasePackage(package)
                                }
                            }
                            .primaryButtonStyle()
                            .disabled(selectedPeriod != "month" || isPurchasing)
                        }
                        .padding(SpacingSystem.lg)
                    }

                    // Annual Card with savings
                    GlassCard {
                        VStack(spacing: SpacingSystem.md) {
                            Text(selectedPeriod == "year" ? "Selected" : "Yearly (Most Popular)")
                                .font(TypographySystem.headlineSmall)
                                .foregroundColor(selectedPeriod == "year" ? PrimaryColors.vibrantPurple : AdaptiveColors.secondaryText)

                            Text("$\(String(format: "%.2f", annualPrice))")
                                .font(TypographySystem.displayMedium)
                                .foregroundColor(PrimaryColors.vibrantPurple)
                                .bold()

                            Text("/year")
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(AdaptiveColors.secondaryText)

                            Text("Save \(String(format: "%.0f", savings))%")
                                .font(TypographySystem.captionLarge)
                                .foregroundColor(SemanticColors.successPrimary)
                                .padding(.horizontal, SpacingSystem.sm)
                                .padding(.vertical, SpacingSystem.xs)
                                .background(SemanticColors.successSecondary)
                                .cornerRadius(SpacingSystem.xs)

                            Button("Subscribe Yearly") {
                                if let package = offering.packages.first(where: { $0.period == "year" }) {
                                    purchasePackage(package)
                                }
                            }
                            .primaryButtonStyle()
                            .disabled(selectedPeriod != "year" || isPurchasing)
                        }
                        .padding(SpacingSystem.lg)
                    }
                    .overlay(
                        Text("Most Popular")
                            .font(TypographySystem.captionLarge)
                            .foregroundColor(.white)
                            .padding(.horizontal, SpacingSystem.sm)
                            .padding(.vertical, SpacingSystem.xs)
                            .background(PrimaryColors.vibrantPurple)
                            .cornerRadius(SpacingSystem.sm),
                        alignment: .topTrailing
                    )
                    .padding(.top, SpacingSystem.sm)
                }
                .padding(.horizontal, SpacingSystem.xl)
            }
        }
        .animation(AnimationTiming.transition, value: selectedPeriod)
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
        VStack(spacing: SpacingSystem.lg) {
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(TypographySystem.buttonMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(ButtonStyles.ghostButton())
            .disabled(isPurchasing)

            Text("If you've already purchased a subscription, tap here to restore your access.")
                .font(TypographySystem.captionSmall)
                .foregroundColor(AdaptiveColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingSystem.lg)
        }
        .padding(.horizontal, SpacingSystem.xl)
    }

    private var closeButton: some View {
        Button(action: {
            withAnimation(AnimationTiming.micro) {
                trackDismiss()
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AdaptiveColors.secondaryText)
                .background(AdaptiveColors.glassBackground)
                .clipShape(Circle())
                .padding(SpacingSystem.sm)
                .overlay(
                    Circle()
                        .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
                )
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


struct SubscriptionVariantConfig: Equatable {
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


struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        GlassCard {
            HStack(spacing: SpacingSystem.md) {
                ZStack {
                    Circle()
                        .fill(PrimaryColors.vibrantPurple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(PrimaryColors.vibrantPurple)
                }

                VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                    Text(title)
                        .font(TypographySystem.bodyLarge)
                        .foregroundColor(AdaptiveColors.primaryText)

                    Text(description)
                        .font(TypographySystem.captionMedium)
                        .foregroundColor(AdaptiveColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(SemanticColors.successPrimary)
                    .font(.system(size: 20, weight: .semibold))
                    .opacity(0.8)
            }
            .padding(SpacingSystem.lg)
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        GlassCard {
            VStack(spacing: SpacingSystem.md) {
                Button(action: { withAnimation(AnimationTiming.micro) { isExpanded.toggle() } }) {
                    HStack {
                        Text(question)
                            .font(TypographySystem.bodyLarge)
                            .foregroundColor(AdaptiveColors.primaryText)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(AdaptiveColors.secondaryText)
                            .font(.system(size: 16, weight: .medium))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding(.vertical, SpacingSystem.sm)
                }
                .buttonStyle(PlainButtonStyle())

                if isExpanded {
                    Text(answer)
                        .font(TypographySystem.bodyMedium)
                        .foregroundColor(AdaptiveColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, SpacingSystem.sm)
                        .transition(.opacity.combined(with: .slide))
                }
            }
            .padding(SpacingSystem.lg)
        }
        .animation(AnimationTiming.micro, value: isExpanded)
    }
}

struct SocialProofBadge: View {
    let count: String
    let label: String

    var body: some View {
        VStack(spacing: SpacingSystem.xs) {
            Text(count)
                .font(TypographySystem.headlineMedium)
                .foregroundColor(PrimaryColors.energeticPink)
                .bold()

            Text(label)
                .font(TypographySystem.captionMedium)
                .foregroundColor(AdaptiveColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingSystem.sm)
        .background(PrimaryColors.energeticPink.opacity(0.1))
        .cornerRadius(SpacingSystem.md)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingSystem.md)
                .stroke(PrimaryColors.energeticPink.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environment(\.colorScheme, .light)
            .previewLayout(.sizeThatFits)
    }
}