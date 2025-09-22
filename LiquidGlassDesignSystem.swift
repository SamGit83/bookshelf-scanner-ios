import SwiftUI

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

// Glass Date Picker component
struct GlassDatePicker: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var date: Date
    let isMandatory: Bool = false

    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.white.opacity(0.8)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.1)
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color.white.opacity(0.2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
                if isMandatory {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
            }

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding()
                .background(backgroundColor)
                .cornerRadius(8)
                .foregroundColor(textColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(strokeColor, lineWidth: 0.5)
                )
                .accentColor(textColor)
        }
    }
}

// Glass Segmented Picker component
struct GlassSegmentedPicker<T: Hashable>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayText: (T) -> String
    let isMandatory: Bool = false

    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.white.opacity(0.8)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.1)
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color.white.opacity(0.2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
                if isMandatory {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
            }

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayText(option))
                        .foregroundColor(textColor)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(textColor)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 0.5)
            )
        }
    }
}

// Translucent Overlay for showing additional fields
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
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)

                content
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isVisible)
    }
}
// Animated Background for dynamic visual effects
struct AnimatedBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Dynamic Gradient Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.pink.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle animated overlay
            GeometryReader { geometry in
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .blur(radius: 40)
                    .offset(x: animate ? 20 : -20)
                    .animation(.easeInOut(duration: 4).repeatForever(), value: animate)

                Circle()
                    .fill(Color.pink.opacity(0.1))
                    .frame(width: geometry.size.width * 0.6)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
                    .blur(radius: 30)
                    .offset(y: animate ? -15 : 15)
                    .animation(.easeInOut(duration: 3).repeatForever(), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// Glass Card component for consistent card styling
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var glassColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.1)
    }

    private var glassStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color.white.opacity(0.2)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(glassColor)
                .blur(radius: 1)
            RoundedRectangle(cornerRadius: 20)
                .fill(glassColor.opacity(0.5))

            content
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(glassStrokeColor, lineWidth: 0.5)
        )
    }
}
extension View {
    @ViewBuilder
    func glassFieldStyle(isValid: Bool = true) -> some View {
        GlassFieldStyleModifier(isValid: isValid)
            .modifier(self)
    }
}

struct GlassFieldStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let isValid: Bool

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.1)
    }

    private var strokeColor: Color {
        if !isValid {
            return Color.red.opacity(0.6)
        }
        return colorScheme == .dark ? Color.white.opacity(0.3) : Color.white.opacity(0.2)
    }

    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 0.5)
            )
    }
}