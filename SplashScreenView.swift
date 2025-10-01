import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var letterScales: [CGFloat] = Array(repeating: 1.0, count: 12)
    
    private let appName = "Book Shelfie"
        
    var body: some View {
        ZStack {
            // Background matching LaunchScreen
            Color(red: 0.949, green: 0.949, blue: 0.969)
                .ignoresSafeArea()

            // App Icon with scale animation
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                .position(x: 196.5, y: 376)
                .scaleEffect(scale)
                .opacity(opacity)

            // App Name with letter-by-letter bounce animation
            HStack(spacing: 0) {
                ForEach(Array(appName.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .scaleEffect(letterScales[index])
                        .opacity(opacity)
                }
            }
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
            .position(x: 196.5, y: 476)
        }
        .onAppear {
            // Animate icon scale and fade-in
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }

            // Add subtle bounce effect to icon
            withAnimation(.easeInOut(duration: 1.2).delay(0.8)) {
                scale = 1.05
            }

            withAnimation(.easeInOut(duration: 0.3).delay(2.0)) {
                scale = 1.0
            }

            // Letter-by-letter bounce animation
            for index in 0..<appName.count {
                let delay = 0.8 + Double(index) * 0.15

                // Bounce up
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                        letterScales[index] = 1.3
                    }
                }

                // Bounce back down
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                        letterScales[index] = 1.0
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}