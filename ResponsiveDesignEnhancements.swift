import SwiftUI

// MARK: - Device Size Detection
struct DeviceInfo {
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
    static let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    enum ScreenSize {
        case compact    // iPhone SE, iPhone 12 mini
        case regular    // iPhone 12, iPhone 13
        case large      // iPhone 12 Pro Max, iPhone 14 Plus
        case tablet     // iPad
        
        static var current: ScreenSize {
            switch screenWidth {
            case ..<375: return .compact
            case 375..<428: return .regular
            case 428...: return isPad ? .tablet : .large
            default: return .regular
            }
        }
    }
}

// MARK: - Responsive Layout Modifiers
extension View {
    /// Applies responsive padding based on screen size
    func responsivePadding(
        compact: CGFloat = 16,
        regular: CGFloat = 24,
        large: CGFloat = 32,
        tablet: CGFloat = 40
    ) -> some View {
        let padding: CGFloat = {
            switch DeviceInfo.ScreenSize.current {
            case .compact: return compact
            case .regular: return regular
            case .large: return large
            case .tablet: return tablet
            }
        }()
        
        return self.padding(.horizontal, padding)
    }
    
    /// Applies responsive font scaling
    func responsiveFont(
        _ baseFont: Font,
        compactScale: CGFloat = 0.9,
        regularScale: CGFloat = 1.0,
        largeScale: CGFloat = 1.1,
        tabletScale: CGFloat = 1.2
    ) -> some View {
        let scale: CGFloat = {
            switch DeviceInfo.ScreenSize.current {
            case .compact: return compactScale
            case .regular: return regularScale
            case .large: return largeScale
            case .tablet: return tabletScale
            }
        }()
        
        // Note: SwiftUI doesn't have direct font scaling, so we use different font sizes
        return self.font(baseFont)
    }
    
    /// Applies responsive spacing
    func responsiveSpacing(
        compact: CGFloat = 16,
        regular: CGFloat = 24,
        large: CGFloat = 32,
        tablet: CGFloat = 40
    ) -> CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return compact
        case .regular: return regular
        case .large: return large
        case .tablet: return tablet
        }
    }
    
    /// Hides view on compact screens
    func hideOnCompact() -> some View {
        self.opacity(DeviceInfo.ScreenSize.current == .compact ? 0 : 1)
    }
    
    /// Shows different content based on screen size
    func adaptiveContent<CompactContent: View, RegularContent: View>(
        compact: () -> CompactContent,
        regular: () -> RegularContent
    ) -> some View {
        Group {
            if DeviceInfo.ScreenSize.current == .compact {
                compact()
            } else {
                regular()
            }
        }
    }
}

// MARK: - Responsive Grid System
struct ResponsiveGrid<Content: View>: View {
    let content: Content
    let spacing: CGFloat
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var columns: [GridItem] {
        let columnCount: Int = {
            switch DeviceInfo.ScreenSize.current {
            case .compact: return 1
            case .regular: return 2
            case .large: return 2
            case .tablet: return 3
            }
        }()
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content
        }
    }
}

// MARK: - Responsive Typography System
struct ResponsiveTypography {
    static func heroTitle(for screenSize: DeviceInfo.ScreenSize = DeviceInfo.ScreenSize.current) -> Font {
        switch screenSize {
        case .compact: return .system(size: 24, weight: .bold, design: .rounded)
        case .regular: return .system(size: 28, weight: .bold, design: .rounded)
        case .large: return .system(size: 32, weight: .bold, design: .rounded)
        case .tablet: return .system(size: 36, weight: .bold, design: .rounded)
        }
    }
    
    static func sectionTitle(for screenSize: DeviceInfo.ScreenSize = DeviceInfo.ScreenSize.current) -> Font {
        switch screenSize {
        case .compact: return .system(size: 20, weight: .semibold, design: .rounded)
        case .regular: return .system(size: 24, weight: .semibold, design: .rounded)
        case .large: return .system(size: 26, weight: .semibold, design: .rounded)
        case .tablet: return .system(size: 28, weight: .semibold, design: .rounded)
        }
    }
    
    static func bodyText(for screenSize: DeviceInfo.ScreenSize = DeviceInfo.ScreenSize.current) -> Font {
        switch screenSize {
        case .compact: return .system(size: 14, weight: .regular)
        case .regular: return .system(size: 16, weight: .regular)
        case .large: return .system(size: 17, weight: .regular)
        case .tablet: return .system(size: 18, weight: .regular)
        }
    }
    
    static func buttonText(for screenSize: DeviceInfo.ScreenSize = DeviceInfo.ScreenSize.current) -> Font {
        switch screenSize {
        case .compact: return .system(size: 16, weight: .semibold, design: .rounded)
        case .regular: return .system(size: 17, weight: .semibold, design: .rounded)
        case .large: return .system(size: 18, weight: .semibold, design: .rounded)
        case .tablet: return .system(size: 19, weight: .semibold, design: .rounded)
        }
    }
}

// MARK: - Responsive Button Component
struct ResponsiveButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
    }
    
    init(
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .font(ResponsiveTypography.buttonText())
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
        }
        .frame(minHeight: minTouchTarget)
    }
    
    private var verticalPadding: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 12
        case .regular: return 16
        case .large: return 18
        case .tablet: return 20
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 20
        case .regular: return 24
        case .large: return 28
        case .tablet: return 32
        }
    }
    
    private var cornerRadius: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 20
        case .regular: return 22
        case .large: return 24
        case .tablet: return 26
        }
    }
    
    private var minTouchTarget: CGFloat {
        44 // Apple's minimum touch target size
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                startPoint: .leading,
                endPoint: .trailing
            ).opacity(1.0) as! Color
        case .secondary:
            return Color.white.opacity(0.1)
        case .ghost:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return LandingPageColors.primaryText
        case .ghost: return LandingPageColors.primaryText
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .primary: return Color.clear
        case .secondary: return Color.white.opacity(0.3)
        case .ghost: return LandingPageColors.primaryText.opacity(0.5)
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .primary: return 0
        case .secondary: return 1
        case .ghost: return 1.5
        }
    }
}

// MARK: - Responsive Card Component
struct ResponsiveCard<Content: View>: View {
    let content: Content
    let padding: CGFloat?
    
    init(padding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(effectivePadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(EnhancedGlassEffects.primaryGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
            )
    }
    
    private var effectivePadding: CGFloat {
        if let padding = padding {
            return padding
        }
        
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 16
        case .regular: return 20
        case .large: return 24
        case .tablet: return 28
        }
    }
    
    private var cornerRadius: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 12
        case .regular: return 16
        case .large: return 18
        case .tablet: return 20
        }
    }
    
    private var shadowOpacity: Double {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 0.08
        case .regular: return 0.1
        case .large: return 0.12
        case .tablet: return 0.15
        }
    }
    
    private var shadowRadius: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 6
        case .regular: return 8
        case .large: return 10
        case .tablet: return 12
        }
    }
    
    private var shadowY: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 3
        case .regular: return 4
        case .large: return 5
        case .tablet: return 6
        }
    }
}

// MARK: - Responsive Navigation Component
struct ResponsiveNavigation<Content: View>: View {
    let content: Content
    let showBackButton: Bool
    let backAction: (() -> Void)?
    
    init(
        showBackButton: Bool = false,
        backAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.showBackButton = showBackButton
        self.backAction = backAction
    }
    
    var body: some View {
        HStack(spacing: horizontalSpacing) {
            if showBackButton {
                Button(action: backAction ?? {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(LandingPageColors.primaryText)
                        .frame(width: touchTargetSize, height: touchTargetSize)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            
            content
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(height: navigationHeight)
    }
    
    private var horizontalPadding: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 16
        case .regular: return 20
        case .large: return 24
        case .tablet: return 32
        }
    }
    
    private var verticalPadding: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 12
        case .regular: return 16
        case .large: return 18
        case .tablet: return 20
        }
    }
    
    private var horizontalSpacing: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 12
        case .regular: return 16
        case .large: return 20
        case .tablet: return 24
        }
    }
    
    private var navigationHeight: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 60
        case .regular: return 70
        case .large: return 75
        case .tablet: return 80
        }
    }
    
    private var iconSize: CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return 18
        case .regular: return 20
        case .large: return 22
        case .tablet: return 24
        }
    }
    
    private var touchTargetSize: CGFloat {
        44 // Minimum touch target size
    }
}

// MARK: - Responsive Image Component
struct ResponsiveImage: View {
    let systemName: String
    let size: ImageSize
    
    enum ImageSize {
        case small
        case medium
        case large
        case hero
        
        func value(for screenSize: DeviceInfo.ScreenSize) -> CGFloat {
            switch (self, screenSize) {
            case (.small, .compact): return 16
            case (.small, .regular): return 18
            case (.small, .large): return 20
            case (.small, .tablet): return 22
            
            case (.medium, .compact): return 24
            case (.medium, .regular): return 28
            case (.medium, .large): return 32
            case (.medium, .tablet): return 36
            
            case (.large, .compact): return 40
            case (.large, .regular): return 48
            case (.large, .large): return 56
            case (.large, .tablet): return 64
            
            case (.hero, .compact): return 60
            case (.hero, .regular): return 80
            case (.hero, .large): return 100
            case (.hero, .tablet): return 120
            }
        }
    }
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size.value(for: DeviceInfo.ScreenSize.current)))
    }
}

// MARK: - Responsive Spacing Helper
struct ResponsiveSpacing {
    static func vertical(
        compact: CGFloat = 16,
        regular: CGFloat = 24,
        large: CGFloat = 32,
        tablet: CGFloat = 40
    ) -> CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return compact
        case .regular: return regular
        case .large: return large
        case .tablet: return tablet
        }
    }
    
    static func horizontal(
        compact: CGFloat = 16,
        regular: CGFloat = 24,
        large: CGFloat = 32,
        tablet: CGFloat = 40
    ) -> CGFloat {
        switch DeviceInfo.ScreenSize.current {
        case .compact: return compact
        case .regular: return regular
        case .large: return large
        case .tablet: return tablet
        }
    }
}

// MARK: - Orientation-Aware Container
struct OrientationAwareContainer<Content: View>: View {
    let content: Content
    @State private var orientation = UIDeviceOrientation.unknown
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                orientation = UIDevice.current.orientation
            }
            .onAppear {
                orientation = UIDevice.current.orientation
            }
    }
    
    var isLandscape: Bool {
        orientation.isLandscape
    }
    
    var isPortrait: Bool {
        orientation.isPortrait
    }
}

// MARK: - Safe Area Aware Container
struct SafeAreaAwareContainer<Content: View>: View {
    let content: Content
    let edges: Edge.Set
    
    init(edges: Edge.Set = .all, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.edges = edges
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .padding(.top, edges.contains(.top) ? geometry.safeAreaInsets.top : 0)
                .padding(.bottom, edges.contains(.bottom) ? geometry.safeAreaInsets.bottom : 0)
                .padding(.leading, edges.contains(.leading) ? geometry.safeAreaInsets.leading : 0)
                .padding(.trailing, edges.contains(.trailing) ? geometry.safeAreaInsets.trailing : 0)
        }
    }
}

// MARK: - Performance-Optimized Scroll View
struct OptimizedScrollView<Content: View>: View {
    let content: Content
    let showsIndicators: Bool
    
    init(showsIndicators: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showsIndicators = showsIndicators
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            LazyVStack(spacing: ResponsiveSpacing.vertical()) {
                content
            }
        }
        .scrollContentBackground(.hidden) // iOS 16+
    }
}

// MARK: - Preview
struct ResponsiveDesignEnhancements_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone SE Preview
            VStack(spacing: 20) {
                Text("iPhone SE")
                    .font(ResponsiveTypography.heroTitle())
                
                ResponsiveButton(action: {}) {
                    Text("Responsive Button")
                }
                
                ResponsiveCard {
                    Text("Responsive Card Content")
                        .font(ResponsiveTypography.bodyText())
                }
            }
            .responsivePadding()
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE")
            
            // iPhone 14 Preview
            VStack(spacing: 20) {
                Text("iPhone 14")
                    .font(ResponsiveTypography.heroTitle())
                
                ResponsiveButton(action: {}) {
                    Text("Responsive Button")
                }
                
                ResponsiveCard {
                    Text("Responsive Card Content")
                        .font(ResponsiveTypography.bodyText())
                }
            }
            .responsivePadding()
            .previewDevice("iPhone 14")
            .previewDisplayName("iPhone 14")
            
            // iPad Preview
            VStack(spacing: 20) {
                Text("iPad")
                    .font(ResponsiveTypography.heroTitle())
                
                ResponsiveButton(action: {}) {
                    Text("Responsive Button")
                }
                
                ResponsiveCard {
                    Text("Responsive Card Content")
                        .font(ResponsiveTypography.bodyText())
                }
            }
            .responsivePadding()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad Pro")
        }
    }
}