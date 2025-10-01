import SwiftUI

struct HomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @State private var showLogin = false
    @State private var showSignup = false
    @State private var floatingOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    @State private var timer: Timer? = nil
    @State private var currentOffset: CGFloat = 0
    @State private var nextOffset: CGFloat = 50
    @State private var currentOpacity: Double = 1
    @State private var nextOpacity: Double = 0
    @State private var nextIndex: Int = 1
    var body: some View {
        ZStack {
            // Apple Books clean background
            AppleBooksColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppleBooksSpacing.space64) {
                    // Hero Section
                    VStack(spacing: AppleBooksSpacing.space32) {
                        Spacer(minLength: AppleBooksSpacing.space80)

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

                        // Title
                        Text("Bookshelf Scanner")
                            .font(AppleBooksTypography.displayLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.center)

                        // Subtitle
                        Text("Transform your physical bookshelf into a smart digital library with AI-powered book recognition.")
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, AppleBooksSpacing.space24)
                        
                        // Animated Hero Words with Icons
                        ZStack {
                            let words = ["Scan", "Catalog", "Organize", "Discover"]
                            let icons = ["viewfinder", "books.vertical", "square.grid.2x2", "sparkles"]
                            
                                // Current word with icon
                                HStack(spacing: 12) {
                                    Image(systemName: icons[currentIndex])
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [AppleBooksColors.accent, AppleBooksColors.accent.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: AppleBooksColors.accent.opacity(0.3), radius: 10, x: 0, y: 0)
                                    
                                    Text(words[currentIndex])
                                        .font(.largeTitle.weight(.bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [AppleBooksColors.accent, AppleBooksColors.accent.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: AppleBooksColors.accent.opacity(0.3), radius: 10, x: 0, y: 0)
                                }
                                .offset(y: currentOffset)
                                .opacity(currentOpacity)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, AppleBooksSpacing.space24)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppleBooksColors.accent.opacity(0.05))
                                        .blur(radius: 8)
                                )
                                
                                // Next word with icon
                                HStack(spacing: 12) {
                                    Image(systemName: icons[nextIndex])
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [AppleBooksColors.accent, AppleBooksColors.accent.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: AppleBooksColors.accent.opacity(0.3), radius: 10, x: 0, y: 0)
                                    
                                    Text(words[nextIndex])
                                        .font(.largeTitle.weight(.bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [AppleBooksColors.accent, AppleBooksColors.accent.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: AppleBooksColors.accent.opacity(0.3), radius: 10, x: 0, y: 0)
                                }
                                .offset(y: nextOffset)
                                .opacity(nextOpacity)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, AppleBooksSpacing.space24)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppleBooksColors.accent.opacity(0.05))
                                        .blur(radius: 8)
                                )
                            }
                            .frame(height: 80)
                        
                        // CTA Buttons
                        VStack(spacing: AppleBooksSpacing.space16) {
                            Button(action: {
                                showSignup = true
                            }) {
                                Text("Get Started")
                                    .font(AppleBooksTypography.buttonLarge)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
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
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppleBooksSpacing.space16)
                                    .background(AppleBooksColors.card)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppleBooksColors.accent, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)

                        Spacer(minLength: AppleBooksSpacing.space40)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            floatingOffset = -10
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    currentOffset = -50
                                    currentOpacity = 0
                                    nextOffset = 0
                                    nextOpacity = 1
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    currentIndex = nextIndex
                                    nextIndex = (nextIndex + 1) % 4
                                    currentOffset = 0
                                    nextOffset = 50
                                    currentOpacity = 1
                                    nextOpacity = 0
                            }
                            }
                        }
                    }
                    .onDisappear {
                        timer?.invalidate()
                    }

                    // Reader's Journey Section
                    ReadersJourneySection()

                    // How It Works Section
                    VStack(spacing: AppleBooksSpacing.space24) {
                        Text("How It Works")
                            .font(AppleBooksTypography.headlineLarge)
                            .foregroundColor(AppleBooksColors.text)

                        VStack(spacing: AppleBooksSpacing.space20) {
                            FeatureRow(
                                icon: "camera.fill",
                                title: "Scan Your Bookshelf",
                                description: "Point your camera at your bookshelf and capture a photo"
                            )

                            FeatureRow(
                                icon: "sparkles",
                                title: "AI Recognition",
                                description: "Our AI instantly identifies books using advanced computer vision"
                            )

                            FeatureRow(
                                icon: "books.vertical.fill",
                                title: "Organize & Track",
                                description: "Automatically organize your library and track reading progress"
                            )

                            FeatureRow(
                                icon: "star.fill",
                                title: "Discover New Books",
                                description: "Get personalized recommendations powered by Grok AI"
                            )
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)
                    }

                    Spacer(minLength: AppleBooksSpacing.space80)
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView(isSignUp: false)
        }
        .sheet(isPresented: $showSignup) {
            LoginView(isSignUp: true)
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