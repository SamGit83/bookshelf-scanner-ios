import SwiftUI

struct UserJourneySection: View {
    @State private var animateSection = false

    let steps = [
        ("Scan Your Bookshelf", "Point your camera at your bookshelf and capture a photo", "camera.fill"),
        ("AI Recognition", "Our AI identifies books instantly using advanced vision technology", "sparkles"),
        ("Organize Your Library", "Automatically add books to your digital collection", "books.vertical.fill"),
        ("Track & Discover", "Monitor reading progress and get personalized recommendations", "chart.bar.fill")
    ]

    var body: some View {
        VStack(spacing: 32) {
            // Section Title
            Text("How It Works")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .offset(y: animateSection ? 0 : 30)
                .opacity(animateSection ? 1 : 0)
                .animation(.spring().delay(0.1), value: animateSection)

            // Steps
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        StepCard(
                            stepNumber: index + 1,
                            title: steps[index].0,
                            description: steps[index].1,
                            icon: steps[index].2,
                            delay: Double(index) * 0.1
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .offset(y: animateSection ? 0 : 30)
            .opacity(animateSection ? 1 : 0)
            .animation(.spring().delay(0.2), value: animateSection)

            // Benefits Summary
            VStack(spacing: 16) {
                Text("Save time cataloging • Never lose track of your books • Discover new favorites • Track reading goals")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .offset(y: animateSection ? 0 : 20)
            .opacity(animateSection ? 1 : 0)
            .animation(.spring().delay(0.3), value: animateSection)
        }
        .padding(.vertical, 64)
        .onAppear {
            withAnimation(.spring().delay(0.1)) {
                animateSection = true
            }
        }
    }
}

struct StepCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let delay: Double

    @State private var animateCard = false

    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                // Step Number
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Text("\(stepNumber)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .foregroundColor(.black)
                }

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.black)
                    .foregroundColor(.black)
                    .frame(height: 40)

                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                // Description
                Text(description)
                    .font(.body)
                    .foregroundColor(.black)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(24)
            .frame(width: 280, height: 300)
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

struct UserJourneySection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            UserJourneySection()
        }
    }
}