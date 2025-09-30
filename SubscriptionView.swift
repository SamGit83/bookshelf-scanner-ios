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
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.blue)
                        Text("Loading subscription options...")
                            .font(.body)
                            .foregroundColor(Color.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 48) {
                            headerSection
                            currentPlanSection
                            offeringsSection
                            featuresSection
                            faqSection
                            restorePurchasesSection
                        }
                        .padding(.vertical, 32)
                        .animation(.easeInOut(duration: 0.5), value: isLoading)
                    }
                }
            }
            .navigationTitle("Premium Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            .onAppear {
                print("DEBUG SubscriptionView: View presented")
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
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)
                    .glassBackground()

                Image(systemName: "star.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(Color.gray)
                    .accessibilityLabel("Premium Star Icon")
            }

            Text(variantConfig?.headerTitle ?? "Unlock Unlimited Access")
                .font(.largeTitle)
                .foregroundColor(Color.primary)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Header: Unlock Unlimited Access")

            Text(variantConfig?.headerSubtitle ?? "Get unlimited scans, recommendations, and premium features")
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            // Social proof badges
            HStack(spacing: 16) {
                SocialProofBadge(count: "10,000+", label: "Happy Readers")
                SocialProofBadge(count: "4.9★", label: "App Store Rating")
                SocialProofBadge(count: "95%", label: "Satisfaction")
            }
            .padding(.top, 24)
        }
        .padding(.horizontal, 32)
        .glassBackground()
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: variantConfig)
        .accessibilityElement(children: .combine)
    }

    private var currentPlanSection: some View {
        Group {
            if revenueCatManager.isSubscribed, let subscription = revenueCatManager.getSubscriptionInfo() {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.green)
                            .font(.system(size: 24))
                        Text("Current Plan")
                            .font(.title3)
                            .foregroundColor(Color.primary)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(subscription.productName)
                            .font(.body)
                            .foregroundColor(Color.primary)

                        Text("Renews on \(formattedDate(subscription.expirationDate))")
                            .font(.caption)
                            .foregroundColor(Color.secondary)

                        if subscription.isTrial {
                            Text("Free Trial")
                                .font(.caption)
                                .foregroundColor(Color.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding(24)
                .glassBackground()
                .cornerRadius(16)
                .padding(.horizontal, 32)
                .accessibilityLabel("Current Plan: \(subscription.productName), Renews on \(formattedDate(subscription.expirationDate))")
            }
        }
    }

    private var offeringsSection: some View {
        VStack(spacing: 32) {
            Text("Choose Your Plan")
                .font(.title2)
                .foregroundColor(Color.primary)
                .accessibilityLabel("Choose Your Plan Section")

            // Toggle for monthly/yearly
            Picker("Billing Period", selection: $selectedPeriod) {
                Text("Monthly").tag("month")
                Text("Yearly").tag("year")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .glassBackground()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )

            // Pricing cards with savings highlight
            if let offering = offerings.first {
                let monthlyPrice = offering.packages.first(where: { $0.period == "month" })?.price ?? 2.99
                let annualPrice = offering.packages.first(where: { $0.period == "year" })?.price ?? 29.99
                let savings = ((2.99 * 12 - annualPrice) / (2.99 * 12)) * 100

                VStack(spacing: 24) {
                    // Monthly Card
                    VStack(spacing: 16) {
                        Text(selectedPeriod == "month" ? "Selected" : "Monthly")
                            .font(.headline)
                            .foregroundColor(selectedPeriod == "month" ? Color.orange : Color.secondary)

                        Text("$\(String(format: "%.2f", monthlyPrice))")
                            .font(.largeTitle)
                            .foregroundColor(Color.primary)
                            .bold()

                        Text("/month")
                            .font(.body)
                            .foregroundColor(Color.secondary)

                        Button("Subscribe Monthly") {
                            if let package = offering.packages.first(where: { $0.period == "month" }) {
                                purchasePackage(package)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.orange)
                        .disabled(selectedPeriod != "month" || isPurchasing)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .glassBackground()
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedPeriod == "month" ? Color.orange : Color.clear, lineWidth: 2)
                    )

                    // Annual Card with savings
                    VStack(spacing: 16) {
                        Text(selectedPeriod == "year" ? "Selected" : "Yearly (Most Popular)")
                            .font(.headline)
                            .foregroundColor(selectedPeriod == "year" ? Color.orange : Color.secondary)

                        Text("$\(String(format: "%.2f", annualPrice))")
                            .font(.largeTitle)
                            .foregroundColor(Color.primary)
                            .bold()

                        Text("/year")
                            .font(.body)
                            .foregroundColor(Color.secondary)

                        Text("Save \(String(format: "%.0f", savings))%")
                            .font(.caption)
                            .foregroundColor(Color.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Button("Subscribe Yearly") {
                            if let package = offering.packages.first(where: { $0.period == "year" }) {
                                purchasePackage(package)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.orange)
                        .disabled(selectedPeriod != "year" || isPurchasing)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .glassBackground()
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedPeriod == "year" ? Color.orange : Color.clear, lineWidth: 2)
                    )
                    .overlay(
                        Text("Most Popular")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4)),
                        alignment: .topTrailing
                    )
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPeriod)
        .accessibilityElement(children: .combine)
    }

    private var featuresSection: some View {
        VStack(spacing: 24) {
            Text("Premium Features")
                .font(.title2)
                .foregroundColor(Color.primary)
                .accessibilityLabel("Premium Features Section")

            VStack(spacing: 16) {
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
        .padding(.horizontal, 16)
        .glassBackground()
        .accessibilityElement(children: .combine)
    }

    private var faqSection: some View {
        VStack(spacing: 24) {
            Text("Frequently Asked Questions")
                .font(.title2)
                .foregroundColor(Color.primary)
                .accessibilityLabel("FAQ Section")

            VStack(spacing: 16) {
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
        .padding(.horizontal, 16)
        .glassBackground()
        .accessibilityElement(children: .combine)
    }

    private var restorePurchasesSection: some View {
        VStack(spacing: 24) {
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            .disabled(isPurchasing)
            .accessibilityLabel("Restore Purchases Button")

            Text("If you've already purchased a subscription, tap here to restore your access.")
                .font(.caption)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.horizontal, 32)
        .glassBackground()
    }

    private var closeButton: some View {
        Button(role: .cancel, action: {
            withAnimation(.easeOut(duration: 0.15)) {
                trackDismiss()
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.secondary)
                .background(Color.gray.opacity(0.4))
                .clipShape(Circle())
                .padding(8)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
        }
        .accessibilityLabel("Close Button")
    }

    private func loadVariantConfig() {
        Task {
            print("DEBUG SubscriptionView: Loading variant config for user \(AuthService.shared.currentUser?.id ?? "nil")")
            guard let userId = AuthService.shared.currentUser?.id else {
                print("DEBUG SubscriptionView: No user ID, skipping variant load")
                return
            }
            do {
                if let variant = try await abTestingService.getVariant(for: "subscription_flow_experiment", userId: userId) {
                    variantConfig = SubscriptionVariantConfig.fromVariant(variant)
                    print("DEBUG SubscriptionView: Loaded variant \(variant.id)")
                } else {
                    print("DEBUG SubscriptionView: No variant assigned")
                }
            } catch {
                print("DEBUG SubscriptionView: Failed to load subscription variant config: \(error)")
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
            id: "premium_monthly",
            productId: "bookshelf_scanner_monthly",
            title: "Monthly",
            price: variantConfig?.monthlyPrice ?? 2.99,
            currency: "USD",
            period: "month",
            isPopular: false
        )

        let annualPackage = SubscriptionPackage(
            id: "premium_yearly",
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
        print("DEBUG SubscriptionView: Starting purchase for package \(package.id) at $\(package.price)")
        isPurchasing = true
        trackPurchaseStart(package: package)
    
        #if canImport(RevenueCat)
        // Find the corresponding RevenueCat package
        guard let offering = revenueCatManager.offerings["premium"],
              let rcPackage = offering.packages.first(where: { $0.identifier == package.id }) else {
            print("DEBUG SubscriptionView: Package not found in RevenueCat offerings")
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
                    print("DEBUG SubscriptionView: Purchase successful")
                    self.trackPurchaseSuccess(package: package)
                    self.presentationMode.wrappedValue.dismiss()
    
                case .failure(let error):
                    print("DEBUG SubscriptionView: Purchase failed: \(error.localizedDescription)")
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
            let success = Bool.random()
            print("DEBUG SubscriptionView: Simulated purchase \(success ? "success" : "failure") for \(package.id)")
    
            if success { // Simulate success/failure
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
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.gray)
                    .accessibilityLabel("\(title) Icon")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body)
                    .foregroundColor(Color.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.green)
                .font(.system(size: 20, weight: .semibold))
                .opacity(0.8)
                .accessibilityLabel("Included in Premium")
        }
        .padding(24)
        .glassBackground()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            Button(action: { withAnimation(.easeOut(duration: 0.15)) { isExpanded.toggle() } }) {
                HStack {
                    Text(question)
                        .font(.body)
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 16, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(24)
        .glassBackground()
        .cornerRadius(12)
        .animation(.easeOut(duration: 0.15), value: isExpanded)
        .accessibilityLabel("\(question). \(isExpanded ? answer : "")")
    }
}

struct SocialProofBadge: View {
    let count: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(count)
                .font(.headline)
                .foregroundColor(Color.blue)
                .bold()

            Text(label)
                .font(.caption)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .accessibilityLabel("\(count) \(label)")
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environment(\.colorScheme, .light)
            .previewLayout(.sizeThatFits)
    }
}