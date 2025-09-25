import SwiftUI

struct FeaturesSection: View {
    @State private var animateSection = false
    @State private var hoveredFeature: Int? = nil
    @State private var selectedFeature: Int? = nil

    let features = [
        Feature(
            title: "AI-Powered Scanning",
            description: "Advanced computer vision recognizes books instantly with 99% accuracy using machine learning",
            icon: "sparkles",
            color: Color(hex: "FF6B6B"),
            benefit: "Save 5+ hours of manual cataloging",
            stats: "99% accuracy"
        ),
        Feature(
            title: "Smart Organization",
            description: "Automatically organize by genre, author, or create custom collections with intelligent sorting",
            icon: "square.grid.3x3.fill",
            color: Color(hex: "4ECDC4"),
            benefit: "Find any book in seconds",
            stats: "Instant search"
        ),
        Feature(
            title: "Reading Progress",
            description: "Track pages read, set goals, and monitor your reading habits with detailed analytics",
            icon: "chart.bar.fill",
            color: Color(hex: "45B7D1"),
            benefit: "Achieve your reading goals 3x faster",
            stats: "3x faster goals"
        ),
        Feature(
            title: "Smart Recommendations",
            description: "Discover new books based on your reading patterns and preferences using AI",
            icon: "star.fill",
            color: Color(hex: "FFE66D"),
            benefit: "Never run out of great books to read",
            stats: "Personalized AI"
        ),
        Feature(
            title: "Offline Access",
            description: "Read and manage your library anywhere, even without internet connection",
            icon: "wifi.slash",
            color: Color(hex: "FF8E53"),
            benefit: "Access your library anytime, anywhere",
            stats: "100% offline"
        ),
        Feature(
            title: "Cross-Device Sync",
            description: "Seamlessly access your library across all your Apple devices with iCloud integration",
            icon: "arrow.triangle.2.circlepath",
            color: Color(hex: "B19CD9"),
            benefit: "Pick up where you left off on any device",
            stats: "All devices"
        )
    ]

    var body: some View {
        VStack(spacing: 48) {
            // Enhanced Section Header with Apple Books styling
            VStack(spacing: 20) {
                Text("Powerful Features")
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
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(y: animateSection ? 0 : 40)
                    .opacity(animateSection ? 1 : 0)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1), value: animateSection)
                    .accessibilityAddTraits(.isHeader)

                Text("Everything you need to transform your reading experience into something extraordinary")
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(LandingPageColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .lineSpacing(4)
                    .offset(y: animateSection ? 0 : 30)
                    .opacity(animateSection ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateSection)
            }

            // Enhanced Features Grid with Apple Books styling
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    AppleBooksFeatureCard(
                        feature: feature,
                        index: index,
                        isHovered: hoveredFeature == index,
                        isSelected: selectedFeature == index,
                        delay: Double(index) * 0.15
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedFeature = selectedFeature == index ? nil : index
                        }
                    }
                    .onHover { isHovering in
                        withAnimation(.easeOut(duration: 0.3)) {
                            hoveredFeature = isHovering ? index : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .offset(y: animateSection ? 0 : 40)
            .opacity(animateSection ? 1 : 0)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateSection)

            // Enhanced Social Proof Integration
            AppleBooksFeaturesSocialProof()
                .offset(y: animateSection ? 0 : 30)
                .opacity(animateSection ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateSection)
        }
        .padding(.vertical, 80)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                animateSection = true
            }
        }
    }
}

// MARK: - Enhanced Feature Data Model
struct Feature {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let benefit: String
    let stats: String
}

// MARK: - Apple Books Feature Card
struct AppleBooksFeatureCard: View {
    let feature: Feature
    let index: Int
    let isHovered: Bool
    let isSelected: Bool
    let delay: Double
    @State private var animateCard = false
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 20) {
            // Enhanced Icon with Apple Books styling
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                feature.color.opacity(isHovered ? 0.4 : 0.2),
                                feature.color.opacity(isHovered ? 0.2 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: isHovered ? 80 : 70, height: isHovered ? 80 : 70)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        feature.color.opacity(0.6),
                                        feature.color.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isHovered ? 2 : 1.5
                            )
                    )
                    .shadow(
                        color: feature.color.opacity(0.3),
                        radius: isHovered ? 12 : 6,
                        x: 0,
                        y: isHovered ? 6 : 3
                    )

                Image(systemName: feature.icon)
                    .font(.system(size: isHovered ? 32 : 28, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                feature.color,
                                feature.color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .rotationEffect(.degrees(isHovered ? 5 : 0))
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)

            // Content with Apple Books typography
            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(LandingPageColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(feature.description)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(LandingPageColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(isSelected ? nil : 3)
                    .lineSpacing(2)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }

            // Stats badge
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(feature.color)
                
                Text(feature.stats)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(feature.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(feature.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(feature.color.opacity(0.3), lineWidth: 1)
                    )
            )

            // Benefit Badge (shows on hover or selection)
            if isHovered || isSelected {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.green)
                        .font(.system(size: 14))
                    
                    Text(feature.benefit)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(LandingPageColors.primaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(EnhancedGlassEffects.secondaryGlass)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .padding(24)
        .frame(minHeight: isSelected ? 280 : 240)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.2 : 0.15),
                            Color.white.opacity(isHovered ? 0.1 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.4 : 0.3),
                                    feature.color.opacity(isHovered ? 0.3 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isHovered ? 2 : 1
                        )
                )
                .shadow(
                    color: isHovered ? feature.color.opacity(0.2) : Color.black.opacity(0.1),
                    radius: isHovered ? 20 : 10,
                    x: 0,
                    y: isHovered ? 10 : 5
                )
        )
        .scaleEffect(isHovered ? 1.05 : (isSelected ? 1.02 : 1.0))
        .offset(y: animateCard ? 0 : 40)
        .opacity(animateCard ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateCard)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSelected)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animateCard = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title): \(feature.description)")
        .accessibilityHint("Tap to expand details")
    }
}

// MARK: - Legacy Enhanced Feature Card (for compatibility)
struct EnhancedFeatureCard: View {
    let feature: Feature
    let index: Int
    let isHovered: Bool
    let delay: Double

    var body: some View {
        AppleBooksFeatureCard(
            feature: feature,
            index: index,
            isHovered: isHovered,
            isSelected: false,
            delay: delay
        )
    }
}

// MARK: - Apple Books Features Social Proof
struct AppleBooksFeaturesSocialProof: View {
    @State private var animateStats = false
    @State private var countUpAnimation = false
    
    let stats = [
        ("99%", "Recognition Accuracy", Color(hex: "FF6B6B")),
        ("5hrs", "Time Saved Weekly", Color(hex: "4ECDC4")),
        ("50K+", "Books Organized", Color(hex: "45B7D1"))
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Trusted by readers worldwide")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(LandingPageColors.primaryText)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            HStack(spacing: 40) {
                ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(stat.2.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(stat.2.opacity(0.4), lineWidth: 2)
                                )
                                .scaleEffect(animateStats ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.2), value: animateStats)
                            
                            Text(stat.0)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(stat.2)
                                .scaleEffect(countUpAnimation ? 1.0 : 0.7)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(index) * 0.2 + 0.3), value: countUpAnimation)
                        }
                        
                        Text(stat.1)
                            .font(.system(size: 13, weight: .medium, design: .default))
                            .foregroundColor(LandingPageColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(EnhancedGlassEffects.primaryGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
            )
            
            // Community indicator
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(Color(hex: "FFE66D"))
                    .font(.system(size: 16))
                
                Text("Join our growing community of book lovers")
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(LandingPageColors.tertiaryText)
            }
            .opacity(animateStats ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).delay(1.0), value: animateStats)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animateStats = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    countUpAnimation = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Statistics: 99% recognition accuracy, 5 hours saved weekly, 50,000+ books organized")
    }
}

// MARK: - Legacy Features Social Proof (for compatibility)
struct FeaturesSocialProof: View {
    var body: some View {
        AppleBooksFeaturesSocialProof()
    }
}

// MARK: - Legacy Feature Card (for compatibility)
struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let delay: Double

    @State private var animateCard = false

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                // Title
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Description
                Text(description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(20)
            .frame(height: 200)
        }
        .offset(y: animateCard ? 0 : 30)
        .opacity(animateCard ? 1 : 0)
        .animation(.spring().delay(delay), value: animateCard)
        .onAppear {
            withAnimation(.spring().delay(delay)) {
                animateCard = true
            }
        }
    }
}

struct FeaturesSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            ScrollView {
                FeaturesSection()
            }
        }
    }
}