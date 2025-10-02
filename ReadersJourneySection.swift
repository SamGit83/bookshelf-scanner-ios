import SwiftUI

struct ReadersJourneySection: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        let isCompact = sizeClass == .compact
        let titleFont = isCompact ? AppleBooksTypography.headlineMedium : AppleBooksTypography.headlineLarge
        let bodyFont = isCompact ? AppleBooksTypography.bodyMedium : AppleBooksTypography.bodyLarge
        let spacing = isCompact ? AppleBooksSpacing.space24 : AppleBooksSpacing.space32
        let horizontalPadding = isCompact ? AppleBooksSpacing.space24 : AppleBooksSpacing.space32
        let cardSpacing = isCompact ? AppleBooksSpacing.space16 : AppleBooksSpacing.space20
        let verticalPadding = isCompact ? AppleBooksSpacing.space12 : AppleBooksSpacing.space16

        VStack(spacing: spacing) {
            Text("Alex's Reading Journey")
                .font(titleFont)
                .foregroundColor(.primary)
                .padding(.horizontal, horizontalPadding)

            Text("Meet Alex, a college student overwhelmed by her growing physical bookshelf. Discover how traditional reading struggles led her to Book Shelfie, and how our app transformed her entire reading experience.")
                .font(bodyFont)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, horizontalPadding)

            // Progress indicator showing transformation
            TransformationProgressIndicator()
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)

            VStack(spacing: cardSpacing) {
                EnhancedJourneyCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Traditional Reading Struggles",
                    cardType: .struggles,
                    bulletPoints: [
                        BulletPoint(icon: "clock.fill", text: "Countless hours manually cataloging books"),
                        BulletPoint(icon: "square.stack.3d.up.slash", text: "Disorganized shelves and lost books"),
                        BulletPoint(icon: "magnifyingglass", text: "Wasting time searching for titles"),
                        BulletPoint(icon: "chart.bar.xaxis", text: "No progress tracking capabilities"),
                        BulletPoint(icon: "lightbulb.slash", text: "Difficulty discovering new books")
                    ]
                )

                EnhancedJourneyCard(
                    icon: "sparkles",
                    title: "Enhanced Reading Experience",
                    cardType: .enhancements,
                    bulletPoints: [
                        BulletPoint(icon: "camera.viewfinder", text: "Instant AI-powered bookshelf scanning"),
                        BulletPoint(icon: "folder.fill", text: "Digital organization of entire collection"),
                        BulletPoint(icon: "chart.line.uptrend.xyaxis", text: "Effortless reading progress tracking"),
                        BulletPoint(icon: "star.fill", text: "Personalized book recommendations"),
                        BulletPoint(icon: "heart.fill", text: "Pure reading enjoyment and discovery")
                    ]
                )
            }
            .padding(.horizontal, horizontalPadding)
        }
    }
}

enum CardType {
    case struggles
    case enhancements

    var backgroundColor: Color {
        switch self {
        case .struggles:
            return Color(hex: "FFF3F0") // Light orange/red background
        case .enhancements:
            return Color(hex: "F0FFF0") // Light green background
        }
    }

    var accentColor: Color {
        switch self {
        case .struggles:
            return Color(hex: "FF6B35") // Orange/red accent
        case .enhancements:
            return Color(hex: "30D158") // Green accent
        }
    }

    var iconColor: Color {
        accentColor
    }
}

struct BulletPoint {
    let icon: String
    let text: String
}

struct EnhancedJourneyCard: View {
    let icon: String
    let title: String
    let cardType: CardType
    let bulletPoints: [BulletPoint]

    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        let isCompact = sizeClass == .compact
        let headerFont = isCompact ? AppleBooksTypography.headlineSmall : AppleBooksTypography.headlineMedium
        let bulletFont = isCompact ? AppleBooksTypography.bodySmall : AppleBooksTypography.bodyMedium
        let iconSize: CGFloat = isCompact ? 20 : 24
        let frameSize: CGFloat = isCompact ? 32 : 40
        let padding = isCompact ? AppleBooksSpacing.space16 : AppleBooksSpacing.space20
        let spacing = isCompact ? AppleBooksSpacing.space12 : AppleBooksSpacing.space16
        let bulletSpacing = isCompact ? AppleBooksSpacing.space8 : AppleBooksSpacing.space12
        let headerSpacing = isCompact ? AppleBooksSpacing.space8 : AppleBooksSpacing.space12
        let bulletIconSize: CGFloat = isCompact ? 14 : 16
        let bulletFrameSize: CGFloat = isCompact ? 16 : 20
        let bulletHSpacing = isCompact ? AppleBooksSpacing.space8 : AppleBooksSpacing.space12
        let lineSpacing: CGFloat = isCompact ? 2 : 4

        VStack(alignment: .leading, spacing: spacing) {
            // Header
            HStack(spacing: headerSpacing) {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(cardType.iconColor)
                    .frame(width: frameSize, height: frameSize)
                    .background(cardType.accentColor.opacity(0.1))
                    .cornerRadius(8)

                Text(title)
                    .font(headerFont)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Bullet points
            VStack(alignment: .leading, spacing: bulletSpacing) {
                ForEach(bulletPoints.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: bulletHSpacing) {
                        Image(systemName: bulletPoints[index].icon)
                            .font(.system(size: bulletIconSize))
                            .foregroundColor(cardType.accentColor)
                            .frame(width: bulletFrameSize, height: bulletFrameSize)

                        Text(bulletPoints[index].text)
                            .font(bulletFont)
                            .foregroundColor(.black)
                            .lineSpacing(lineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardType.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardType.accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: cardType.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity)
    }
}

struct TransformationProgressIndicator: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        let isCompact = sizeClass == .compact
        let width: CGFloat = isCompact ? 240 : 280
        let height: CGFloat = isCompact ? 60 : 80
        let barHeight: CGFloat = isCompact ? 6 : 8
        let spacing = isCompact ? AppleBooksSpacing.space6 : AppleBooksSpacing.space8
        let hSpacing = isCompact ? AppleBooksSpacing.space60 : AppleBooksSpacing.space80

        VStack(spacing: spacing) {
            Text("Transformation Progress")
                .font(AppleBooksTypography.captionBold)
                .foregroundColor(AppleBooksColors.textSecondary)

            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "4A90E2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width, height: barHeight)
            }
            .frame(width: width)

            HStack(spacing: hSpacing) {
                Text("Struggles")
                    .font(AppleBooksTypography.caption)
                    .foregroundColor(Color(hex: "FF6B35"))
                Text("Success")
                    .font(AppleBooksTypography.caption)
                    .foregroundColor(Color(hex: "4A90E2"))
            }
        }
        .frame(height: height)
    }
}

struct ReadersJourneySection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppleBooksColors.background
                .ignoresSafeArea()
            ReadersJourneySection()
        }
    }
}