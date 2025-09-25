import SwiftUI

struct HomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @State private var showLogin = false
    @State private var showSignup = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Enhanced gradient background with Apple Books styling
            LandingPageDesignSystem.Colors.heroGradient
                .ignoresSafeArea()
            
            // Animated background elements
            GeometryReader { geometry in
                // Floating elements for depth
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: geometry.size.width * 0.6)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.3)
                    .blur(radius: 30)
                    .offset(y: scrollOffset * 0.3)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: geometry.size.width * 0.4)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.7)
                    .blur(radius: 20)
                    .offset(y: scrollOffset * 0.2)
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    // Enhanced Navigation Bar (Fixed position)
                    HomeNavigationBar(showLogin: $showLogin, showSignup: $showSignup)
                    
                    // Enhanced Hero Section with proper spacing
                    HeroSection(showSignup: $showSignup, showLogin: $showLogin)
                        .padding(.bottom, LandingPageDesignSystem.Spacing.xxxl)

                    // Enhanced Interactive Journey Section with consistent spacing
                    EnhancedUserJourneySection()
                        .padding(.bottom, LandingPageDesignSystem.Spacing.xxxl)

                    // Enhanced Features Section with Apple Books styling
                    FeaturesSection()
                        .padding(.bottom, LandingPageDesignSystem.Spacing.xxxl)

                    // Enhanced Footer with final conversion opportunities
                    HomeFooter()
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
        }
        .preferredColorScheme(.dark) // Ensure dark mode for landing page
        .sheet(isPresented: $showLogin) {
            LoginView(isSignUp: false)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSignup) {
            LoginView(isSignUp: true)
                .preferredColorScheme(.dark)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bookshelf Scanner landing page")
    }
}

// MARK: - Scroll Offset Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppleBooksSpacing.space16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppleBooksColors.accent)
                .frame(width: 40, height: 40)
                .background(AppleBooksColors.accent.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                Text(title)
                    .font(AppleBooksTypography.headlineSmall)
                    .foregroundColor(AppleBooksColors.text)

                Text(description)
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

struct HomeFeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        AppleBooksCard(
            cornerRadius: 12,
            padding: AppleBooksSpacing.space20,
            shadowStyle: .subtle
        ) {
            HStack(spacing: AppleBooksSpacing.space16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(AppleBooksColors.accent)
                    .frame(width: 50, height: 50)
                    .background(AppleBooksColors.accent.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text(title)
                        .font(AppleBooksTypography.headlineMedium)
                        .foregroundColor(AppleBooksColors.text)

                    Text(description)
                        .font(AppleBooksTypography.bodyMedium)
                        .foregroundColor(AppleBooksColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}