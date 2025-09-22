import SwiftUI

struct FeaturesSection: View {
    @State private var animateSection = false

    let features = [
        ("AI-Powered Scanning", "Advanced computer vision recognizes books instantly", "sparkles"),
        ("Offline Access", "Read and manage your library anywhere, even offline", "wifi.slash"),
        ("Reading Progress", "Track pages read, set goals, and monitor your reading habits", "chart.bar.fill"),
        ("Smart Recommendations", "Discover new books based on your reading patterns", "star.fill"),
        ("Manual Entry", "Add books manually with ISBN lookup for complete coverage", "plus.circle.fill"),
        ("Cross-Device Sync", "Access your library on all your Apple devices", "arrow.triangle.2.circlepath")
    ]

    var body: some View {
        VStack(spacing: 32) {
            // Section Title
            Text("Powerful Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .offset(y: animateSection ? 0 : 30)
                .opacity(animateSection ? 1 : 0)
                .animation(.spring().delay(0.1), value: animateSection)

            // Features Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                ForEach(0..<features.count, id: \.self) { index in
                    FeatureCard(
                        title: features[index].0,
                        description: features[index].1,
                        icon: features[index].2,
                        delay: Double(index) * 0.1
                    )
                }
            }
            .padding(.horizontal, 20)
            .offset(y: animateSection ? 0 : 30)
            .opacity(animateSection ? 1 : 0)
            .animation(.spring().delay(0.2), value: animateSection)
        }
        .padding(.vertical, 64)
        .onAppear {
            withAnimation(.spring().delay(0.1)) {
                animateSection = true
            }
        }
    }
}

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let delay: Double

    @State private var animateCard = false

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                // Title
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Description
                Text(description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(20)
            .frame(height: 200)
        }
        .offset(y: animateCard ? 0 : 30)
        .opacity(animateCard ? 1 : 0)
        .animation(.spring().delay(delay), value: animateCard)
        .onAppear {
            withAnimation(.spring().delay(delay)) {
                animateCard = true
            }
        }
    }
}

struct FeaturesSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            ScrollView {
                FeaturesSection()
            }
        }
    }
}