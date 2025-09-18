import SwiftUI

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    @State private var animateTab = false

    private let tabItems = [
        TabItem(icon: "books.vertical.fill", title: "Library", color: LiquidGlass.primary),
        TabItem(icon: "book.fill", title: "Reading", color: LiquidGlass.secondary),
        TabItem(icon: "sparkles", title: "Discover", color: LiquidGlass.accent),
        TabItem(icon: "person.fill", title: "Profile", color: LiquidGlass.success)
    ]

    var body: some View {
        ZStack {
            // Background blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
                .blur(radius: 20)
                .ignoresSafeArea()

            // Tab bar content
            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    tabButton(for: index)
                }
            }
            .padding(.horizontal, LiquidGlass.Spacing.space8)
            .padding(.vertical, LiquidGlass.Spacing.space12)
            .padding(.bottom, LiquidGlass.Spacing.space8)
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
                .overlay(
                    RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, LiquidGlass.Spacing.space16)
        .padding(.bottom, LiquidGlass.Spacing.space8)
        .onAppear {
            withAnimation(LiquidGlass.Animation.spring) {
                animateTab = true
            }
        }
    }

    private func tabButton(for index: Int) -> some View {
        let item = tabItems[index]
        let isSelected = selectedTab == index

        return Button(action: {
            withAnimation(LiquidGlass.Animation.spring) {
                selectedTab = index
            }
        }) {
            VStack(spacing: LiquidGlass.Spacing.space4) {
                ZStack {
                    // Background circle for selected state
                    if isSelected {
                        Circle()
                            .fill(item.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .blur(radius: 8)
                            .scaleEffect(animateTab ? 1 : 0.8)
                            .animation(LiquidGlass.Animation.spring, value: animateTab)
                    }

                    // Icon with glow effect when selected
                    Image(systemName: item.icon)
                        .font(.system(size: isSelected ? 24 : 20, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .shadow(color: isSelected ? item.color.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 0)
                        .animation(LiquidGlass.Animation.spring, value: isSelected)
                }
                .frame(width: 50, height: 50)

                // Title
                Text(item.title)
                    .font(LiquidGlass.Typography.captionSmall)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .opacity(animateTab ? 1 : 0)
                    .animation(LiquidGlass.Animation.spring.delay(0.1), value: animateTab)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidTabButtonStyle())
    }
}

struct TabItem {
    let icon: String
    let title: String
    let color: Color
}

struct LiquidTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(LiquidGlass.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Liquid Glass Tab Bar with Indicator

struct LiquidGlassTabBarWithIndicator: View {
    @Binding var selectedTab: Int
    @State private var indicatorOffset: CGFloat = 0

    private let tabItems = [
        TabItem(icon: "books.vertical.fill", title: "Library", color: LiquidGlass.primary),
        TabItem(icon: "book.fill", title: "Reading", color: LiquidGlass.secondary),
        TabItem(icon: "sparkles", title: "Discover", color: LiquidGlass.accent),
        TabItem(icon: "person.fill", title: "Profile", color: LiquidGlass.success)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)
                    .overlay(
                        RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.large)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)

                // Liquid indicator
                RoundedRectangle(cornerRadius: LiquidGlass.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [tabItems[selectedTab].color.opacity(0.3), tabItems[selectedTab].color.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width / CGFloat(tabItems.count) - LiquidGlass.Spacing.space16,
                           height: 4)
                    .offset(x: indicatorOffset)
                    .animation(LiquidGlass.Animation.spring, value: selectedTab)

                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(0..<tabItems.count, id: \.self) { index in
                        tabButton(for: index, in: geometry)
                    }
                }
            }
        }
        .frame(height: 80)
        .padding(.horizontal, LiquidGlass.Spacing.space16)
        .padding(.bottom, LiquidGlass.Spacing.space8)
        .onAppear {
            updateIndicatorOffset()
        }
        .onChange(of: selectedTab) { _ in
            updateIndicatorOffset()
        }
    }

    private func tabButton(for index: Int, in geometry: GeometryProxy) -> some View {
        let item = tabItems[index]
        let isSelected = selectedTab == index
        let tabWidth = geometry.size.width / CGFloat(tabItems.count)

        return Button(action: {
            withAnimation(LiquidGlass.Animation.spring) {
                selectedTab = index
            }
        }) {
            VStack(spacing: LiquidGlass.Spacing.space4) {
                Image(systemName: item.icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .shadow(color: isSelected ? item.color.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 0)
                    .animation(LiquidGlass.Animation.spring, value: isSelected)

                Text(item.title)
                    .font(LiquidGlass.Typography.captionSmall)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(width: tabWidth, height: 60)
        }
        .buttonStyle(LiquidTabButtonStyle())
    }

    private func updateIndicatorOffset() {
        let tabWidth = UIScreen.main.bounds.width / CGFloat(tabItems.count)
        indicatorOffset = (tabWidth * CGFloat(selectedTab)) - (UIScreen.main.bounds.width / 2) + (tabWidth / 2)
    }
}