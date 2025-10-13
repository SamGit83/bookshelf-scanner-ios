import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @State private var showLogin = false
    @State private var showSignup = false
    @State private var floatingOffset: CGFloat = -20
    @State private var flipAngle: Double = 0
    @State private var currentIndex: Int = 0
    @State private var timer: Timer? = nil
    @State private var flipTimer: Timer? = nil
    @State private var currentOffset: CGFloat = 0
    @State private var nextOffset: CGFloat = 50
    @State private var currentOpacity: Double = 1
    @State private var nextOpacity: Double = 0
    @State private var nextIndex: Int = 1
    @State private var currentPage: Int = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    private var horizontalPadding: CGFloat {
        isIPad ? 64 : 24
    }
    
    private var heroMaxWidth: CGFloat {
        isIPad ? 800 : .infinity
    }
    
    private var featureMaxWidth: CGFloat {
        isIPad ? 700 : .infinity
    }

    private let features = [
        ("camera.fill", "Scan Your Bookshelf", "Point your camera at your bookshelf and capture a photo"),
        ("sparkles", "AI Recognition", "Our AI instantly identifies books using advanced computer vision"),
        ("books.vertical.fill", "Organize & Track", "Automatically organize your library and track reading progress"),
        ("star.fill", "Discover New Books", "Get personalized recommendations powered by smart AI")
    ]


    var body: some View {
        ZStack {
            // Apple Books clean background
            AppleBooksColors.background
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Page 1: Hero Section
                HeroSection(showSignup: $showSignup)
                    .tag(0)

                // Page 2: Reader's Journey Section
                VStack {
                    ReadersJourneySection()
                    Spacer()
                }
                .tag(1)

                // Page 3: How It Works Section
                VStack(spacing: AppleBooksSpacing.space24) {
                    VStack(spacing: AppleBooksSpacing.space24) {
                        Text("How it works")
                            .font(AppleBooksTypography.headlineLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .padding(.bottom, AppleBooksSpacing.space40)

                        VStack(spacing: AppleBooksSpacing.space24) {
                            ForEach(features.indices, id: \.self) { index in
                                let feature = features[index]
                                GeometryReader { geometry in
                                    let minY = geometry.frame(in: .global).minY
                                    let maxY = geometry.frame(in: .global).maxY
                                    let screenHeight = UIScreen.main.bounds.height

                                    // Calculate visibility: item is visible when it's in viewport
                                    // Fade in starts when bottom of item enters screen (maxY < screenHeight)
                                    // Full opacity when item is well within viewport
                                    // Stay visible even when scrolling up past top
                                    let fadeInThreshold: CGFloat = screenHeight * 0.95
                                    let fadeInComplete: CGFloat = screenHeight * 0.90

                                    let visibility: Double = {
                                        if maxY < fadeInComplete {
                                            // Item is well within viewport - fully visible
                                            return 1.0
                                        } else if maxY < fadeInThreshold {
                                            // Item is entering viewport - fade in
                                            let progress = (fadeInThreshold - maxY) / (fadeInThreshold - fadeInComplete)
                                            return Double(min(max(progress, 0), 1))
                                        } else {
                                            // Item is below viewport - hidden
                                            return 0.0
                                        }
                                    }()

                                    FeatureRow(icon: feature.0, title: feature.1, description: feature.2)
                                        .opacity(visibility)
                                        .offset(y: (1 - visibility) * 30)
                                        .onChange(of: visibility) { _ in }
                                }
                                .frame(height: 80)
                            }
                        }
                    }
                    .frame(maxWidth: featureMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)

                    Spacer()

                    Button(action: {
                        showSignup = true
                    }) {
                        Text("Sign Up")
                            .font(AppleBooksTypography.buttonLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: isIPad ? 400 : .infinity)
                            .padding(.vertical, AppleBooksSpacing.space16)
                            .background(AppleBooksColors.accent)
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: featureMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, AppleBooksSpacing.space80)
                }
                .padding(.top, AppleBooksSpacing.space48)
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .accentColor(Color(red: 1.0, green: 0.42, blue: 0.42))
        }
        .sheet(isPresented: $showLogin) {
            LoginView(isSignUp: false)
        }
        .sheet(isPresented: $showSignup) {
            LoginView(isSignUp: true)
        }
        .onChange(of: authService.showLoginAfterDeletion) { newValue in
            if newValue {
                showLogin = true
                authService.showLoginAfterDeletion = false
            }
        }
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
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)
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