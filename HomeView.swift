import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @State private var showLogin = false
    @State private var showSignup = false
    @State private var floatingOffset: CGFloat = -20
    @State private var flipAngle: Double = 0
    @State private var flipTimer: Timer? = nil
    @State private var currentPage: Int = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var iconOpacities: [CGFloat] = Array(repeating: 0.0, count: 4)
    @State private var textOffsets: [CGFloat] = Array(repeating: 30.0, count: 4)
    @State private var isAnimatingSequence = false
    @State private var animationCurrentIndex = 0
    
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


    private func startSequenceCycle() {
        iconOpacities = Array(repeating: 0.0, count: 4)
        textOffsets = Array(repeating: 30.0, count: 4)
        animationCurrentIndex = 0
    
        func animateNext() {
            if animationCurrentIndex < 4 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    iconOpacities[animationCurrentIndex] = 1.0
                }
    
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        textOffsets[animationCurrentIndex] = 0
                    }
    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            iconOpacities[animationCurrentIndex] = 0.0
                        }
    
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            animationCurrentIndex += 1
                            animateNext()
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        isAnimatingSequence = true
                        iconOpacities = Array(repeating: 0.0, count: 4)
                        textOffsets = Array(repeating: 30.0, count: 4)
                    }
    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAnimatingSequence = false
                        startSequenceCycle()
                    }
                }
            }
        }
    
        animateNext()
    }
    
    var body: some View {
        ZStack {
            // Apple Books clean background
            AppleBooksColors.background
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Page 1: Hero Section
                VStack(spacing: AppleBooksSpacing.space32) {
                    Spacer(minLength: AppleBooksSpacing.space80)

                    VStack(spacing: AppleBooksSpacing.space32) {
                        // App Icon
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(AppleBooksColors.accent)
                            .padding(AppleBooksSpacing.space24)
                            .background(
                                Circle()
                                    .fill(AppleBooksColors.accent.opacity(0.1))
                            )
                            .offset(y: floatingOffset)
                            .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0))

                        // Title
                        Text("Book Shelfie")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.center)

                        // Subtitle
                        Text("Transform your physical bookshelf into a smart digital library with AI-powered book recognition.")
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppleBooksSpacing.space24)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: heroMaxWidth)
                    .frame(maxWidth: .infinity)
                    
                    // Animated Hero Words with Icons
                    VStack(spacing: 16) {
                        let words = ["Scan", "Catalog", "Organize", "Discover"]
                        let icons = ["viewfinder", "books.vertical", "square.grid.2x2", "sparkles"]
                        let colors: [Color] = [Color(hex: "FF6B35"), Color(hex: "FF1493"), Color(hex: "00BFFF"), Color(hex: "32CD32")]
                        HStack(spacing: 24) {
                            ForEach(0..<4, id: \.self) { index in
                                VStack(spacing: 8) {
                                    Image(systemName: icons[index])
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [colors[index], colors[index].opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .opacity(iconOpacities[index])
                                        .animation(.easeInOut(duration: 0.5), value: iconOpacities[index])
                    
                                    Text(words[index])
                                        .font(.largeTitle.weight(.bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [colors[index], colors[index].opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .offset(y: textOffsets[index])
                                        .animation(.easeInOut(duration: 0.5), value: textOffsets[index])
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                        .rotationEffect(.degrees(Double(isAnimatingSequence ? 360 : 0)))
                        .animation(.easeInOut(duration: 0.8), value: isAnimatingSequence)
                    }
                    .frame(height: 80)
                    .frame(maxWidth: heroMaxWidth)
                    .frame(maxWidth: .infinity)
                    
                    // CTA Buttons
                    VStack(spacing: AppleBooksSpacing.space16) {
                        Button(action: {
                            currentPage = 1
                        }) {
                            Text("Get Started")
                                .font(AppleBooksTypography.buttonLarge)
                                .foregroundColor(.white)
                                .frame(maxWidth: isIPad ? 400 : .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(AppleBooksColors.accent)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            showLogin = true
                        }) {
                            Text("Sign In")
                                .font(AppleBooksTypography.buttonLarge)
                                .foregroundColor(AppleBooksColors.accent)
                                .frame(maxWidth: isIPad ? 400 : .infinity)
                                .padding(.vertical, AppleBooksSpacing.space16)
                                .background(AppleBooksColors.card)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppleBooksColors.accent, lineWidth: 1)
                                )
                        }
                    }
                    .frame(maxWidth: heroMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)

                    Spacer(minLength: AppleBooksSpacing.space40)
                }
                .tag(0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        floatingOffset = 20
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        flipTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                            withAnimation(.easeInOut(duration: 1.0)) {
                                flipAngle = flipAngle == 0 ? 180 : 0
                            }
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startSequenceCycle()
                    }
                }
                .onDisappear {
                    flipTimer?.invalidate()
                }

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