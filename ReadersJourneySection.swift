import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            // Calculate responsive dimensions based on screen width
            let cardDimensions = calculateCardDimensions(for: screenWidth)
            let textScale = calculateTextScale(for: screenWidth)
            let spacing = calculateSpacing(for: screenWidth)
            let horizontalPadding = calculateHorizontalPadding(for: screenWidth)
            
            VStack(spacing: spacing.section) {
                Text("Alex's Reading Journey")
                    .font(TypographySystem.headlineMedium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, spacing.top)
                    .scaleEffect(textScale.title)

                Text("Meet Alex, a college student overwhelmed by her growing physical bookshelf. Discover how traditional reading struggles led her to Book Shelfie, and how our app transformed her entire reading experience.")
                    .font(TypographySystem.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, spacing.text)
                    .scaleEffect(textScale.body)

                // Progress indicator showing transformation
                TransformationProgressIndicator(screenWidth: screenWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, spacing.vertical)
                    .padding(.top, spacing.text)

                FlipCard(cardWidth: cardDimensions.width, cardHeight: cardDimensions.height, textScale: textScale)
                    .padding(.horizontal, horizontalPadding)
            }
            .padding(.top, spacing.top)
        }
    }
    
    // Calculate card dimensions based on screen width
    private func calculateCardDimensions(for width: CGFloat) -> (width: CGFloat, height: CGFloat) {
        switch width {
        case ..<375: // iPhone SE, small devices
            return (300, 340)
        case 375..<430: // iPhone 13/14/15 standard
            return (340, 380)
        default: // iPhone Pro Max, iPad, larger devices
            return (min(400, width - 40), 450)
        }
    }
    
    // Calculate text scale based on screen width
    private func calculateTextScale(for width: CGFloat) -> (title: CGFloat, body: CGFloat) {
        switch width {
        case ..<375: // Small devices
            return (0.9, 0.9)
        case 375..<430: // Standard devices
            return (1.0, 1.0)
        default: // Large devices
            return (1.1, 1.05)
        }
    }
    
    // Calculate spacing based on screen width
    private func calculateSpacing(for width: CGFloat) -> (section: CGFloat, text: CGFloat, vertical: CGFloat, top: CGFloat) {
        switch width {
        case ..<375: // Small devices
            return (16, 12, 8, 30)
        case 375..<430: // Standard devices
            return (24, 20, 12, 50)
        default: // Large devices
            return (32, 24, 16, 60)
        }
    }
    
    // Calculate horizontal padding based on screen width
    private func calculateHorizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<375: // Small devices
            return 16
        case 375..<430: // Standard devices
            return 24
        default: // Large devices
            return max(32, (width - 400) / 2)
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
    let textScale: (title: CGFloat, body: CGFloat)

    var body: some View {
        let iconSize: CGFloat = 20 * textScale.body
        let frameSize: CGFloat = 32 * textScale.body
        let padding = AppleBooksSpacing.space16 * textScale.body
        let spacing = AppleBooksSpacing.space12 * textScale.body
        let bulletSpacing = AppleBooksSpacing.space8 * textScale.body
        let headerSpacing = AppleBooksSpacing.space8 * textScale.body
        let bulletIconSize: CGFloat = 14 * textScale.body
        let bulletFrameSize: CGFloat = 16 * textScale.body
        let bulletHSpacing = AppleBooksSpacing.space8 * textScale.body
        let lineSpacing: CGFloat = 2 * textScale.body

        VStack(alignment: .leading, spacing: spacing) {
            // Header
            HStack(spacing: headerSpacing) {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(cardType.iconColor)
                    .frame(width: frameSize, height: frameSize)
                    .background(cardType.accentColor.opacity(0.1))
                    .cornerRadius(8 * textScale.body)

                Text(title)
                    .font(TypographySystem.headlineMedium)
                    .foregroundColor(.black)
                    .scaleEffect(textScale.title)
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
                            .scaleEffect(textScale.body)
                    }
                }
            }
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: 16 * textScale.body)
                .fill(cardType.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16 * textScale.body)
                        .stroke(cardType.accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: cardType.accentColor.opacity(0.2), radius: 8 * textScale.body, x: 0, y: 4 * textScale.body)
        )
    }
}

struct TransformationProgressIndicator: View {
    let screenWidth: CGFloat
    
    var body: some View {
        // Calculate responsive dimensions
        let scale: CGFloat = {
            switch screenWidth {
            case ..<375: return 0.85
            case 375..<430: return 1.0
            default: return 1.15
            }
        }()
        
        let width: CGFloat = 240 * scale
        let height: CGFloat = 60 * scale
        let barHeight: CGFloat = 6 * scale
        let spacing = AppleBooksSpacing.space6 * scale
        let hSpacing = AppleBooksSpacing.space48 * scale

        VStack(spacing: spacing) {
            Text("Transformation Progress")
                .font(AppleBooksTypography.captionBold)
                .foregroundColor(AppleBooksColors.textSecondary)
                .scaleEffect(scale)

            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 4 * scale)
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
                    .scaleEffect(scale)
                Text("Success")
                    .font(AppleBooksTypography.caption)
                    .foregroundColor(Color(hex: "4A90E2"))
                    .scaleEffect(scale)
            }
        }
        .frame(height: height)
    }
}
struct FlipCard: View {
    @State private var flipped = false
    @State private var isPressed = false
    @State private var timer: Timer?
    
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let textScale: (title: CGFloat, body: CGFloat)

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
                    bulletPoints: strugglesBulletPoints,
                    textScale: textScale
                )
            }
            
            // Back card - Enhanced Reading Experience (green)
            if flipped {
                EnhancedJourneyCard(
                    icon: "sparkles",
                    title: "Enhanced Reading Experience",
                    cardType: .enhancements,
                    bulletPoints: enhancementsBulletPoints,
                    textScale: textScale
                )
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(width: cardWidth, height: cardHeight)
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