import SwiftUI

// MARK: - Design Tokens

struct LiquidGlass {
    // MARK: - Colors

    static let primary = Color(hex: "007AFF")      // iOS Blue
    static let secondary = Color(hex: "5856D6")    // iOS Purple
    static let accent = Color(hex: "FF9500")       // iOS Orange
    static let success = Color(hex: "34C759")      // iOS Green
    static let warning = Color(hex: "FF9500")      // iOS Orange
    static let error = Color(hex: "FF3B30")        // iOS Red

    // Glass Effect Colors
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    static let glassShadow = Color.black.opacity(0.1)

    // Semantic Glass Colors
    static let successGlass = Color(hex: "34C759").opacity(0.8)
    static let warningGlass = Color(hex: "FF9500").opacity(0.8)
    static let errorGlass = Color(hex: "FF3B30").opacity(0.8)

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [primary.opacity(0.8), secondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassGradient = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [accent.opacity(0.8), Color(hex: "FF3B30").opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Typography

    struct Typography {
        static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let displaySmall = Font.system(size: 24, weight: .medium, design: .rounded)

        static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 20, weight: .medium, design: .rounded)
        static let headlineSmall = Font.system(size: 18, weight: .medium, design: .rounded)

        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)

        static let captionLarge = Font.system(size: 12, weight: .medium, design: .rounded)
        static let captionMedium = Font.system(size: 11, weight: .regular, design: .rounded)
        static let captionSmall = Font.system(size: 10, weight: .regular, design: .rounded)
    }

    // MARK: - Spacing

    struct Spacing {
        static let space4: CGFloat = 4
        static let space8: CGFloat = 8
        static let space12: CGFloat = 12
        static let space16: CGFloat = 16
        static let space20: CGFloat = 20
        static let space24: CGFloat = 24
        static let space32: CGFloat = 32
        static let space48: CGFloat = 48
        static let space64: CGFloat = 64
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let round: CGFloat = 999
    }

    // MARK: - Shadows

    struct Shadow {
        static let subtle = SwiftUI.Shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let medium = SwiftUI.Shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        static let strong = SwiftUI.Shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        static let floating = SwiftUI.Shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
    }

    // MARK: - Animations

    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.3)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let bounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)

        static func scaleEffect(_ scale: CGFloat) -> SwiftUI.Animation {
            SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Liquid Glass Modifiers

struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let blurRadius: CGFloat
    let opacity: Double

    init(cornerRadius: CGFloat = LiquidGlass.CornerRadius.large,
         blurRadius: CGFloat = 2,
         opacity: Double = 0.8) {
        self.cornerRadius = cornerRadius
        self.blurRadius = blurRadius
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
                    .blur(radius: blurRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct LiquidInteractionModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(LiquidGlass.Animation.spring, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

struct LiquidGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.1), radius: radius * 3, x: 0, y: 0)
    }
}

// MARK: - Liquid Glass Components

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: CGFloat

    init(cornerRadius: CGFloat = LiquidGlass.CornerRadius.large,
         padding: CGFloat = LiquidGlass.Spacing.space20,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
            .modifier(LiquidGlassModifier(cornerRadius: cornerRadius, blurRadius: 1))
    }
}

struct LiquidGlassButton: View {
    let title: String
    let action: () -> Void
    let style: LiquidButtonStyle
    let isLoading: Bool

    init(title: String,
         style: LiquidButtonStyle = .primary,
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    LiquidSpinner()
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(style.foregroundColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LiquidGlass.Spacing.space16)
            .background(
                RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .modifier(LiquidGlassModifier(cornerRadius: LiquidGlass.CornerRadius.large, blurRadius: 2))
        }
        .buttonStyle(PlainButtonStyle())
        .modifier(LiquidInteractionModifier())
        .disabled(isLoading)
    }
}

enum LiquidButtonStyle {
    case primary, secondary, accent, success, warning, error

    var backgroundColor: Color {
        switch self {
        case .primary: return LiquidGlass.primary.opacity(0.8)
        case .secondary: return LiquidGlass.secondary.opacity(0.8)
        case .accent: return LiquidGlass.accent.opacity(0.8)
        case .success: return LiquidGlass.success.opacity(0.8)
        case .warning: return LiquidGlass.warning.opacity(0.8)
        case .error: return LiquidGlass.error.opacity(0.8)
        }
    }

    var foregroundColor: Color {
        return .white
    }
}

struct LiquidSpinner: View {
    @State private var rotation: Angle = .zero

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 3)
                .frame(width: 32, height: 32)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [LiquidGlass.primary, LiquidGlass.secondary, LiquidGlass.accent]),
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 32, height: 32)
                .rotationEffect(rotation)
        }
        .background(
            Circle()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
                .blur(radius: 2)
        )
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = .degrees(360)
            }
        }
    }
}

// MARK: - Liquid Glass Text Field Style

struct LiquidTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(LiquidGlass.Spacing.space16)
            .background(
                RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .foregroundColor(.white)
            .font(LiquidGlass.Typography.bodyMedium)
            .accentColor(LiquidGlass.accent)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Convenience Extensions

extension View {
    func liquidGlass(cornerRadius: CGFloat = LiquidGlass.CornerRadius.large,
                     blurRadius: CGFloat = 2,
                     opacity: Double = 0.8) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius,
                                   blurRadius: blurRadius,
                                   opacity: opacity))
    }

    func liquidInteraction() -> some View {
        modifier(LiquidInteractionModifier())
    }

    func liquidGlow(color: Color = LiquidGlass.primary, radius: CGFloat = 8) -> some View {
        modifier(LiquidGlowModifier(color: color, radius: radius))
    }
}