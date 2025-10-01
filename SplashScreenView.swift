import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background matching LaunchScreen
            Color(red: 0.949, green: 0.949, blue: 0.969)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon with scale animation
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // App Name with fade-in animation
                Text("Book Shelfie")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.42))
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Animate icon scale and fade-in
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Add subtle bounce effect
            withAnimation(.easeInOut(duration: 1.2).delay(0.8)) {
                scale = 1.05
            }
            
            withAnimation(.easeInOut(duration: 0.3).delay(2.0)) {
                scale = 1.0
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}