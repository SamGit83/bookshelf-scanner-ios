import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let icon: AnyView
    let label: String
    let tag: Int
}

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]

    private func tabButtonContent(for tab: TabItem) -> some View {
        VStack(spacing: 4) {
            tab.icon
                .frame(width: 24, height: 24)
            Text(tab.label)
                .font(.caption2)
                .fontWeight(selectedTab == tab.tag ? .semibold : .regular)
        }
        .foregroundColor(selectedTab == tab.tag ? Color(hex: "FF9F0A") : Color(hex: "3C3C4399"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var tabBarContent: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = tab.tag
                    }
                }) {
                    tabButtonContent(for: tab)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var backgroundShape: some View {
        Color.white
            .overlay(
                Divider()
                    .padding(.top, 0),
                alignment: .top
            )
    }

    var body: some View {
        tabBarContent
            .background(backgroundShape)
            .padding(.top, 8)
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
