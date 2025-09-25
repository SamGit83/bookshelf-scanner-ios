import SwiftUI

struct HeroSection: View {
    @Binding var showSignup: Bool
    @Binding var showLogin: Bool
    @State private var animateContent = false
    @State private var pulseAnimation = false
    @State private var socialProofCount = 50247
    @State private var showUrgency = false
    @State private var floatingAnimation = false
    @State private var glowIntensity: Double = 0.3

    var body: some View {
        VStack(spacing: 48) {
            Spacer(minLength: 80)

            // Enhanced App Icon with multi-layered glow effects
            ZStack {
                // Outer dynamic glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FF6B6B").opacity(glowIntensity),
                                Color(hex: "4ECDC4").opacity(glowIntensity * 0.7),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 25)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // Middle glow with color transition
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color(hex: "45B7D1").opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 18)
                    .offset(y: floatingAnimation ? -5 : 5)
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: floatingAnimation)
                
                // Inner glass background
                Circle()
                    .fill(EnhancedGlassEffects.primaryGlass)
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )

                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 55, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateContent ? 1.0 : 0.7)
                    .rotationEffect(.degrees(animateContent ? 0 : -10))
                    .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.3), value: animateContent)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("Bookshelf Scanner app icon")

            // Enhanced Headlines with Apple Books typography
            VStack(spacing: 24) {
                Text("Transform Your Reading Life")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1), value: animateContent)
                    .accessibilityAddTraits(.isHeader)

                Text("Scan your physical books with AI, discover new reads, and track your reading journey—all in one beautiful app.")
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(LandingPageColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(6)
                    .offset(y: animateContent ? 0 : 30)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateContent)
            }

            // Enhanced Social Proof Counter with Apple Books styling
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "FF6B6B"))
                    
                    Text("Join \(socialProofCount.formatted())+ readers")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(LandingPageColors.primaryText)
                    
                    if showUrgency {
                        Text("• 127 joined today")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4ECDC4"))
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                
                // Live activity indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text("Live community")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(LandingPageColors.tertiaryText)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(EnhancedGlassEffects.primaryGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .offset(y: animateContent ? 0 : 25)
            .opacity(animateContent ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Join \(socialProofCount) readers in our community")

            // Enhanced CTA Buttons with Apple Books styling
            VStack(spacing: 20) {
                // Primary CTA with enhanced design
                Button(action: {
                    print("HeroSection: Start Your Journey button tapped")
                    showSignup = true
                }) {
                    HStack(spacing: 12) {
                        Text("Start Your Journey")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
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
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "FF6B6B").opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: animateContent)
                .accessibilityLabel("Start your reading journey")
                .accessibilityHint("Opens account creation")
                
                // Secondary CTA with improved styling
                Button(action: {
                    print("HeroSection: Sign In button tapped")
                    showLogin = true
                }) {
                    HStack(spacing: 8) {
                        Text("Already have an account?")
                            .font(.system(size: 16, weight: .regular))
                        Text("Sign In")
                            .font(.system(size: 16, weight: .semibold))
                            .underline()
                    }
                    .foregroundColor(LandingPageColors.secondaryText)
                }
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: animateContent)
                .accessibilityLabel("Sign in to existing account")
            }
            .padding(.horizontal, 32)

            // Enhanced Trust Indicators with Apple Books styling
            HStack(spacing: 20) {
                EnhancedTrustBadge(
                    icon: "lock.shield.fill",
                    text: "Privacy First",
                    color: Color(hex: "4ECDC4")
                )
                EnhancedTrustBadge(
                    icon: "checkmark.seal.fill",
                    text: "7-Day Free Trial",
                    color: Color(hex: "45B7D1")
                )
                EnhancedTrustBadge(
                    icon: "xmark.circle.fill",
                    text: "Cancel Anytime",
                    color: Color(hex: "FFE66D")
                )
            }
            .offset(y: animateContent ? 0 : 25)
            .opacity(animateContent ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6), value: animateContent)

            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.85)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                animateContent = true
            }
            
            // Start animations with staggered delays
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulseAnimation = true
                floatingAnimation = true
            }
            
            // Dynamic glow intensity animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
            
            // Show urgency after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showUrgency = true
                }
            }
            
            // Animate social proof counter with more realistic increments
            Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    socialProofCount += Int.random(in: 1...2)
                }
            }
        }
    }
}

// MARK: - Enhanced Trust Badge Component
struct EnhancedTrustBadge: View {
    let icon: String
    let text: String
    let color: Color
    @State private var animateBadge = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            .scaleEffect(animateBadge ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateBadge)
            
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(LandingPageColors.tertiaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onAppear {
            animateBadge = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text) feature")
    }
}

// MARK: - Legacy Trust Badge Component (for compatibility)
struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        EnhancedTrustBadge(
            icon: icon,
            text: text,
            color: LandingPageColors.interactive
        )
    }
}

struct HeroSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LandingPageColors.heroGradient
                .ignoresSafeArea()
            
            ScrollView {
                HeroSection(showSignup: .constant(false), showLogin: .constant(false))
            }
        }
        .preferredColorScheme(.dark)
    }
}