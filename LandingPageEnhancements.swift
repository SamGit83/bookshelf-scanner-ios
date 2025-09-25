import SwiftUI

// MARK: - Landing Page Accessibility Enhancements
struct LandingPageAccessibilityEnhancements {
    
    // MARK: - VoiceOver Support
    static func configureVoiceOver() {
        // Custom accessibility actions for landing page
    }
    
    // MARK: - Dynamic Type Support
    static func scaledFont(_ font: Font, for category: UIContentSizeCategory) -> Font {
        switch category {
        case .extraSmall, .small, .medium:
            return font
        case .large, .extraLarge:
            return font
        case .extraExtraLarge, .extraExtraExtraLarge:
            return font
        case .accessibilityMedium, .accessibilityLarge:
            return font
        case .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return font
        default:
            return font
        }
    }
    
    // MARK: - High Contrast Support
    static func highContrastColor(_ color: Color, for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return color.opacity(1.0)
        } else {
            return color
        }
    }
}

// MARK: - Responsive Design Utilities
struct ResponsiveDesign {
    
    // MARK: - Device Size Detection
    static func deviceSize() -> DeviceSize {
        let screenWidth = UIScreen.main.bounds.width
        
        switch screenWidth {
        case 0..<375:
            return .compact // iPhone SE
        case 375..<414:
            return .regular // iPhone Pro
        case 414..<430:
            return .large // iPhone Pro Max
        default:
            return .extraLarge // iPad
        }
    }
    
    // MARK: - Adaptive Spacing
    static func adaptiveSpacing(_ baseSpacing: CGFloat) -> CGFloat {
        let device = deviceSize()
        
        switch device {
        case .compact:
            return baseSpacing * 0.8
        case .regular:
            return baseSpacing
        case .large:
            return baseSpacing * 1.1
        case .extraLarge:
            return baseSpacing * 1.3
        }
    }
    
    // MARK: - Adaptive Typography
    static func adaptiveFont(_ baseFont: Font) -> Font {
        let device = deviceSize()
        
        switch device {
        case .compact:
            return baseFont
        case .regular:
            return baseFont
        case .large:
            return baseFont
        case .extraLarge:
            return baseFont
        }
    }
}

enum DeviceSize {
    case compact    // iPhone SE
    case regular    // iPhone Pro
    case large      // iPhone Pro Max
    case extraLarge // iPad
}

// MARK: - Performance Optimizations
struct PerformanceOptimizations {
    
    // MARK: - Animation Performance
    static func shouldUseReducedMotion() -> Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
    
    static func optimizedAnimation(_ animation: Animation) -> Animation {
        if shouldUseReducedMotion() {
            return .easeInOut(duration: 0.2)
        }
        return animation
    }
    
    // MARK: - Memory Management
    static func limitConcurrentAnimations() -> Int {
        let device = ResponsiveDesign.deviceSize()
        
        switch device {
        case .compact:
            return 2
        case .regular:
            return 3
        case .large:
            return 4
        case .extraLarge:
            return 6
        }
    }
}

// MARK: - Enhanced View Modifiers
struct LandingPageViewModifiers {
    
    // MARK: - Consistent Card Style
    struct LandingPageCard: ViewModifier {
        let cornerRadius: CGFloat
        let padding: CGFloat
        let shadowStyle: ShadowStyle
        
        func body(content: Content) -> some View {
            content
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LandingPageDesignSystem.GlassEffects.primaryGlass)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(
                            color: shadowStyle.color,
                            radius: shadowStyle.radius,
                            x: shadowStyle.x,
                            y: shadowStyle.y
                        )
                )
        }
    }
    
    // MARK: - Consistent Button Style
    struct LandingPageButton: ViewModifier {
        let style: ButtonStyleType
        let isHovered: Bool
        
        func body(content: Content) -> some View {
            content
                .font(style.font)
                .foregroundColor(style.foregroundColor)
                .padding(.horizontal, style.horizontalPadding)
                .padding(.vertical, style.verticalPadding)
                .background(style.background)
                .cornerRadius(style.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                )
                .shadow(
                    color: style.shadowColor,
                    radius: isHovered ? style.shadowRadius * 1.5 : style.shadowRadius,
                    x: 0,
                    y: isHovered ? style.shadowY * 1.5 : style.shadowY
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
    }
    
    // MARK: - Consistent Animation Entry
    struct LandingPageEntry: ViewModifier {
        let delay: Double
        let offset: CGFloat
        @State private var animate = false
        
        func body(content: Content) -> some View {
            content
                .offset(y: animate ? 0 : offset)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(delay), value: animate)
                .onAppear {
                    animate = true
                }
        }
    }
}

// MARK: - Button Style Types
enum ButtonStyleType {
    case primary
    case secondary
    case ghost
    case cta
    
    var font: Font {
        switch self {
        case .primary, .cta:
            return LandingPageDesignSystem.Typography.ctaLarge
        case .secondary:
            return LandingPageDesignSystem.Typography.ctaMedium
        case .ghost:
            return LandingPageDesignSystem.Typography.ctaSmall
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .cta:
            return .white
        case .secondary:
            return LandingPageDesignSystem.Colors.primaryText
        case .ghost:
            return LandingPageDesignSystem.Colors.interactive
        }
    }
    
    var background: LinearGradient {
        switch self {
        case .primary, .cta:
            return LinearGradient(
                colors: [
                    Color(hex: "FF6B6B"),
                    Color(hex: "FF8E53")
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            return LandingPageDesignSystem.GlassEffects.secondaryGlass
        case .ghost:
            return LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .primary, .cta: return 32
        case .secondary: return 24
        case .ghost: return 16
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .primary, .cta: return 18
        case .secondary: return 14
        case .ghost: return 12
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .primary, .cta: return 28
        case .secondary: return 16
        case .ghost: return 12
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary, .cta: return Color.white.opacity(0.2)
        case .secondary: return Color.white.opacity(0.3)
        case .ghost: return LandingPageDesignSystem.Colors.interactive
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .primary, .cta, .secondary: return 1
        case .ghost: return 2
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary, .cta: return Color(hex: "FF6B6B").opacity(0.4)
        case .secondary: return Color.black.opacity(0.1)
        case .ghost: return Color.clear
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .primary, .cta: return 15
        case .secondary: return 8
        case .ghost: return 0
        }
    }
    
    var shadowY: CGFloat {
        switch self {
        case .primary, .cta: return 8
        case .secondary: return 4
        case .ghost: return 0
        }
    }
}

// MARK: - Shadow Style Types
enum ShadowStyle {
    case subtle
    case medium
    case elevated
    case glow(Color)
    
    var color: Color {
        switch self {
        case .subtle: return Color.black.opacity(0.1)
        case .medium: return Color.black.opacity(0.15)
        case .elevated: return Color.black.opacity(0.2)
        case .glow(let color): return color.opacity(0.3)
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .subtle: return 8
        case .medium: return 12
        case .elevated: return 20
        case .glow: return 15
        }
    }
    
    var x: CGFloat { 0 }
    
    var y: CGFloat {
        switch self {
        case .subtle: return 4
        case .medium: return 6
        case .elevated: return 10
        case .glow: return 8
        }
    }
}

// MARK: - View Extensions for Landing Page
extension View {
    func landingPageCard(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 24,
        shadowStyle: ShadowStyle = .medium
    ) -> some View {
        self.modifier(
            LandingPageViewModifiers.LandingPageCard(
                cornerRadius: cornerRadius,
                padding: padding,
                shadowStyle: shadowStyle
            )
        )
    }
    
    func landingPageButton(
        style: ButtonStyleType,
        isHovered: Bool = false
    ) -> some View {
        self.modifier(
            LandingPageViewModifiers.LandingPageButton(
                style: style,
                isHovered: isHovered
            )
        )
    }
    
    func landingPageEntry(
        delay: Double = 0.0,
        offset: CGFloat = 30
    ) -> some View {
        self.modifier(
            LandingPageViewModifiers.LandingPageEntry(
                delay: delay,
                offset: offset
            )
        )
    }
    
    func adaptiveSpacing(_ spacing: CGFloat) -> some View {
        self.padding(ResponsiveDesign.adaptiveSpacing(spacing))
    }
    
    func optimizedAnimation(_ animation: Animation) -> some View {
        self.animation(PerformanceOptimizations.optimizedAnimation(animation), value: true)
    }
}