import SwiftUI

struct HeroSection: View {
    @Binding var showSignup: Bool
    @State private var animateContent = false

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
            withAnimation(.spring().delay(0.1)) {
                animateContent = true
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