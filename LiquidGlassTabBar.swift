import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let icon: AnyView
    let label: String
    let tag: Int
}

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    @ObservedObject private var accentColorManager = AccentColorManager.shared
    @ObservedObject private var authService = AuthService.shared

    private var userInitials: String {
        let displayName = authService.currentUser?.displayName
        let email = authService.currentUser?.email
        let name = displayName ?? email ?? "?"
        if name == "?" { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = components.first?.first?.uppercased() ?? ""
            let lastInitial = components.last?.first?.uppercased() ?? ""
            return firstInitial + lastInitial
        } else if let first = components.first?.first?.uppercased() {
            return first
        }
        return "?"
    }

    private var tabs: [TabItem] {
        return [
            TabItem(icon: AnyView(Image(systemName: "books.vertical")), label: "Library", tag: 0),
            TabItem(icon: AnyView(Image(systemName: "book.closed")), label: "Reading", tag: 1),
            TabItem(icon: AnyView(Image(systemName: "sparkles")), label: "Discover", tag: 2),
            TabItem(icon: AnyView(Image(systemName: "person.circle")), label: "Profile", tag: 3)
        ]
    }

    private func tabButtonContent(for tab: TabItem) -> some View {
        VStack(spacing: 4) {
            if tab.tag == 3 { // Profile tab
                ProfileInitialsView(
                    initials: userInitials,
                    isSelected: selectedTab == tab.tag
                )
                .frame(width: 24, height: 24)
            } else {
                tab.icon
                    .frame(width: 24, height: 24)
                    .foregroundColor(selectedTab == tab.tag ? AppleBooksColors.accent : AdaptiveColors.secondaryText)
            }

            Text(tab.label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(selectedTab == tab.tag ? AppleBooksColors.accent : AdaptiveColors.secondaryText)
        }
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
        AdaptiveColors.secondaryBackground
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
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        if isSelected {
            return AppleBooksColors.accent.opacity(0.2)
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return AppleBooksColors.accent.opacity(0.4)
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.4) : Color.gray.opacity(0.3)
        }
    }

    private var textColor: Color {
        if isSelected {
            return AppleBooksColors.accent
        } else {
            return AdaptiveColors.secondaryText
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1)
                )
            Text(initials)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(textColor)
                .frame(width: 20, alignment: .center)
        }
        .clipShape(Circle())
    }
}
