import SwiftUI
import UIKit

// MARK: - Accessibility Enhancement Extensions
extension View {
    /// Adds comprehensive accessibility support to any view
    func enhancedAccessibility(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isButton: Bool = false,
        isHeader: Bool = false
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(isButton ? .isButton : (isHeader ? .isHeader : traits))
    }
    
    /// Adds focus ring for keyboard navigation
    func keyboardFocusable(
        isFocused: Bool = false,
        onFocusChange: @escaping (Bool) -> Void = { _ in }
    ) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? Color.blue : Color.clear,
                        lineWidth: 3
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
                // Handle VoiceOver state changes
            }
    }
    
    /// Adds high contrast support
    func highContrastAdaptive(
        normalColor: Color,
        highContrastColor: Color
    ) -> some View {
        self
            .foregroundColor(
                UIAccessibility.isDarkerSystemColorsEnabled ? highContrastColor : normalColor
            )
    }
    
    /// Adds reduced motion support
    func reducedMotionAdaptive<T: Equatable>(
        animation: Animation,
        value: T
    ) -> some View {
        self
            .animation(
                UIAccessibility.isReduceMotionEnabled ? .none : animation,
                value: value
            )
    }
}

// MARK: - Accessibility-Enhanced Components

/// Enhanced button with full accessibility support
struct AccessibleButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    let accessibilityLabel: String
    let accessibilityHint: String?
    
    @State private var isFocused = false
    @State private var isPressed = false
    
    init(
        action: @escaping () -> Void,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
    
    var body: some View {
        Button(action: action) {
            content
        }
        .enhancedAccessibility(
            label: accessibilityLabel,
            hint: accessibilityHint,
            isButton: true
        )
        .keyboardFocusable(isFocused: isFocused) { focused in
            isFocused = focused
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/// Enhanced text field with accessibility support
struct AccessibleTextField: View {
    @Binding var text: String
    let placeholder: String
    let accessibilityLabel: String
    let accessibilityHint: String?
    let isSecure: Bool
    
    @State private var isFocused = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        isSecure: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .focused($isTextFieldFocused)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isTextFieldFocused ? Color.blue : Color.white.opacity(0.3),
                            lineWidth: isTextFieldFocused ? 2 : 1
                        )
                )
        )
        .foregroundColor(LandingPageColors.primaryText)
        .enhancedAccessibility(
            label: accessibilityLabel,
            hint: accessibilityHint,
            value: text.isEmpty ? "Empty" : text
        )
        .onChange(of: isTextFieldFocused) { focused in
            isFocused = focused
        }
    }
}

/// Screen reader optimized section header
struct AccessibleSectionHeader: View {
    let title: String
    let subtitle: String?
    let level: Int // 1-6 for heading levels
    
    init(title: String, subtitle: String? = nil, level: Int = 1) {
        self.title = title
        self.subtitle = subtitle
        self.level = max(1, min(6, level)) // Clamp between 1-6
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(fontForLevel(level))
                .foregroundColor(LandingPageColors.primaryText)
                .enhancedAccessibility(
                    label: title,
                    isHeader: true
                )
                .accessibilityHeading(.h1) // Will be adjusted based on level
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(LandingPageTypography.sectionSubtitle)
                    .foregroundColor(LandingPageColors.secondaryText)
                    .enhancedAccessibility(
                        label: subtitle
                    )
            }
        }
    }
    
    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return LandingPageTypography.sectionTitle
        case 2: return LandingPageTypography.journeyTitle
        case 3: return LandingPageTypography.journeyBody
        default: return LandingPageTypography.journeyCaption
        }
    }
}

// MARK: - Accessibility Preferences Manager
class AccessibilityPreferencesManager: ObservableObject {
    @Published var isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    @Published var preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    
    init() {
        setupAccessibilityNotifications()
    }
    
    private func setupAccessibilityNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        }
    }
}

// MARK: - Accessibility-Enhanced Colors
struct AccessibleColors {
    static func adaptiveColor(
        normal: Color,
        highContrast: Color,
        darkMode: Color? = nil
    ) -> Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return highContrast
        }
        
        // Add dark mode support if provided
        if let darkMode = darkMode {
            return Color(UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(darkMode)
                default:
                    return UIColor(normal)
                }
            })
        }
        
        return normal
    }
    
    // High contrast color palette
    static let highContrastText = Color.white
    static let highContrastBackground = Color.black
    static let highContrastAccent = Color.yellow
    static let highContrastError = Color.red
    static let highContrastSuccess = Color.green
}

// MARK: - Accessibility-Enhanced Typography
struct AccessibleTypography {
    static func scaledFont(
        _ baseFont: Font,
        category: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    ) -> Font {
        let scaleFactor = scaleFactor(for: category)
        return baseFont // SwiftUI automatically scales fonts
    }
    
    private static func scaleFactor(for category: UIContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall: return 0.8
        case .small: return 0.85
        case .medium: return 0.9
        case .large: return 1.0
        case .extraLarge: return 1.15
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.5
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.9
        case .accessibilityExtraLarge: return 2.35
        case .accessibilityExtraExtraLarge: return 2.76
        case .accessibilityExtraExtraExtraLarge: return 3.12
        default: return 1.0
        }
    }
}

// MARK: - Accessibility Testing Helpers
struct AccessibilityTestingOverlay: View {
    @State private var showAccessibilityInfo = false
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    showAccessibilityInfo.toggle()
                }) {
                    Image(systemName: "accessibility")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityLabel("Toggle accessibility information")
            }
            .padding()
        }
        .sheet(isPresented: $showAccessibilityInfo) {
            AccessibilityInfoSheet()
        }
    }
}

struct AccessibilityInfoSheet: View {
    @StateObject private var accessibilityManager = AccessibilityPreferencesManager()
    
    var body: some View {
        NavigationView {
            List {
                Section("Accessibility Status") {
                    AccessibilityStatusRow(
                        title: "VoiceOver",
                        isEnabled: accessibilityManager.isVoiceOverEnabled
                    )
                    
                    AccessibilityStatusRow(
                        title: "Reduce Motion",
                        isEnabled: accessibilityManager.isReduceMotionEnabled
                    )
                    
                    AccessibilityStatusRow(
                        title: "Increase Contrast",
                        isEnabled: accessibilityManager.isDarkerSystemColorsEnabled
                    )
                    
                    AccessibilityStatusRow(
                        title: "Reduce Transparency",
                        isEnabled: accessibilityManager.isReduceTransparencyEnabled
                    )
                }
                
                Section("Text Size") {
                    Text("Current: \(accessibilityManager.preferredContentSizeCategory.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Accessibility Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AccessibilityStatusRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(isEnabled ? .green : .red)
        }
    }
}

// MARK: - Accessibility Announcement Helper
struct AccessibilityAnnouncement {
    static func announce(_ message: String, priority: UIAccessibility.NotificationPriority = .medium) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    static func announcePageChange(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: message)
        }
    }
    
    static func announceLayoutChange(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: message)
        }
    }
}

// MARK: - Accessibility-Enhanced Animations
struct AccessibleAnimations {
    static func spring(
        response: Double = 0.5,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
    }
    
    static func easeInOut(duration: Double) -> Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return .easeInOut(duration: duration)
    }
    
    static func linear(duration: Double) -> Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .none
        }
        return .linear(duration: duration)
    }
}

// MARK: - Preview
struct AccessibilityEnhancements_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AccessibleSectionHeader(
                title: "Accessibility Demo",
                subtitle: "Testing enhanced accessibility features",
                level: 1
            )
            
            AccessibleButton(
                action: { print("Accessible button tapped") },
                accessibilityLabel: "Demo button",
                accessibilityHint: "Tap to test accessibility features"
            ) {
                Text("Accessible Button")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            AccessibleTextField(
                text: .constant(""),
                placeholder: "Enter text",
                accessibilityLabel: "Demo text field",
                accessibilityHint: "Enter text to test accessibility"
            )
        }
        .padding()
        .overlay(AccessibilityTestingOverlay())
    }
}