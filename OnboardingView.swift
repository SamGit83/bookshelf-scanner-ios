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
            color: .blue
        ),
        OnboardingPage(
            title: "Scan Your Books",
            description: "Point your camera at your bookshelf and watch as our AI identifies your books automatically.",
            imageName: "camera.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Build Your Library",
            description: "Organize your books into collections, track your reading progress, and discover new favorites.",
            imageName: "building.columns.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Set reading goals, log your sessions, and watch your reading habits come to life with detailed analytics.",
            imageName: "chart.bar.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Smart Recommendations",
            description: "Get personalized book suggestions based on your reading history and preferences.",
            imageName: "sparkles",
            color: .pink
        ),
        OnboardingPage(
            title: "Ready to Begin!",
            description: "Let's start building your digital bookshelf. You can always access this tutorial from settings.",
            imageName: "checkmark.circle.fill",
            color: .teal
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient that changes with pages
            LinearGradient(
                gradient: Gradient(colors: [
                    pages[currentPage].color.opacity(0.3),
                    pages[currentPage].color.opacity(0.1),
                    .clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                // Page Content
                VStack(spacing: 32) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? pages[currentPage].color : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)

                        Image(systemName: pages[currentPage].imageName)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .scaleEffect(currentPage == 0 ? 1.0 : 0.8)
                            .animation(.spring().delay(0.2), value: currentPage)
                    }

                    // Text Content
                    VStack(spacing: 16) {
                        Text(pages[currentPage].title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .animation(.spring().delay(0.1), value: currentPage)

                        Text(pages[currentPage].description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .animation(.spring().delay(0.3), value: currentPage)
                    }
                }

                Spacer()

                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.spring()) {
                                currentPage -= 1
                            }
                        }) {
                            Text("Previous")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.spring()) {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(pages[currentPage].color)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Get Started")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(pages[currentPage].color)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
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
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}