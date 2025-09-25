import SwiftUI

// MARK: - Enhanced Interactive Journey Section
struct EnhancedUserJourneySection: View {
    @State private var selectedPersona: ReadingPersona? = nil
    @State private var showSimulator = false
    @State private var simulatorStep = 0
    @State private var animateSection = false
    @State private var showResults = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Section Header
            VStack(spacing: 16) {
                Text("Discover Your Reading Journey")
                    .font(LandingPageTypography.sectionTitle)
                    .foregroundColor(LandingPageColors.primaryText)
                    .multilineTextAlignment(.center)
                    .offset(y: animateSection ? 0 : 30)
                    .opacity(animateSection ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateSection)
                
                Text("Choose your reading style and see how Bookshelf Scanner transforms your experience")
                    .font(LandingPageTypography.sectionSubtitle)
                    .foregroundColor(LandingPageColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .offset(y: animateSection ? 0 : 20)
                    .opacity(animateSection ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateSection)
            }
            
            if selectedPersona == nil {
                // Persona Selection
                PersonaSelectionView(selectedPersona: $selectedPersona)
                    .offset(y: animateSection ? 0 : 30)
                    .opacity(animateSection ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateSection)
            } else if !showResults {
                // Interactive Simulator
                InteractiveSimulatorView(
                    persona: selectedPersona!,
                    currentStep: $simulatorStep,
                    showResults: $showResults
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                // Personalized Results
                PersonalizedResultsView(persona: selectedPersona!)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            
            // Reset Button (when in simulator or results)
            if selectedPersona != nil {
                Button(action: resetJourney) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Try Different Style")
                    }
                    .font(LandingPageTypography.ctaMedium)
                    .foregroundColor(LandingPageColors.tertiaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LandingPageColors.tertiaryText.opacity(0.3), lineWidth: 1)
                    )
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.vertical, 64)
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateSection = true
            }
        }
    }
    
    private func resetJourney() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showResults = false
            simulatorStep = 0
            selectedPersona = nil
        }
    }
}

// MARK: - Reading Personas
enum ReadingPersona: String, CaseIterable, Identifiable {
    case weekendExplorer = "Weekend Explorer"
    case bookCollector = "Book Collector"
    case goalCrusher = "Goal Crusher"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .weekendExplorer: return "book.and.wrench"
        case .bookCollector: return "books.vertical.fill"
        case .goalCrusher: return "target"
        }
    }
    
    var description: String {
        switch self {
        case .weekendExplorer: return "I love discovering new books but often forget what I've read"
        case .bookCollector: return "I have hundreds of books but struggle to keep track of them all"
        case .goalCrusher: return "I set reading goals but need help staying motivated and organized"
        }
    }
    
    var color: Color {
        switch self {
        case .weekendExplorer: return Color(hex: "FF6B6B")
        case .bookCollector: return Color(hex: "4ECDC4")
        case .goalCrusher: return Color(hex: "45B7D1")
        }
    }
    
    var scenario: JourneyScenario {
        switch self {
        case .weekendExplorer:
            return JourneyScenario(
                title: "Weekend Discovery",
                steps: [
                    "Scan your weekend reading pile",
                    "Get instant book recognition",
                    "Discover similar books you'll love",
                    "Never forget what you've read"
                ],
                results: PersonalizedResults(
                    booksOrganized: 47,
                    timesSaved: "2 hours weekly",
                    recommendationsFound: 12,
                    achievementUnlocked: "Discovery Master"
                )
            )
        case .bookCollector:
            return JourneyScenario(
                title: "Library Organization",
                steps: [
                    "Scan your entire bookshelf",
                    "Watch books appear in digital library",
                    "Organize by genre, author, or custom tags",
                    "Find any book instantly with search"
                ],
                results: PersonalizedResults(
                    booksOrganized: 247,
                    timesSaved: "5 hours of cataloging",
                    recommendationsFound: 8,
                    achievementUnlocked: "Master Librarian"
                )
            )
        case .goalCrusher:
            return JourneyScenario(
                title: "Reading Challenge",
                steps: [
                    "Set your yearly reading goal",
                    "Track progress with every page",
                    "Get motivated with reading streaks",
                    "Celebrate achieving your target"
                ],
                results: PersonalizedResults(
                    booksOrganized: 24,
                    timesSaved: "30 minutes daily tracking",
                    recommendationsFound: 15,
                    achievementUnlocked: "Goal Crusher"
                )
            )
        }
    }
}

// MARK: - Journey Data Models
struct JourneyScenario {
    let title: String
    let steps: [String]
    let results: PersonalizedResults
}

struct PersonalizedResults {
    let booksOrganized: Int
    let timesSaved: String
    let recommendationsFound: Int
    let achievementUnlocked: String
}

// MARK: - Persona Selection View
struct PersonaSelectionView: View {
    @Binding var selectedPersona: ReadingPersona?
    @State private var hoveredPersona: ReadingPersona? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Which reader are you?")
                .font(LandingPageTypography.journeyTitle)
                .foregroundColor(LandingPageColors.primaryText)
            
            VStack(spacing: 16) {
                ForEach(ReadingPersona.allCases) { persona in
                    PersonaCard(
                        persona: persona,
                        isHovered: hoveredPersona == persona,
                        isSelected: selectedPersona == persona
                    ) {
                        selectPersona(persona)
                    }
                    .onHover { isHovering in
                        withAnimation(.easeOut(duration: 0.2)) {
                            hoveredPersona = isHovering ? persona : nil
                        }
                    }
                }
            }
        }
    }
    
    private func selectPersona(_ persona: ReadingPersona) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            selectedPersona = persona
        }
    }
}

// MARK: - Persona Card
struct PersonaCard: View {
    let persona: ReadingPersona
    let isHovered: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(persona.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: persona.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(persona.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.rawValue)
                        .font(LandingPageTypography.journeyTitle)
                        .foregroundColor(LandingPageColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(persona.description)
                        .font(LandingPageTypography.journeyBody)
                        .foregroundColor(LandingPageColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(persona.color)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: isHovered)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EnhancedGlassEffects.primaryGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isHovered ? persona.color.opacity(0.5) : Color.white.opacity(0.2),
                                lineWidth: isHovered ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isHovered ? persona.color.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isHovered ? 12 : 6,
                        x: 0,
                        y: isHovered ? 6 : 3
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Interactive Simulator View
struct InteractiveSimulatorView: View {
    let persona: ReadingPersona
    @Binding var currentStep: Int
    @Binding var showResults: Bool
    @State private var isScanning = false
    @State private var showPhoneContent = false
    
    var scenario: JourneyScenario {
        persona.scenario
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Scenario Title
            Text(scenario.title)
                .font(LandingPageTypography.sectionTitle)
                .foregroundColor(LandingPageColors.primaryText)
            
            // Phone Mockup with Interactive Content
            PhoneMockupView(
                persona: persona,
                currentStep: currentStep,
                isScanning: $isScanning,
                showContent: $showPhoneContent
            )
            
            // Step Progress
            StepProgressView(
                steps: scenario.steps,
                currentStep: currentStep,
                accentColor: persona.color
            )
            
            // Continue Button
            if currentStep < scenario.steps.count - 1 {
                Button(action: nextStep) {
                    HStack(spacing: 8) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(LandingPageTypography.ctaLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(persona.color)
                    )
                    .shadow(color: persona.color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentStep)
            } else {
                Button(action: showPersonalizedResults) {
                    HStack(spacing: 8) {
                        Text("See My Results")
                        Image(systemName: "sparkles")
                    }
                    .font(LandingPageTypography.ctaLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [persona.color, persona.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: persona.color.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .scaleEffect(1.05)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showResults)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                showPhoneContent = true
            }
        }
    }
    
    private func nextStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentStep == 0 {
                isScanning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentStep += 1
                        isScanning = false
                    }
                }
            } else {
                currentStep += 1
            }
        }
    }
    
    private func showPersonalizedResults() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showResults = true
        }
    }
}

// MARK: - Phone Mockup View
struct PhoneMockupView: View {
    let persona: ReadingPersona
    let currentStep: Int
    @Binding var isScanning: Bool
    @Binding var showContent: Bool
    
    var body: some View {
        ZStack {
            // Phone Frame
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black)
                .frame(width: 200, height: 400)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white)
                        .frame(width: 190, height: 390)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Screen Content
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black)
                .frame(width: 190, height: 390)
                .overlay(
                    Group {
                        if showContent {
                            screenContent
                        }
                    }
                )
                .clipped()
        }
        .scaleEffect(showContent ? 1.0 : 0.8)
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showContent)
    }
    
    @ViewBuilder
    private var screenContent: some View {
        switch currentStep {
        case 0:
            CameraScanView(isScanning: isScanning, accentColor: persona.color)
        case 1:
            BookRecognitionView(persona: persona)
        case 2:
            LibraryOrganizationView(persona: persona)
        case 3:
            ResultsCelebrationView(persona: persona)
        default:
            Color.clear
        }
    }
}

// MARK: - Screen Content Views
struct CameraScanView: View {
    let isScanning: Bool
    let accentColor: Color
    @State private var scanLinePosition: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Camera background
            Color.black
            
            // Bookshelf image placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Point camera at bookshelf")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
            
            // Scanning overlay
            if isScanning {
                Rectangle()
                    .fill(accentColor.opacity(0.3))
                    .frame(height: 4)
                    .offset(y: scanLinePosition)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                            scanLinePosition = 150
                        }
                    }
            }
            
            // Viewfinder corners
            VStack {
                HStack {
                    ViewfinderCorner()
                    Spacer()
                    ViewfinderCorner()
                        .rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    ViewfinderCorner()
                        .rotationEffect(.degrees(-90))
                    Spacer()
                    ViewfinderCorner()
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(40)
        }
    }
}

struct ViewfinderCorner: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.white, lineWidth: 2)
        .frame(width: 20, height: 20)
    }
}

struct BookRecognitionView: View {
    let persona: ReadingPersona
    @State private var showBooks = false
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 16) {
                Text("Books Found!")
                    .font(.headline)
                    .foregroundColor(.black)
                
                VStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Rectangle()
                                .fill(persona.color.opacity(0.3))
                                .frame(width: 30, height: 40)
                                .cornerRadius(4)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Book Title \(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                Text("Author Name")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(persona.color)
                        }
                        .padding(.horizontal, 20)
                        .opacity(showBooks ? 1 : 0)
                        .offset(x: showBooks ? 0 : 50)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.2), value: showBooks)
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                showBooks = true
            }
        }
    }
}

struct LibraryOrganizationView: View {
    let persona: ReadingPersona
    @State private var showOrganization = false
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 12) {
                Text("Your Digital Library")
                    .font(.headline)
                    .foregroundColor(.black)
                
                // Genre categories
                VStack(spacing: 8) {
                    ForEach(["Fiction", "Non-Fiction", "Mystery"], id: \.self) { genre in
                        HStack {
                            Text(genre)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text("12 books")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(persona.color.opacity(0.1))
                        )
                        .scaleEffect(showOrganization ? 1 : 0.8)
                        .opacity(showOrganization ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: showOrganization)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation {
                showOrganization = true
            }
        }
    }
}

struct ResultsCelebrationView: View {
    let persona: ReadingPersona
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            persona.color.opacity(0.1)
            
            VStack(spacing: 16) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 40))
                    .foregroundColor(persona.color)
                    .scaleEffect(showCelebration ? 1.2 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5).repeatCount(3), value: showCelebration)
                
                Text("Success!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(persona.color)
                
                Text("Your reading journey\nis now organized")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .onAppear {
            withAnimation {
                showCelebration = true
            }
        }
    }
}

// MARK: - Step Progress View
struct StepProgressView: View {
    let steps: [String]
    let currentStep: Int
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStep ? accentColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(maxWidth: 200)
            
            // Current step description
            Text(steps[min(currentStep, steps.count - 1)])
                .font(LandingPageTypography.journeyBody)
                .foregroundColor(LandingPageColors.secondaryText)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
    }
}

// MARK: - Personalized Results View
struct PersonalizedResultsView: View {
    let persona: ReadingPersona
    @State private var animateResults = false
    @State private var showCTA = false
    
    var results: PersonalizedResults {
        persona.scenario.results
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Results Header
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(persona.color)
                    .scaleEffect(animateResults ? 1.2 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5).repeatCount(2), value: animateResults)
                
                Text("Your Potential Results")
                    .font(LandingPageTypography.sectionTitle)
                    .foregroundColor(LandingPageColors.primaryText)
                
                Text("Here's what you could achieve with Bookshelf Scanner")
                    .font(LandingPageTypography.sectionSubtitle)
                    .foregroundColor(LandingPageColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Results Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ResultCard(
                    icon: "books.vertical.fill",
                    value: "\(results.booksOrganized)",
                    label: "Books Organized",
                    color: persona.color,
                    delay: 0.1
                )
                
                ResultCard(
                    icon: "clock.fill",
                    value: results.timesSaved,
                    label: "Time Saved",
                    color: persona.color,
                    delay: 0.2
                )
                
                ResultCard(
                    icon: "star.fill",
                    value: "\(results.recommendationsFound)",
                    label: "New Recommendations",
                    color: persona.color,
                    delay: 0.3
                )
                
                ResultCard(
                    icon: "trophy.fill",
                    value: results.achievementUnlocked,
                    label: "Achievement",
                    color: persona.color,
                    delay: 0.4
                )
            }
            
            // Social Proof
            SocialProofBanner(persona: persona)
                .opacity(showCTA ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).delay(1.0), value: showCTA)
            
            // CTA Button
            if showCTA {
                Button(action: {
                    // Handle CTA action
                    print("Start Your Journey CTA tapped for \(persona.rawValue)")
                }) {
                    HStack(spacing: 12) {
                        Text("Start Your Journey")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(LandingPageTypography.ctaLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [persona.color, persona.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: persona.color.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showCTA)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateResults = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showCTA = true
                }
            }
        }
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let delay: Double
    @State private var animateCard = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(LandingPageColors.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(LandingPageColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EnhancedGlassEffects.secondaryGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(animateCard ? 1.0 : 0.8)
        .opacity(animateCard ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: animateCard)
        .onAppear {
            animateCard = true
        }
    }
}

// MARK: - Social Proof Banner
struct SocialProofBanner: View {
    let persona: ReadingPersona
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .foregroundColor(persona.color)
            
            Text("Join 2,847 \(persona.rawValue.lowercased())s who transformed their reading experience")
                .font(.caption)
                .foregroundColor(LandingPageColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(persona.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(persona.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Design System Extensions (Updated for Consistency)
struct LandingPageColors {
    static let heroGradient = LandingPageDesignSystem.Colors.heroGradient
    static let primaryText = LandingPageDesignSystem.Colors.primaryText
    static let secondaryText = LandingPageDesignSystem.Colors.secondaryText
    static let tertiaryText = LandingPageDesignSystem.Colors.tertiaryText
    static let ctaPrimary = LandingPageDesignSystem.Colors.ctaPrimary
    static let ctaSecondary = LandingPageDesignSystem.Colors.ctaSecondary
    static let interactive = LandingPageDesignSystem.Colors.interactive
}

struct LandingPageTypography {
    static let sectionTitle = LandingPageDesignSystem.Typography.sectionTitle
    static let sectionSubtitle = LandingPageDesignSystem.Typography.sectionSubtitle
    static let journeyTitle = LandingPageDesignSystem.Typography.journeyTitle
    static let journeyBody = LandingPageDesignSystem.Typography.journeyBody
    static let journeyCaption = LandingPageDesignSystem.Typography.journeyCaption
    static let ctaLarge = LandingPageDesignSystem.Typography.ctaLarge
    static let ctaMedium = LandingPageDesignSystem.Typography.ctaMedium
}

struct EnhancedGlassEffects {
    static let primaryGlass = LandingPageDesignSystem.GlassEffects.primaryGlass
    static let secondaryGlass = LandingPageDesignSystem.GlassEffects.secondaryGlass
    static let interactiveGlass = LandingPageDesignSystem.GlassEffects.interactiveGlass
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct EnhancedUserJourneySection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LandingPageColors.heroGradient
                .ignoresSafeArea()
            
            ScrollView {
                EnhancedUserJourneySection()
            }
        }
    }
}