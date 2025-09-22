import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var currentPage = 0
    @State private var showMainApp = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Bookshelf Scanner",
            description: "Transform your physical book collection into a beautiful digital library with AI-powered recognition.",
            imageName: "books.vertical.fill",
            color: PrimaryColors.electricBlue,
            gradient: BackgroundGradients.heroGradient
        ),
        OnboardingPage(
            title: "Scan Your Books",
            description: "Point your camera at your bookshelf and watch as our AI identifies your books automatically.",
            imageName: "camera.fill",
            color: PrimaryColors.freshGreen,
            gradient: BackgroundGradients.cameraGradient
        ),
        OnboardingPage(
            title: "Build Your Library",
            description: "Organize your books into collections, track your reading progress, and discover new favorites.",
            imageName: "building.columns.fill",
            color: PrimaryColors.vibrantPurple,
            gradient: BackgroundGradients.libraryGradient
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Set reading goals, log your sessions, and watch your reading habits come to life with detailed analytics.",
            imageName: "chart.bar.fill",
            color: PrimaryColors.dynamicOrange,
            gradient: BackgroundGradients.profileGradient
        ),
        OnboardingPage(
            title: "Smart Recommendations",
            description: "Get personalized book suggestions based on your reading history and preferences.",
            imageName: "sparkles",
            color: PrimaryColors.energeticPink,
            gradient: BackgroundGradients.heroGradient
        ),
        OnboardingPage(
            title: "Ready to Begin!",
            description: "Let's start building your digital bookshelf. You can always access this tutorial from settings.",
            imageName: "checkmark.circle.fill",
            color: SecondaryColors.turquoise,
            gradient: BackgroundGradients.libraryGradient
        )
    ]

    var body: some View {
        ZStack {
            // Enhanced vibrant background gradient
            pages[currentPage].gradient
                .ignoresSafeArea()
                .animation(AnimationTiming.pageTransition, value: currentPage)

            // Animated floating elements
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .blur(radius: 30)
                    .offset(x: currentPage % 2 == 0 ? 20 : -20)
                    .animation(.easeInOut(duration: 3).repeatForever(), value: currentPage)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.7)
                    .blur(radius: 25)
                    .offset(y: currentPage % 2 == 0 ? -15 : 15)
                    .animation(.easeInOut(duration: 4).repeatForever(), value: currentPage)
            }

            VStack(spacing: 0) {
                Spacer()

                // Enhanced Page Content
                VStack(spacing: SpacingSystem.xl) {
                    // Enhanced Page Indicator
                    HStack(spacing: SpacingSystem.sm) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.0 : 0.8)
                                .animation(AnimationTiming.transition, value: currentPage)
                        }
                    }
                    .padding(.top, SpacingSystem.lg)

                    // Enhanced Icon with glass effect
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 160, height: 160)
                            )

                        Image(systemName: pages[currentPage].imageName)
                            .font(.system(size: 72, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .scaleEffect(1.0)
                            .animation(AnimationTiming.transition.delay(0.2), value: currentPage)
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)

                    // Enhanced Text Content
                    VStack(spacing: SpacingSystem.lg) {
                        Text(pages[currentPage].title)
                            .font(TypographySystem.displayMedium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            .animation(AnimationTiming.transition.delay(0.1), value: currentPage)

                        Text(pages[currentPage].description)
                            .font(TypographySystem.bodyLarge)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, SpacingSystem.xl)
                            .animation(AnimationTiming.transition.delay(0.3), value: currentPage)
                    }
                }
                .padding(.horizontal, SpacingSystem.lg)

                Spacer()

                // Enhanced Navigation Buttons
                HStack(spacing: SpacingSystem.md) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(AnimationTiming.transition) {
                                currentPage -= 1
                            }
                        }) {
                            HStack(spacing: SpacingSystem.sm) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Previous")
                                    .font(TypographySystem.buttonMedium)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .ghostButtonStyle()
                        .foregroundColor(.white)
                    } else {
                        Spacer()
                    }

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(AnimationTiming.transition) {
                                currentPage += 1
                            }
                        }) {
                            HStack(spacing: SpacingSystem.sm) {
                                Text("Next")
                                    .font(TypographySystem.buttonLarge)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .modifier(ButtonStyleModifier(
                            background: LinearGradient(colors: [Color.white], startPoint: .leading, endPoint: .trailing),
                            foregroundColor: pages[currentPage].color,
                            cornerRadius: 16,
                            padding: EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24),
                            font: TypographySystem.buttonLarge,
                            shadow: (color: Color.white.opacity(0.3), radius: 12, x: 0, y: 6)
                        ))
                    } else {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            HStack(spacing: SpacingSystem.sm) {
                                Text("Get Started")
                                    .font(TypographySystem.buttonLarge)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .modifier(ButtonStyleModifier(
                            background: LinearGradient(colors: [Color.white], startPoint: .leading, endPoint: .trailing),
                            foregroundColor: pages[currentPage].color,
                            cornerRadius: 16,
                            padding: EdgeInsets(top: 18, leading: 28, bottom: 18, trailing: 28),
                            font: TypographySystem.buttonLarge,
                            shadow: (color: Color.white.opacity(0.4), radius: 16, x: 0, y: 8)
                        ))
                        .scaleEffect(1.05)
                    }
                }
                .padding(.horizontal, SpacingSystem.lg)
                .padding(.bottom, SpacingSystem.xl)
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
    }

    private func completeOnboarding() {
        authService.completeOnboarding()
        withAnimation(.spring()) {
            showMainApp = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
    let gradient: LinearGradient
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}