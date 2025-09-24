import SwiftUI

// MARK: - Theme Management
enum ColorSchemePreference: String, CaseIterable {
    case light, dark, system

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let userDefaultsKey = "colorSchemePreference"

    @Published var currentPreference: ColorSchemePreference {
        didSet {
            UserDefaults.standard.set(currentPreference.rawValue, forKey: userDefaultsKey)
        }
    }

    init() {
        let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ColorSchemePreference.system.rawValue
        self.currentPreference = ColorSchemePreference(rawValue: rawValue) ?? .system
    }
}

// MARK: - Color System Extensions
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
    
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Vibrant Color Palette
struct PrimaryColors {
    static let electricBlue = Color(hex: "007AFF")      // iOS System Blue - Enhanced
    static let vibrantPurple = Color(hex: "5856D6")     // iOS System Purple
    static let energeticPink = Color(hex: "FF2D92")     // Hot Pink - Attention grabbing
    static let dynamicOrange = Color(hex: "FF9500")     // iOS System Orange
    static let freshGreen = Color(hex: "30D158")        // iOS System Green - Vibrant
}

struct SecondaryColors {
    static let deepIndigo = Color(hex: "4C4CDB")        // Rich indigo for depth
    static let coral = Color(hex: "FF6B6B")             // Warm coral for warmth
    static let turquoise = Color(hex: "40E0D0")         // Fresh turquoise for highlights
    static let lavender = Color(hex: "B19CD9")          // Soft lavender for subtlety
    static let mint = Color(hex: "00F5A0")              // Electric mint for freshness
}

struct AccentColors {
    static let neonYellow = Color(hex: "FFFF00")        // High visibility alerts
    static let electricLime = Color(hex: "32FF32")      // Success states
    static let hotMagenta = Color(hex: "FF1493")        // Critical actions
    static let cyberBlue = Color(hex: "00FFFF")         // Information highlights
    static let sunsetOrange = Color(hex: "FF4500")      // Warning states
}

struct SemanticColors {
    // Success States
    static let successPrimary = Color(hex: "30D158")
    static let successSecondary = Color(hex: "30D158").opacity(0.1)
    
    // Warning States
    static let warningPrimary = Color(hex: "FF9500")
    static let warningSecondary = Color(hex: "FF9500").opacity(0.1)
    
    // Error States
    static let errorPrimary = Color(hex: "FF3B30")
    static let errorSecondary = Color(hex: "FF3B30").opacity(0.1)
    
    // Information States
    static let infoPrimary = Color(hex: "007AFF")
    static let infoSecondary = Color(hex: "007AFF").opacity(0.1)
}

// MARK: - Adaptive Colors for Light/Dark Mode
struct AdaptiveColors {
    // Background Colors
    static let primaryBackground = Color(
        light: Color.white,
        dark: Color(hex: "000000")
    )
    
    static let secondaryBackground = Color(
        light: Color(hex: "F2F2F7"),
        dark: Color(hex: "1C1C1E")
    )
    
    static let tertiaryBackground = Color(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "2C2C2E")
    )
    
    // Text Colors
    static let primaryText = Color(
        light: Color(hex: "000000"),
        dark: Color(hex: "FFFFFF")
    )
    
    static let secondaryText = Color(
        light: Color(hex: "3C3C43").opacity(0.6),
        dark: Color(hex: "EBEBF5").opacity(0.6)
    )
    
    // Glass Effects
    static let glassBackground = Color(
        light: Color.white.opacity(0.1),
        dark: Color.white.opacity(0.05)
    )
    
    static let glassBorder = Color(
        light: Color.white.opacity(0.2),
        dark: Color.white.opacity(0.1)
    )
    
    // Vibrant Colors (Consistent across modes)
    static let vibrantPink = Color(hex: "FF2D92")
    static let vibrantPurple = Color(hex: "5856D6")
    static let vibrantBlue = Color(hex: "007AFF")
    static let vibrantGreen = Color(hex: "30D158")
    static let vibrantOrange = Color(hex: "FF9500")
}

// MARK: - Dynamic Gradient System
struct BackgroundGradients {
    // Hero Section Gradient
    static let heroGradient = LinearGradient(
        colors: [
            Color(hex: "FF2D92"),  // Hot Pink
            Color(hex: "5856D6"),  // Purple
            Color(hex: "007AFF")   // Blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Library Section Gradient
    static let libraryGradient = LinearGradient(
        colors: [
            Color(hex: "30D158"),  // Green
            Color(hex: "40E0D0"),  // Turquoise
            Color(hex: "007AFF")   // Blue
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Camera Interface Gradient
    static let cameraGradient = RadialGradient(
        colors: [
            Color(hex: "FF9500").opacity(0.8),  // Orange
            Color(hex: "FF2D92").opacity(0.6),  // Pink
            Color.black.opacity(0.4)
        ],
        center: .center,
        startRadius: 50,
        endRadius: 300
    )
    
    // Profile Section Gradient
    static let profileGradient = LinearGradient(
        colors: [
            Color(hex: "B19CD9"),  // Lavender
            Color(hex: "FF6B6B"),  // Coral
            Color(hex: "FF9500")   // Orange
        ],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
}

struct UIGradients {
    // Primary Button Gradient
    static let primaryButton = LinearGradient(
        colors: [
            Color(hex: "FF2D92"),  // Hot Pink
            Color(hex: "5856D6")   // Purple
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Secondary Button Gradient
    static let secondaryButton = LinearGradient(
        colors: [
            Color(hex: "40E0D0"),  // Turquoise
            Color(hex: "30D158")   // Green
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Card Background Gradient
    static let cardBackground = LinearGradient(
        colors: [
            Color.white.opacity(0.2),
            Color.white.opacity(0.1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Glass Effect Gradient
    static let glassEffect = LinearGradient(
        colors: [
            Color.white.opacity(0.25),
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography System
struct TypographySystem {
    // Display Typography (Headlines, Hero Text)
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    // Headline Typography (Section Headers)
    static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 20, weight: .medium, design: .rounded)
    static let headlineSmall = Font.system(size: 18, weight: .medium, design: .rounded)
    
    // Body Typography (Main Content)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // Caption Typography (Metadata, Labels)
    static let captionLarge = Font.system(size: 12, weight: .medium, design: .default)
    static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
    
    // Button Typography
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let buttonMedium = Font.system(size: 15, weight: .medium, design: .rounded)
    static let buttonSmall = Font.system(size: 13, weight: .medium, design: .rounded)
}

// MARK: - Spacing System
struct SpacingSystem {
    static let xs: CGFloat = 4      // Tight spacing
    static let sm: CGFloat = 8      // Small spacing
    static let md: CGFloat = 16     // Medium spacing (base)
    static let lg: CGFloat = 24     // Large spacing
    static let xl: CGFloat = 32     // Extra large spacing
    static let xxl: CGFloat = 48    // Section spacing
    static let xxxl: CGFloat = 64   // Page spacing
}

// MARK: - Animation System
struct AnimationTiming {
    // Micro-interactions (button presses, toggles)
    static let micro = Animation.easeOut(duration: 0.15)
    
    // UI transitions (sheet presentations, navigation)
    static let transition = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    // Loading states and progress indicators
    static let loading = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    
    // Success/error feedback
    static let feedback = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    // Page transitions
    static let pageTransition = Animation.easeInOut(duration: 0.5)
}

// MARK: - Button Style System
struct LiquidButtonStyle: ButtonStyle {
    let background: LinearGradient
    let foregroundColor: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let font: Font
    let shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)?
    let border: (color: Color, width: CGFloat)?

    init(background: LinearGradient,
         foregroundColor: Color,
         cornerRadius: CGFloat,
         padding: EdgeInsets,
         font: Font,
         shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)? = nil,
         border: (color: Color, width: CGFloat)? = nil) {
        self.background = background
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.font = font
        self.shadow = shadow
        self.border = border
    }

    func makeBody(configuration: Configuration) -> some View {
        let borderColor = border?.color ?? Color.clear
        let borderWidth = border?.width ?? 0
        let shadowColor = shadow?.color ?? Color.clear
        let shadowRadius = shadow?.radius ?? 0
        let shadowX = shadow?.x ?? 0
        let shadowY = shadow?.y ?? 0

        configuration.label
            .font(font)
            .foregroundColor(foregroundColor)
            .padding(padding)
            .background(background)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: shadowX, y: shadowY)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ButtonStyles {
    // Primary Action Button
    static func primaryButton() -> LiquidButtonStyle {
        return LiquidButtonStyle(
            background: UIGradients.primaryButton,
            foregroundColor: .white,
            cornerRadius: 16,
            padding: EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24),
            font: TypographySystem.buttonLarge,
            shadow: (color: Color(hex: "FF2D92").opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    // Secondary Action Button
    static func secondaryButton() -> LiquidButtonStyle {
        return LiquidButtonStyle(
            background: UIGradients.secondaryButton,
            foregroundColor: .white,
            cornerRadius: 16,
            padding: EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20),
            font: TypographySystem.buttonMedium,
            shadow: (color: Color(hex: "40E0D0").opacity(0.3), radius: 6, x: 0, y: 3)
        )
    }

    // Ghost Button
    static func ghostButton() -> LiquidButtonStyle {
        return LiquidButtonStyle(
            background: LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
            foregroundColor: Color(hex: "FF2D92"),
            cornerRadius: 16,
            padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
            font: TypographySystem.buttonMedium,
            border: (color: Color(hex: "FF2D92"), width: 2)
        )
    }
}

// MARK: - Card Style System
struct CardStyle<Content: View>: View {
    let content: Content
    let background: LinearGradient
    let cornerRadius: CGFloat
    let padding: CGFloat
    let shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)?
    let border: (color: Color, width: CGFloat)?
    let blur: CGFloat?

    @State private var animate = false

    var body: some View {
        let borderColor = border?.color ?? Color.clear
        let borderWidth = border?.width ?? 0
        let shadowColor = shadow?.color ?? Color.clear
        let shadowRadius = shadow?.radius ?? 0
        let shadowX = shadow?.x ?? 0
        let shadowY = shadow?.y ?? 0
        let blurRadius = blur ?? 0

        content
            .padding(padding)
            .background(background)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: shadowX, y: shadowY)
            .blur(radius: blurRadius)
    }
}

struct CardStyles {
    // Book Card Style
    static func bookCard<Content: View>(content: Content) -> CardStyle<Content> {
        return CardStyle(
            content: content,
            background: UIGradients.cardBackground,
            cornerRadius: 20,
            padding: 16,
            shadow: (color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6),
            border: (color: Color.white.opacity(0.2), width: 1),
            blur: 0
        )
    }
    
    // Feature Card Style
    static func featureCard<Content: View>(content: Content) -> CardStyle<Content> {
        return CardStyle(
            content: content,
            background: UIGradients.glassEffect,
            cornerRadius: 24,
            padding: 20,
            shadow: (color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8),
            border: (color: Color.white.opacity(0.3), width: 1),
            blur: 0
        )
    }
    
    // Recommendation Card Style
    static func recommendationCard<Content: View>(content: Content) -> CardStyle<Content> {
        return CardStyle(
            content: content,
            background: LinearGradient(
                colors: [
                    Color(hex: "FF2D92").opacity(0.1),
                    Color(hex: "5856D6").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            cornerRadius: 18,
            padding: 16,
            shadow: (color: Color(hex: "FF2D92").opacity(0.2), radius: 10, x: 0, y: 5),
            border: (color: Color(hex: "FF2D92").opacity(0.3), width: 1),
            blur: 0
        )
    }
}


// MARK: - Enhanced Animated Background
struct AnimatedBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Dynamic Gradient Background
            BackgroundGradients.heroGradient
                .ignoresSafeArea()

            // Animated floating elements
            GeometryReader { geometry in
                // First floating circle
                Circle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.15))
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .blur(radius: 40)
                    .offset(x: animate ? 20 : -20)
                    .animation(.easeInOut(duration: 4).repeatForever(), value: animate)

                // Second floating circle
                Circle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12))
                    .frame(width: geometry.size.width * 0.6)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
                    .blur(radius: 30)
                    .offset(y: animate ? -15 : 15)
                    .animation(.easeInOut(duration: 3).repeatForever(), value: animate)
                
                // Third floating circle
                Circle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.08))
                    .frame(width: geometry.size.width * 0.4)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
                    .blur(radius: 25)
                    .offset(x: animate ? -10 : 10, y: animate ? 10 : -10)
                    .animation(.easeInOut(duration: 5).repeatForever(), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Enhanced Glass Components
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var glassColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.15)
    }

    private var glassStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.white.opacity(0.3)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(glassColor)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            
            content
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(glassStrokeColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct GlassFieldStyleView<Content: View>: View {
    let content: Content
    let isValid: Bool
    let isFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(content: Content, isValid: Bool = true, isFocused: Bool = false) {
        self.content = content
        self.isValid = isValid
        self.isFocused = isFocused
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.15)
    }

    private var strokeColor: Color {
        if !isValid {
            return SemanticColors.errorPrimary
        }
        if isFocused {
            return PrimaryColors.energeticPink
        }
        return colorScheme == .dark ? Color.white.opacity(0.2) : Color.white.opacity(0.3)
    }

    var body: some View {
        content
            .padding(SpacingSystem.md)
            .background(backgroundColor)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(strokeColor, lineWidth: isFocused ? 2 : 1)
            )
            .animation(AnimationTiming.micro, value: isFocused)
            .animation(AnimationTiming.micro, value: isValid)
    }
}

// MARK: - Enhanced Form Components
struct GlassDatePicker: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var date: Date
    let isMandatory: Bool
    @State private var isFocused = false

    init(title: String, date: Binding<Date>, isMandatory: Bool = false) {
        self.title = title
        self._date = date
        self.isMandatory = isMandatory
    }

    private var textColor: Color {
        AdaptiveColors.primaryText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.sm) {
            HStack {
                Text(title)
                    .font(TypographySystem.headlineSmall)
                    .foregroundColor(textColor)
                if isMandatory {
                    Text("*")
                        .foregroundColor(SemanticColors.errorPrimary)
                        .font(TypographySystem.headlineSmall)
                }
            }

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .foregroundColor(textColor)
                .accentColor(PrimaryColors.energeticPink)
                .glassFieldStyle(isValid: true, isFocused: isFocused)
                .onTapGesture {
                    isFocused.toggle()
                }
        }
    }
}

struct GlassSegmentedPicker<T: Hashable>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayText: (T) -> String
    let isMandatory: Bool

    init(title: String, selection: Binding<T>, options: [T], displayText: @escaping (T) -> String, isMandatory: Bool = false) {
        self.title = title
        self._selection = selection
        self.options = options
        self.displayText = displayText
        self.isMandatory = isMandatory
    }

    private var textColor: Color {
        AdaptiveColors.primaryText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.sm) {
            HStack {
                Text(title)
                    .font(TypographySystem.headlineSmall)
                    .foregroundColor(textColor)
                if isMandatory {
                    Text("*")
                        .foregroundColor(SemanticColors.errorPrimary)
                        .font(TypographySystem.headlineSmall)
                }
            }

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayText(option))
                        .foregroundColor(textColor)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .background(AdaptiveColors.glassBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Translucent Overlay
struct TranslucentOverlay<Content: View>: View {
    let isVisible: Bool
    let content: Content

    init(isVisible: Bool, @ViewBuilder content: () -> Content) {
        self.isVisible = isVisible
        self.content = content()
    }

    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                content
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(AnimationTiming.transition, value: isVisible)
    }
}

// MARK: - View Extensions
extension View {
    func glassFieldStyle(isValid: Bool = true, isFocused: Bool = false) -> some View {
        GlassFieldStyleView(content: self, isValid: isValid, isFocused: isFocused)
    }
    
    func primaryButtonStyle() -> some View {
        self.buttonStyle(ButtonStyles.primaryButton())
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(ButtonStyles.secondaryButton())
    }

    func ghostButtonStyle() -> some View {
        self.buttonStyle(ButtonStyles.ghostButton())
    }
    
    func bookCardStyle() -> some View {
        CardStyles.bookCard(content: self)
    }

    func featureCardStyle() -> some View {
        CardStyles.featureCard(content: self)
    }

    func recommendationCardStyle() -> some View {
        CardStyles.recommendationCard(content: self)
    }


    func vibrantBackground(_ gradient: LinearGradient) -> some View {
        self.background(gradient.ignoresSafeArea())
    }
    
    func glassEffect() -> some View {
        self.background(UIGradients.glassEffect)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Section-Specific Color Applications
struct HomePageColors {
    static let heroBackground = BackgroundGradients.heroGradient
    static let navigationBackground = Color.white.opacity(0.1)
    static let featureCardBackground = UIGradients.cardBackground
    static let ctaButton = UIGradients.primaryButton
    static let accentElements = AccentColors.hotMagenta
}

struct LibraryColors {
    static let bookCardBackground = UIGradients.cardBackground
    static let searchBarFocus = Color(hex: "FF2D92")
    static let filterButtons = UIGradients.secondaryButton
    static let scanButton = UIGradients.primaryButton
    static let sortingAccent = AccentColors.cyberBlue
}

struct CameraColors {
    static let overlayBackground = BackgroundGradients.cameraGradient
    static let captureButton = AccentColors.hotMagenta
    static let previewFrame = AccentColors.electricLime
    static let loadingSpinner = [
        AccentColors.neonYellow,
        AccentColors.hotMagenta,
        AccentColors.cyberBlue
    ]
    static let successFeedback = SemanticColors.successPrimary
}

struct ProfileColors {
    static let headerBackground = BackgroundGradients.profileGradient
    static let statsCardBackground = UIGradients.cardBackground
    static let settingsBackground = AdaptiveColors.secondaryBackground
    static let dangerActions = SemanticColors.errorPrimary
    static let successActions = SemanticColors.successPrimary
    static let avatarBorder = AccentColors.hotMagenta
}

struct ReadingProgressColors {
    static func progressRingColor(completion: Double) -> Color {
        switch completion {
        case 0..<0.25: return AccentColors.sunsetOrange
        case 0.25..<0.5: return AccentColors.neonYellow
        case 0.5..<0.75: return AccentColors.cyberBlue
        case 0.75...1.0: return AccentColors.electricLime
        default: return Color.gray
        }
    }
    
    static let bookDetailsBackground = UIGradients.cardBackground
    static let continueButton = SemanticColors.successPrimary
    static let statisticsAccent = PrimaryColors.vibrantPurple
}

struct DiscoverColors {
    static let recommendationCard = LinearGradient(
        colors: [
            Color(hex: "FF2D92").opacity(0.1),
            Color(hex: "5856D6").opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let categoryFilters = UIGradients.secondaryButton
    static let trendingAccent = AccentColors.hotMagenta
    static let personalizedTint = PrimaryColors.vibrantPurple.opacity(0.1)
    static let addToLibraryButton = UIGradients.primaryButton
}

// MARK: - Accent Color Management
enum AccentColorScheme: String, CaseIterable, Identifiable {
    case warmOrange = "Warm Orange"
    case deepCoral = "Deep Coral"
    case vibrantPink = "Vibrant Pink"
    case electricBlue = "Electric Blue"
    case freshGreen = "Fresh Green"
    case royalPurple = "Royal Purple"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .warmOrange: return Color(hex: "FF9500")
        case .deepCoral: return Color(hex: "FF6B6B")
        case .vibrantPink: return Color(hex: "FF2D92")
        case .electricBlue: return Color(hex: "007AFF")
        case .freshGreen: return Color(hex: "30D158")
        case .royalPurple: return Color(hex: "5856D6")
        }
    }

    var displayName: String { rawValue }
}

class AccentColorManager: ObservableObject {
    static let shared = AccentColorManager()

    private let userDefaultsKey = "accentColorScheme"

    @Published var currentAccentColor: AccentColorScheme {
        didSet {
            UserDefaults.standard.set(currentAccentColor.rawValue, forKey: userDefaultsKey)
            // Force UI update by triggering objectWillChange
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    init() {
        let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey) ?? AccentColorScheme.deepCoral.rawValue
        self.currentAccentColor = AccentColorScheme(rawValue: rawValue) ?? .deepCoral
    }
}

// MARK: - Apple Books Design System

// Apple Books Color Palette
public struct AppleBooksColors {
    // Adaptive background colors that change with dark mode
    static let background = Color(
        light: Color(hex: "F2F2F7"),    // Light gray background
        dark: Color(hex: "000000")      // Pure black background
    )
    
    static let card = Color(
        light: Color.white,             // Pure white cards
        dark: Color(hex: "1C1C1E")      // Dark gray cards
    )
    
    static let text = Color(
        light: Color.black,             // Primary black text
        dark: Color.white               // Primary white text
    )
    
    static let textSecondary = Color(
        light: Color(hex: "3C3C4399"),  // 60% opacity gray
        dark: Color(hex: "EBEBF599")    // 60% opacity light gray
    )
    
    static let textTertiary = Color(
        light: Color(hex: "3C3C434D"),  // 30% opacity gray
        dark: Color(hex: "EBEBF54D")    // 30% opacity light gray
    )
    
    // Dynamic accent color that updates when AccentColorManager changes
    static var accent: Color {
        AccentColorManager.shared.currentAccentColor.color
    }
    
    static let promotional = Color(hex: "FF3B30")   // Red for promotions
    static let success = Color(hex: "34C759")      // Green for success states
}

// Apple Books Typography
public struct AppleBooksTypography {
    // Display (Large Section Headers)
    static let displayLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)

    // Headline (Section Headers)
    static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)

    // Body (Content Text)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // Caption (Descriptive Text)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)

    // Button Text
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .default)
    static let buttonMedium = Font.system(size: 15, weight: .semibold, design: .default)
}

// Apple Books Spacing
public struct AppleBooksSpacing {
    static let space2: CGFloat = 2
    static let space4: CGFloat = 4
    static let space6: CGFloat = 6
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
    static let space40: CGFloat = 40
    static let space48: CGFloat = 48
    static let space64: CGFloat = 64
    static let space80: CGFloat = 80
    static let space120: CGFloat = 120
}

// Apple Books Shadow System
public enum AppleBooksShadow {
    case subtle
    case medium
    case elevated

    var color: Color {
        switch self {
        case .subtle: return Color.black.opacity(0.06)
        case .medium: return Color.black.opacity(0.12)
        case .elevated: return Color.black.opacity(0.18)
        }
    }

    var radius: CGFloat {
        switch self {
        case .subtle: return 8
        case .medium: return 16
        case .elevated: return 24
        }
    }

    var x: CGFloat { 0 }
    var y: CGFloat {
        switch self {
        case .subtle: return 4
        case .medium: return 8
        case .elevated: return 12
        }
    }
}

// Apple Books Components
public struct AppleBooksSectionHeader: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var accentColorManager = AccentColorManager.shared
    let title: String
    let subtitle: String?
    let showSeeAll: Bool
    let seeAllAction: (() -> Void)?

    public var body: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
            HStack {
                Text(title)
                    .font(AppleBooksTypography.headlineLarge)
                    .foregroundColor(AppleBooksColors.text)

                Spacer()

                if showSeeAll {
                    Button(action: { seeAllAction?() }) {
                        Text("See All")
                            .font(AppleBooksTypography.captionBold)
                            .foregroundColor(AppleBooksColors.accent)
                    }
                }
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppleBooksTypography.caption)
                    .foregroundColor(colorScheme == .dark ? AppleBooksColors.accent : AppleBooksColors.textSecondary)
            }
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
        .padding(.vertical, AppleBooksSpacing.space16)
    }
}

public struct AppleBooksCollection: View {
    let books: [Book]
    let title: String
    let subtitle: String?
    let onBookTap: (Book) -> Void
    let onSeeAllTap: (() -> Void)?
    let viewModel: BookViewModel? // For adding books to library

    public var body: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space20) {
            AppleBooksSectionHeader(
                title: title,
                subtitle: subtitle,
                showSeeAll: onSeeAllTap != nil,
                seeAllAction: onSeeAllTap
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppleBooksSpacing.space16) {
                    ForEach(books) { book in
                        AppleBooksBookCard(
                            book: book,
                            onTap: { onBookTap(book) },
                            showAddButton: viewModel != nil,
                            onAddTap: viewModel != nil ? { viewModel?.saveBookToFirestore(book) } : nil,
                            viewModel: viewModel
                        )
                    }
                }
                .padding(.horizontal, AppleBooksSpacing.space24)
            }
        }
    }
}

public struct AppleBooksPromoBanner: View {
    let title: String
    let subtitle: String?
    let gradient: LinearGradient
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                Text(title)
                    .font(AppleBooksTypography.headlineMedium)
                    .foregroundColor(.white)
                    .bold()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppleBooksTypography.bodyMedium)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppleBooksSpacing.space24)
            .background(gradient)
            .cornerRadius(16)
        }
        .padding(.horizontal, AppleBooksSpacing.space24)
    }
}

public struct AppleBooksCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: CGFloat
    let backgroundColor: Color
    let shadowStyle: AppleBooksShadow

    init(
        cornerRadius: CGFloat = 12,
        padding: CGFloat = AppleBooksSpacing.space16,
        backgroundColor: Color = AppleBooksColors.card,
        shadowStyle: AppleBooksShadow = .subtle,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.shadowStyle = shadowStyle
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: shadowStyle.color,
                        radius: shadowStyle.radius,
                        x: shadowStyle.x,
                        y: shadowStyle.y
                    )
            )
    }
}

public struct AppleBooksBookCard: View {
    let book: Book
    let onTap: () -> Void
    let showAddButton: Bool
    let onAddTap: (() -> Void)?
    let viewModel: BookViewModel? // Add viewModel for adding to library

    @State private var isAddingToLibrary = false

    public var body: some View {
        AppleBooksCard(
            cornerRadius: 12,
            padding: AppleBooksSpacing.space12,
            shadowStyle: .subtle
        ) {
            HStack(spacing: AppleBooksSpacing.space12) {
                // Book Cover
                if let coverData = book.coverImageData,
                   let uiImage = UIImage(data: coverData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else if let coverURL = book.coverImageURL,
                          let url = URL(string: coverURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.5)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                                .overlay(
                                    VStack(spacing: 2) {
                                        Image(systemName: "book")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                        Text("No Image")
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                    }
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                        }
                    }
                    .id(book.coverImageURL) // Force refresh when URL changes
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .overlay(
                            Text("No Cover")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }

                // Book Details
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text(book.title ?? "Unknown Title")
                        .font(AppleBooksTypography.bodyLarge)
                        .bold()
                        .foregroundColor(AppleBooksColors.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(book.author ?? "Unknown Author")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.text)

                    // Row 1: Page count and reading time badges
                    HStack(spacing: AppleBooksSpacing.space6) {
                        if let pageCount = book.pageCount {
                            Text("\(pageCount) pages")
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.promotional)
                                .padding(.horizontal, AppleBooksSpacing.space6)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(AppleBooksColors.promotional.opacity(0.1))
                                .cornerRadius(4)
                        }
                        if let readingTime = book.estimatedReadingTime {
                            Text(readingTime)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.success)
                                .padding(.horizontal, AppleBooksSpacing.space6)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(AppleBooksColors.success.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    // Row 2: Sub genre badge
                    if let subGenre = book.subGenre {
                        HStack(spacing: AppleBooksSpacing.space6) {
                            Text(subGenre)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(AppleBooksColors.text)
                                .padding(.horizontal, AppleBooksSpacing.space6)
                                .padding(.vertical, AppleBooksSpacing.space2)
                                .background(AppleBooksColors.card.opacity(0.8))
                                .cornerRadius(4)
                            Spacer()
                        }
                    }
                }

                Spacer()

                // Add Button (if needed)
                if showAddButton {
                    Button(action: addToLibrary) {
                        if isAddingToLibrary {
                            ProgressView()
                                .frame(width: AppleBooksSpacing.space20, height: AppleBooksSpacing.space20)
                        } else {
                            Image(systemName: "plus")
                                .font(AppleBooksTypography.buttonMedium)
                                .foregroundColor(AppleBooksColors.accent)
                                .padding(AppleBooksSpacing.space8)
                                .background(AppleBooksColors.accent.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .disabled(isAddingToLibrary)
                }
            }
        }
        .onTapGesture(perform: onTap)
    }

    private func addToLibrary() {
        isAddingToLibrary = true
        onAddTap?()
        // Show feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isAddingToLibrary = false
        }
    }
}

// Reading Goals Section
public struct ReadingGoalsSection: View {
    public var body: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
            Text("Daily Reading Goals")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(.horizontal, AppleBooksSpacing.space24)

            // Placeholder for reading goals - you can expand this
            AppleBooksCard {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Today's Goal")
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.text)
                        Text("Read for 30 minutes")
                            .font(AppleBooksTypography.bodyMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)
                    }
                    Spacer()
                    // Progress indicator placeholder
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(AppleBooksColors.success, lineWidth: 4)
                                .frame(width: 40, height: 40)
                        )
                }
            }
            .padding(.horizontal, AppleBooksSpacing.space24)
        }
    }
}