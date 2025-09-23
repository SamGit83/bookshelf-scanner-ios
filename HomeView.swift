import SwiftUI

struct HomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var showLogin = false
    @State private var showSignup = false

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Navigation Bar
                    HomeNavigationBar(showLogin: $showLogin, showSignup: $showSignup)

                    // Hero Section
                    HeroSection(showSignup: $showSignup)

                    // User Journey Section
                    UserJourneySection()

                    // Features Section
                    FeaturesSection()

                    // Footer
                    HomeFooter()
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showSignup) {
            // For now, show login view - you might want to create a separate signup view
            LoginView()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}