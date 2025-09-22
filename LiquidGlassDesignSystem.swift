import SwiftUI

// Glass Field Modifier for consistent text field styling
struct GlassFieldModifier: ViewModifier {
    var isValid: Bool = true

    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.white.opacity(0.2) : Color.red.opacity(0.6), lineWidth: 0.5)
            )
    }
}

// Glass Date Picker component
struct GlassDatePicker: View {
    let title: String
    @Binding var date: Date
    let isMandatory: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.white.opacity(0.8))
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
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .accentColor(Color.white)
        }
    }
}

// Glass Segmented Picker component
struct GlassSegmentedPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayText: (T) -> String
    let isMandatory: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.white.opacity(0.8))
                if isMandatory {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
            }

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayText(option))
                        .foregroundColor(Color.white)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
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
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .blur(radius: 1)
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))

            content
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}