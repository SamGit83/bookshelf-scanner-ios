import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        let titleFont = TypographySystem.headlineMedium
        let bodyFont = TypographySystem.bodyMedium
        let spacing = AppleBooksSpacing.space24
        let horizontalPadding = AppleBooksSpacing.space24
        let cardSpacing = AppleBooksSpacing.space16
        let verticalPadding = AppleBooksSpacing.space12

        VStack(spacing: spacing) {
            Text("Alex's Reading Journey")
                .font(titleFont)
                .foregroundColor(.primary)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 20)

            Text("Meet Alex, a college student overwhelmed by her growing physical bookshelf. Discover how traditional reading struggles led her to Book Shelfie, and how our app transformed her entire reading experience.")
                .font(bodyFont)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 20)

            // Progress indicator showing transformation
            TransformationProgressIndicator()
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .padding(.top, 20)

            FlipCard()
                .padding(.horizontal, horizontalPadding)
        }
        .padding(.top, 50)
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
        let headerFont = AppleBooksTypography.headlineSmall
        let bulletFont = AppleBooksTypography.bodySmall
        let iconSize: CGFloat = 20
        let frameSize: CGFloat = 32
        let padding = AppleBooksSpacing.space16
        let spacing = AppleBooksSpacing.space12
        let bulletSpacing = AppleBooksSpacing.space8
        let headerSpacing = AppleBooksSpacing.space8
        let bulletIconSize: CGFloat = 14
        let bulletFrameSize: CGFloat = 16
        let bulletHSpacing = AppleBooksSpacing.space8
        let lineSpacing: CGFloat = 2

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
                    .font(TypographySystem.headlineMedium)
                    .foregroundColor(.black)
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
                            .font(TypographySystem.bodyMedium)
                            .foregroundColor(.black)
                            .lineSpacing(lineSpacing)
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
    }
}

struct TransformationProgressIndicator: View {
    var body: some View {
        let width: CGFloat = 240
        let height: CGFloat = 60
        let barHeight: CGFloat = 6
        let spacing = AppleBooksSpacing.space6
        let hSpacing = AppleBooksSpacing.space48

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
struct FlipCard: View {
    @State private var flipped = false
    @State private var isPressed = false
    @State private var timer: Timer?

    let strugglesBulletPoints = [
        BulletPoint(icon: "clock.fill", text: "Countless hours manually cataloging books"),
        BulletPoint(icon: "square.stack.3d.up.slash", text: "Disorganized shelves and lost books"),
        BulletPoint(icon: "magnifyingglass", text: "Wasting time searching for titles"),
        BulletPoint(icon: "chart.bar.xaxis", text: "No progress tracking capabilities"),
        BulletPoint(icon: "lightbulb.slash", text: "Difficulty discovering new books")
    ]

    let enhancementsBulletPoints = [
        BulletPoint(icon: "camera.viewfinder", text: "Instant AI-powered bookshelf scanning"),
        BulletPoint(icon: "folder.fill", text: "Digital organization of entire collection"),
        BulletPoint(icon: "chart.line.uptrend.xyaxis", text: "Effortless reading progress tracking"),
        BulletPoint(icon: "star.fill", text: "Personalized book recommendations"),
        BulletPoint(icon: "heart.fill", text: "Pure reading enjoyment and discovery")
    ]

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            if !isPressed {
                withAnimation(.easeInOut(duration: 0.6)) {
                    flipped.toggle()
                }
            }
        }
    }

    var body: some View {
        ZStack {
            // Front card - Traditional Reading Struggles (coral)
            if !flipped {
                EnhancedJourneyCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Traditional Reading Struggles",
                    cardType: .struggles,
                    bulletPoints: strugglesBulletPoints
                )
                .frame(width: 360, height: 400)
            }
            
            // Back card - Enhanced Reading Experience (green)
            if flipped {
                EnhancedJourneyCard(
                    icon: "sparkles",
                    title: "Enhanced Reading Experience",
                    cardType: .enhancements,
                    bulletPoints: enhancementsBulletPoints
                )
                .frame(width: 360, height: 400)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .clipped()
        .layoutPriority(1)
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    timer?.invalidate()
                }
                .onEnded { _ in
                    isPressed = false
                    startTimer()
                    withAnimation(.easeInOut(duration: 0.6)) {
                        flipped.toggle()
                    }
                }
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
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