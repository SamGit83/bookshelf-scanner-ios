import SwiftUI

struct HomeFooter: View {
    @State private var animateFooter = false
    @State private var showNewsletter = false
    @State private var ctaPulse = false
    
    let socialLinks = [
        SocialLink(name: "Twitter", icon: "twitter", url: "https://twitter.com/bookshelfscanner"),
        SocialLink(name: "Instagram", icon: "instagram", url: "https://instagram.com/bookshelfscanner"),
        SocialLink(name: "LinkedIn", icon: "linkedin", url: "https://linkedin.com/company/bookshelfscanner")
    ]
    
    let legalLinks = [
        "Privacy Policy",
        "Terms of Service",
        "Contact Us"
    ]

    var body: some View {
        VStack(spacing: 48) {
            // Enhanced Final CTA Section
            AppleBooksFinalCTASection(ctaPulse: $ctaPulse)
                .opacity(animateFooter ? 1.0 : 0.0)
                .offset(y: animateFooter ? 0 : 40)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateFooter)
            
            // Enhanced Newsletter Signup
            AppleBooksNewsletterSignup(showNewsletter: $showNewsletter)
                .opacity(animateFooter ? 1.0 : 0.0)
                .offset(y: animateFooter ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateFooter)
            
            // Enhanced Trust Badges
            AppleBooksTrustBadgesSection()
                .opacity(animateFooter ? 1.0 : 0.0)
                .offset(y: animateFooter ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateFooter)
            
            // Enhanced Social Links
            AppleBooksSocialLinksSection(socialLinks: socialLinks)
                .opacity(animateFooter ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.4), value: animateFooter)
            
            // Enhanced Legal Links
            AppleBooksLegalLinksSection(legalLinks: legalLinks)
                .opacity(animateFooter ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.5), value: animateFooter)

            // Enhanced Copyright
            VStack(spacing: 12) {
                Text("© 2024 Bookshelf Scanner. All rights reserved.")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(LandingPageColors.tertiaryText)
                
                HStack(spacing: 8) {
                    Text("Made with")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(LandingPageColors.tertiaryText.opacity(0.8))
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .scaleEffect(ctaPulse ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: ctaPulse)
                    
                    Text("for book lovers everywhere")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(LandingPageColors.tertiaryText.opacity(0.8))
                }
            }
            .opacity(animateFooter ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.6).delay(0.6), value: animateFooter)
        }
        .padding(.vertical, 80)
        .padding(.horizontal, 28)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                // Subtle top border
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .offset(y: -40)
            )
        )
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
                animateFooter = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ctaPulse = true
            }
        }
    }
}

// MARK: - Social Link Model
struct SocialLink {
    let name: String
    let icon: String
    let url: String
}

// MARK: - Apple Books Final CTA Section
struct AppleBooksFinalCTASection: View {
    @Binding var ctaPulse: Bool
    @State private var glowIntensity: Double = 0.3
    @State private var buttonHover = false
    
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 16) {
                Text("Ready to Transform Your Reading?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                LandingPageColors.primaryText,
                                LandingPageColors.primaryText.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Join thousands of readers who've already organized their libraries and discovered their next favorite books")
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(LandingPageColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            // Enhanced CTA with multiple options
            VStack(spacing: 16) {
                // Primary CTA
                Button(action: {
                    print("Footer CTA: Get Started Free tapped")
                    // Handle final CTA action
                }) {
                    ZStack {
                        // Glow effect
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "FF6B6B").opacity(glowIntensity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(height: 64)
                            .blur(radius: 12)
                        
                        HStack(spacing: 12) {
                            Text("Get Started Free")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20, weight: .medium))
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
                        .cornerRadius(32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(
                            color: Color(hex: "FF6B6B").opacity(0.5),
                            radius: buttonHover ? 25 : 20,
                            x: 0,
                            y: buttonHover ? 12 : 10
                        )
                    }
                }
                .scaleEffect(buttonHover ? 1.02 : (ctaPulse ? 1.01 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonHover)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: ctaPulse)
                .onHover { isHovering in
                    buttonHover = isHovering
                }
                .accessibilityLabel("Get started with free trial")
                .accessibilityHint("Opens account creation")
                
                // Secondary options
                HStack(spacing: 24) {
                    Button(action: {
                        print("Footer: Learn More tapped")
                    }) {
                        HStack(spacing: 6) {
                            Text("Learn More")
                            Image(systemName: "info.circle")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(LandingPageColors.secondaryText)
                        .underline()
                    }
                    .accessibilityLabel("Learn more about features")
                    
                    Button(action: {
                        print("Footer: Watch Demo tapped")
                    }) {
                        HStack(spacing: 6) {
                            Text("Watch Demo")
                            Image(systemName: "play.circle")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(LandingPageColors.secondaryText)
                        .underline()
                    }
                    .accessibilityLabel("Watch product demo")
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
        }
    }
}

// MARK: - Legacy Final CTA Section (for compatibility)
struct FinalCTASection: View {
    var body: some View {
        AppleBooksFinalCTASection(ctaPulse: .constant(true))
    }
}

// MARK: - Apple Books Newsletter Signup
struct AppleBooksNewsletterSignup: View {
    @Binding var showNewsletter: Bool
    @State private var email = ""
    @State private var isSubscribed = false
    @State private var isHovered = false
    @State private var fieldFocused = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "4ECDC4").opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "4ECDC4"))
                    }
                    
                    Text("Stay Updated")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(LandingPageColors.primaryText)
                }
                
                Text("Get reading tips, book recommendations, and app updates")
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(LandingPageColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            if !isSubscribed {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Enter your email address", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(EnhancedGlassEffects.secondaryGlass)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                fieldFocused ? Color(hex: "4ECDC4").opacity(0.5) : Color.white.opacity(0.3),
                                                lineWidth: fieldFocused ? 2 : 1
                                            )
                                    )
                            )
                            .foregroundColor(LandingPageColors.primaryText)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .onTapGesture {
                                fieldFocused = true
                            }
                        
                        Button(action: subscribeToNewsletter) {
                            HStack(spacing: 8) {
                                Text("Subscribe")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "4ECDC4"),
                                        Color(hex: "45B7D1")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: Color(hex: "4ECDC4").opacity(0.3),
                                radius: isHovered ? 12 : 8,
                                x: 0,
                                y: isHovered ? 6 : 4
                            )
                        }
                        .scaleEffect(isHovered ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                        .onHover { hovering in
                            isHovered = hovering
                        }
                        .disabled(email.isEmpty)
                    }
                    .frame(maxWidth: 480)
                    
                    // Privacy note
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "4ECDC4"))
                        
                        Text("We respect your privacy. Unsubscribe anytime.")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(LandingPageColors.tertiaryText)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.green)
                        
                        Text("Thanks for subscribing!")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(LandingPageColors.primaryText)
                    }
                    
                    Text("You'll receive our next newsletter with reading tips and recommendations")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(LandingPageColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EnhancedGlassEffects.primaryGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Newsletter signup")
    }
    
    private func subscribeToNewsletter() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isSubscribed = true
        }
        
        // Reset after 4 seconds for demo purposes
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 0.6)) {
                isSubscribed = false
                email = ""
                fieldFocused = false
            }
        }
    }
}

// MARK: - Legacy Newsletter Signup (for compatibility)
struct NewsletterSignup: View {
    @Binding var showNewsletter: Bool
    
    var body: some View {
        AppleBooksNewsletterSignup(showNewsletter: showNewsletter)
    }
}

// MARK: - Apple Books Trust Badges Section
struct AppleBooksTrustBadgesSection: View {
    @State private var animateBadges = false
    
    let badges = [
        AppleBooksTrustBadge(
            icon: "star.fill",
            text: "4.8★ Rating",
            subtext: "12K+ Reviews",
            color: Color(hex: "FFE66D")
        ),
        AppleBooksTrustBadge(
            icon: "shield.checkered",
            text: "Privacy First",
            subtext: "GDPR Compliant",
            color: Color(hex: "4ECDC4")
        ),
        AppleBooksTrustBadge(
            icon: "checkmark.seal.fill",
            text: "Featured by Apple",
            subtext: "App Store",
            color: Color(hex: "45B7D1")
        )
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Trusted by Readers Worldwide")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(LandingPageColors.primaryText)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 0.5)
            
            HStack(spacing: 32) {
                ForEach(Array(badges.enumerated()), id: \.offset) { index, badge in
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(badge.color.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(badge.color.opacity(0.4), lineWidth: 1.5)
                                )
                                .scaleEffect(animateBadges ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.2), value: animateBadges)
                            
                            Image(systemName: badge.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(badge.color)
                        }
                        
                        VStack(spacing: 4) {
                            Text(badge.text)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(LandingPageColors.primaryText)
                                .multilineTextAlignment(.center)
                            
                            Text(badge.subtext)
                                .font(.system(size: 12, weight: .regular, design: .default))
                                .foregroundColor(LandingPageColors.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(animateBadges ? 1.0 : 0.0)
                    .offset(y: animateBadges ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.15), value: animateBadges)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EnhancedGlassEffects.primaryGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                animateBadges = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trust indicators: 4.8 star rating with 12,000+ reviews, privacy first and GDPR compliant, featured by Apple on App Store")
    }
}

struct AppleBooksTrustBadge {
    let icon: String
    let text: String
    let subtext: String
    let color: Color
}

// MARK: - Legacy Trust Badges Section (for compatibility)
struct TrustBadgesSection: View {
    var body: some View {
        AppleBooksTrustBadgesSection()
    }
}

struct TrustBadge {
    let icon: String
    let text: String
    let subtext: String
}

// MARK: - Social Links Section
struct SocialLinksSection: View {
    let socialLinks: [SocialLink]
    @State private var hoveredLink: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Follow Us")
                .font(LandingPageTypography.journeyBody)
                .foregroundColor(LandingPageColors.secondaryText)
            
            HStack(spacing: 20) {
                ForEach(socialLinks, id: \.name) { link in
                    Button(action: {
                        print("Social link tapped: \(link.name)")
                        // Handle social link tap
                    }) {
                        Image(systemName: getSocialIcon(for: link.icon))
                            .font(.system(size: 24))
                            .foregroundColor(hoveredLink == link.name ? LandingPageColors.interactive : LandingPageColors.tertiaryText)
                            .scaleEffect(hoveredLink == link.name ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredLink)
                    }
                    .onHover { isHovering in
                        hoveredLink = isHovering ? link.name : nil
                    }
                    .accessibilityLabel("\(link.name) social media")
                }
            }
        }
    }
    
    private func getSocialIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case "twitter": return "message.fill"
        case "instagram": return "camera.fill"
        case "linkedin": return "person.2.fill"
        default: return "link"
        }
    }
}

// MARK: - Legal Links Section
struct LegalLinksSection: View {
    let legalLinks: [String]
    
    var body: some View {
        HStack(spacing: 32) {
            ForEach(legalLinks, id: \.self) { link in
                Button(action: {
                    print("Legal link tapped: \(link)")
                    // Handle legal link tap
                }) {
                    Text(link)
                        .font(.caption)
                        .foregroundColor(LandingPageColors.tertiaryText)
                        .underline()
                }
                .accessibilityLabel(link)
            }
        }
    }
}

struct HomeFooter_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            HomeFooter()
        }
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Apple Books Social Links Section
struct AppleBooksSocialLinksSection: View {
    let socialLinks: [SocialLink]
    @State private var hoveredLink: String? = nil
    @State private var animateLinks = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect With Us")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(LandingPageColors.primaryText)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 0.5)
            
            HStack(spacing: 24) {
                ForEach(Array(socialLinks.enumerated()), id: \.offset) { index, link in
                    Button(action: {
                        print("Social link tapped: \(link.name)")
                        // Handle social link tap
                    }) {
                        ZStack {
                            Circle()
                                .fill(getSocialColor(for: link.icon).opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            getSocialColor(for: link.icon).opacity(hoveredLink == link.name ? 0.6 : 0.4),
                                            lineWidth: hoveredLink == link.name ? 2 : 1
                                        )
                                )
                                .shadow(
                                    color: getSocialColor(for: link.icon).opacity(hoveredLink == link.name ? 0.3 : 0.1),
                                    radius: hoveredLink == link.name ? 8 : 4,
                                    x: 0,
                                    y: hoveredLink == link.name ? 4 : 2
                                )
                            
                            Image(systemName: getSocialIcon(for: link.icon))
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(getSocialColor(for: link.icon))
                        }
                        .scaleEffect(hoveredLink == link.name ? 1.1 : (animateLinks ? 1.0 : 0.8))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hoveredLink)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateLinks)
                    }
                    .onHover { isHovering in
                        hoveredLink = isHovering ? link.name : nil
                    }
                    .accessibilityLabel("\(link.name) social media")
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateLinks = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Social media links")
    }
    
    private func getSocialIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case "twitter": return "message.fill"
        case "instagram": return "camera.fill"
        case "linkedin": return "person.2.fill"
        default: return "link"
        }
    }
    
    private func getSocialColor(for platform: String) -> Color {
        switch platform.lowercased() {
        case "twitter": return Color(hex: "45B7D1")
        case "instagram": return Color(hex: "FF6B6B")
        case "linkedin": return Color(hex: "4ECDC4")
        default: return LandingPageColors.interactive
        }
    }
}

// MARK: - Apple Books Legal Links Section
struct AppleBooksLegalLinksSection: View {
    let legalLinks: [String]
    @State private var hoveredLink: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Legal & Support")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(LandingPageColors.secondaryText)
            
            HStack(spacing: 28) {
                ForEach(legalLinks, id: \.self) { link in
                    Button(action: {
                        print("Legal link tapped: \(link)")
                        // Handle legal link tap
                    }) {
                        Text(link)
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(
                                hoveredLink == link ? LandingPageColors.primaryText : LandingPageColors.tertiaryText
                            )
                            .underline(hoveredLink == link)
                            .scaleEffect(hoveredLink == link ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredLink)
                    }
                    .onHover { isHovering in
                        hoveredLink = isHovering ? link : nil
                    }
                    .accessibilityLabel(link)
                }
            }
        }
    }
}