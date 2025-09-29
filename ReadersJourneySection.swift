import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        VStack(spacing: AppleBooksSpacing.space32) {
            Text("Alex's Reading Journey")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(.horizontal, AppleBooksSpacing.space32)

            Text("Meet Alex, a college student overwhelmed by her growing physical bookshelf. Discover how traditional reading struggles led her to Bookshelf Scanner, and how our app transformed her entire reading experience.")
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, AppleBooksSpacing.space32)

            // Progress indicator showing transformation
            TransformationProgressIndicator()
                .padding(.horizontal, AppleBooksSpacing.space32)
                .padding(.vertical, AppleBooksSpacing.space16)

            VStack(spacing: AppleBooksSpacing.space20) {
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
            .padding(.horizontal, AppleBooksSpacing.space32)
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

    var body: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
            // Header
            HStack(spacing: AppleBooksSpacing.space12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(cardType.iconColor)
                    .frame(width: 40, height: 40)
                    .background(cardType.accentColor.opacity(0.1))
                    .cornerRadius(8)

                Text(title)
                    .font(AppleBooksTypography.headlineMedium)
                    .foregroundColor(AppleBooksColors.text)
            }

            // Bullet points
            VStack(alignment: .leading, spacing: AppleBooksSpacing.space12) {
                ForEach(bulletPoints.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: AppleBooksSpacing.space12) {
                        Image(systemName: bulletPoints[index].icon)
                            .font(.system(size: 16))
                            .foregroundColor(cardType.accentColor)
                            .frame(width: 20, height: 20)

                        Text(bulletPoints[index].text)
                            .font(AppleBooksTypography.bodyMedium)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .lineSpacing(4)
                    }
                }
            }
        }
        .padding(AppleBooksSpacing.space20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardType.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardType.accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: cardType.accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity)
    }
}

struct TransformationProgressIndicator: View {
    var body: some View {
        VStack(spacing: AppleBooksSpacing.space8) {
            Text("Transformation Progress")
                .font(AppleBooksTypography.captionBold)
                .foregroundColor(AppleBooksColors.textSecondary)

            ZStack {
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "4A90E2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 280, height: 8) // Full width

                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 196) // Position at 70% of 280
            }
            .frame(width: 280)

            HStack(spacing: AppleBooksSpacing.space80) {
                Text("Struggles")
                    .font(AppleBooksTypography.caption)
                    .foregroundColor(Color(hex: "FF6B35"))
                Text("Success")
                    .font(AppleBooksTypography.caption)
                    .foregroundColor(Color(hex: "4A90E2"))
            }
        }
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