import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let icon: any View
    let label: String
    let tag: Int
}

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]

    private var tabBarContent: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = tab.tag
                    }
                }) {
                    VStack(spacing: 4) {
                        tab.icon
                            .frame(width: 24, height: 24)
                        Text(tab.label)
                            .font(.caption2)
                            .fontWeight(selectedTab == tab.tag ? .semibold : .regular)
                    }
                    .foregroundColor(selectedTab == tab.tag ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab.tag ? Color.blue.opacity(0.1) : Color.clear)
                            .padding(.horizontal, 8)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .opacity(0.8)
            .blur(radius: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    var body: some View {
        tabBarContent
            .background(backgroundShape)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}

struct ProfileInitialsView: View {
    let initials: String
    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        print("DEBUG ProfileInitialsView: initials = '\(initials)'")
        return ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            Text(initials)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textColor)
        }
    }
}
