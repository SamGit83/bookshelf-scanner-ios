import SwiftUI
import Foundation

struct HeroSection: View {
    @Binding var showSignup: Bool
    @State private var animateContent = false
    @State private var floatingOffset: CGFloat = 0
    @State private var iconOpacities: [CGFloat] = Array(repeating: 0.0, count: 4)
    @State private var textOffsets: [CGFloat] = Array(repeating: 30.0, count: 4)
    @State private var isAnimatingSequence = false
    @State private var currentIndex = 0

    private let items = [
        ("camera.fill", "Scan"),
        ("books.vertical.fill", "catalog"),
        ("list.bullet", "organize"),
        ("magnifyingglass", "discover")
    ]
    
    private func startSequenceCycle() {
        print("DEBUG: Starting sequence cycle")
        iconOpacities = Array(repeating: 0.0, count: 4)
        textOffsets = Array(repeating: 30.0, count: 4)
        currentIndex = 0
    
        func animateNext() {
            if currentIndex < items.count {
                print("DEBUG: Animating index \(currentIndex)")
                withAnimation(.easeInOut(duration: 0.5)) {
                    iconOpacities[currentIndex] = 1.0
                }
    
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("DEBUG: Sliding text for index \(currentIndex)")
                    withAnimation(.easeInOut(duration: 0.5)) {
                        textOffsets[currentIndex] = 0
                    }
    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        print("DEBUG: Fading out icon for index \(currentIndex)")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            iconOpacities[currentIndex] = 0.0
                        }
    
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            currentIndex += 1
                            animateNext()
                        }
                    }
                }
            } else {
                print("DEBUG: Resetting sequence")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        isAnimatingSequence = true
                        iconOpacities = Array(repeating: 0.0, count: 4)
                        textOffsets = Array(repeating: 30.0, count: 4)
                    }
    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAnimatingSequence = false
                        startSequenceCycle()
                    }
                }
            }
        }
    
        animateNext()
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 40)

            // App Icon with glow effect
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)

                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .offset(y: floatingOffset)
                    .animation(.spring().delay(0.3), value: animateContent)
            }

            // Headline
            Text("Transform Your Bookshelf into a Digital Library")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .offset(y: animateContent ? 0 : 30)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring().delay(0.1), value: animateContent)

            // Subheadline
            Text("Scan your physical books with AI, discover new reads, and track your reading journey—all in one beautiful app.")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring().delay(0.2), value: animateContent)
            
            // Animated Sequence
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    ForEach(0..<4, id: \.self) { index in
                        VStack(spacing: 8) {
                            Image(systemName: items[index].0)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .opacity(iconOpacities[index])
                                .animation(.easeInOut(duration: 0.5), value: iconOpacities[index])

                            Text(items[index].1)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .offset(y: textOffsets[index])
                                .animation(.easeInOut(duration: 0.5), value: textOffsets[index])
                        }
                    }
                }
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
                .rotationEffect(.degrees(Double(isAnimatingSequence ? 360 : 0)))
                .animation(.easeInOut(duration: 0.8), value: isAnimatingSequence)
            }

            // CTA Button
            Button(action: {
                print("HeroSection: Get Started button tapped")
                showSignup = true
            }) {
                Text("Get Started")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
            }
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1 : 0)
            .animation(.spring().delay(0.4), value: animateContent)

            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.7)
        .onAppear {
            print("DEBUG: HeroSection onAppear triggered")
            withAnimation(.spring().delay(0.1)) {
                animateContent = true
            }
            
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatingOffset = -8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startSequenceCycle()
            }
        }
    }
}

struct HeroSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            HeroSection(showSignup: .constant(false))
        }
    }
}