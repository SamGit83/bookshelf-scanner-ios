import SwiftUI

struct HomeNavigationBar: View {
    @Binding var showLogin: Bool
    @Binding var showSignup: Bool
    @State private var showPopover = false
    @State private var animateNavigation = false
    @State private var logoRotation: Double = 0
    @State private var glowIntensity: Double = 0.3

    var body: some View {
        ZStack {
            // Enhanced Apple Books style background with dynamic blur
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(.ultraThinMaterial, in: Rectangle())
                .overlay(
                    // Subtle top border
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 0.5)
                        .offset(y: -40)
                )
                .ignoresSafeArea()

            HStack(spacing: 20) {
                // Enhanced App Logo and Title with branding
                HStack(spacing: 16) {
                    // Animated logo with glow effect
                    ZStack {
                        // Glow background
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "FF6B6B").opacity(glowIntensity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                            .blur(radius: 8)
                        
                        // Logo background
                        Circle()
                            .fill(EnhancedGlassEffects.primaryGlass)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                        
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF6B6B"),
                                        Color(hex: "4ECDC4")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateNavigation ? 1.0 : 0.7)
                            .rotationEffect(.degrees(logoRotation))
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: animateNavigation)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bookshelf Scanner")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(LandingPageColors.primaryText)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                        
                        Text("AI-Powered Library")
                            .font(.system(size: 11, weight: .medium, design: .default))
                            .foregroundColor(LandingPageColors.tertiaryText)
                            .opacity(animateNavigation ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.6).delay(0.4), value: animateNavigation)
                    }
                    .opacity(animateNavigation ? 1.0 : 0.0)
                    .offset(x: animateNavigation ? 0 : -20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateNavigation)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Bookshelf Scanner - AI-Powered Library app")

                Spacer()

                // Enhanced Menu Button with Apple Books styling
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showPopover = true
                    }
                }) {
                    ZStack {
                        // Background with glass effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(EnhancedGlassEffects.interactiveGlass)
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        LandingPageColors.primaryText,
                                        LandingPageColors.secondaryText
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .accessibilityLabel("Account menu")
                .accessibilityHint("Opens login and signup options")
                .scaleEffect(animateNavigation ? 1.0 : 0.8)
                .opacity(animateNavigation ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateNavigation)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
        }
        .frame(height: 88)
        .popover(isPresented: $showPopover) {
            AppleBooksAccountMenu(
                showLogin: $showLogin,
                showSignup: $showSignup,
                showPopover: $showPopover
            )
            .presentationCompactAdaptation(.popover)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateNavigation = true
            }
            
            // Logo rotation animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    logoRotation = 360
                }
            }
            
            // Glow intensity animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
        }
    }
}

// MARK: - Apple Books Account Menu
struct AppleBooksAccountMenu: View {
    @Binding var showLogin: Bool
    @Binding var showSignup: Bool
    @Binding var showPopover: Bool
    @State private var animateMenu = false
    @State private var buttonHover: String? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Enhanced Menu Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FF6B6B").opacity(0.3),
                                    Color(hex: "4ECDC4").opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(EnhancedGlassEffects.primaryGlass)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF6B6B"),
                                    Color(hex: "4ECDC4")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(animateMenu ? 1.0 : 0.7)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateMenu)
                
                VStack(spacing: 4) {
                    Text("Welcome to Bookshelf Scanner")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(LandingPageColors.primaryText)
                    
                    Text("Start your reading journey today")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(LandingPageColors.secondaryText)
                }
                .opacity(animateMenu ? 1.0 : 0.0)
                .offset(y: animateMenu ? 0 : 10)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateMenu)
            }
            
            // Enhanced Menu Actions
            VStack(spacing: 16) {
                // Sign Up Button (Primary) with Apple Books styling
                Button(action: {
                    print("HomeNavigationBar: Sign Up button tapped")
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSignup = true
                        showPopover = false
                    }
                }) {
                    HStack(spacing: 10) {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "FF6B6B"),
                                Color(hex: "FF8E53"),
                                Color(hex: "FF6B6B")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: Color(hex: "FF6B6B").opacity(buttonHover == "signup" ? 0.4 : 0.3),
                        radius: buttonHover == "signup" ? 12 : 8,
                        x: 0,
                        y: buttonHover == "signup" ? 6 : 4
                    )
                }
                .scaleEffect(buttonHover == "signup" ? 1.02 : (animateMenu ? 1.0 : 0.9))
                .opacity(animateMenu ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: animateMenu)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonHover)
                .onHover { isHovering in
                    buttonHover = isHovering ? "signup" : nil
                }
                .accessibilityLabel("Create new account")

                // Login Button (Secondary) with enhanced styling
                Button(action: {
                    print("HomeNavigationBar: Login button tapped")
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showLogin = true
                        showPopover = false
                    }
                }) {
                    HStack(spacing: 10) {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                        Image(systemName: "person.fill")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(LandingPageColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(EnhancedGlassEffects.secondaryGlass)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        Color.white.opacity(buttonHover == "login" ? 0.4 : 0.3),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(buttonHover == "login" ? 0.15 : 0.1),
                        radius: buttonHover == "login" ? 8 : 4,
                        x: 0,
                        y: buttonHover == "login" ? 4 : 2
                    )
                }
                .scaleEffect(buttonHover == "login" ? 1.02 : (animateMenu ? 1.0 : 0.9))
                .opacity(animateMenu ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4), value: animateMenu)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonHover)
                .onHover { isHovering in
                    buttonHover = isHovering ? "login" : nil
                }
                .accessibilityLabel("Sign in to existing account")
            }
            
            // Enhanced Trust Indicators
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4ECDC4"))
                    
                    Text("Secure & Private")
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(LandingPageColors.tertiaryText)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.green)
                        Text("Free Trial")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(LandingPageColors.tertiaryText)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.orange)
                        Text("Cancel Anytime")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(LandingPageColors.tertiaryText)
                    }
                }
            }
            .opacity(animateMenu ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).delay(0.5), value: animateMenu)
        }
        .padding(28)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(EnhancedGlassEffects.primaryGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateMenu = true
            }
        }
    }
}

// MARK: - Legacy Enhanced Account Menu (for compatibility)
struct EnhancedAccountMenu: View {
    @Binding var showLogin: Bool
    @Binding var showSignup: Bool
    @Binding var showPopover: Bool
    
    var body: some View {
        AppleBooksAccountMenu(
            showLogin: showLogin,
            showSignup: showSignup,
            showPopover: showPopover
        )
    }
}

struct HomeNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            HomeNavigationBar(showLogin: .constant(false), showSignup: .constant(false))
        }
        .previewLayout(.sizeThatFits)
    }
}