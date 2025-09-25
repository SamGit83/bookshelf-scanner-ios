import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        VStack(spacing: AppleBooksSpacing.space24) {
            Text("Reader's Journey")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)

            VStack(spacing: AppleBooksSpacing.space20) {
                JourneyStepRow(
                    stepNumber: 1,
                    icon: "magnifyingglass",
                    title: "Discover",
                    description: "Discover new books and get personalized recommendations powered by AI"
                )

                JourneyStepRow(
                    stepNumber: 2,
                    icon: "plus.circle.fill",
                    title: "Build",
                    description: "Build your digital library by scanning bookshelves or adding manually"
                )

                JourneyStepRow(
                    stepNumber: 3,
                    icon: "chart.bar.fill",
                    title: "Track",
                    description: "Track your reading progress, set goals, and monitor your reading habits"
                )

                JourneyStepRow(
                    stepNumber: 4,
                    icon: "books.vertical.fill",
                    title: "Find",
                    description: "Find your books easily with smart organization and powerful search"
                )
            }
            .padding(.horizontal, AppleBooksSpacing.space24)
        }
    }
}

struct JourneyStepRow: View {
    let stepNumber: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppleBooksSpacing.space16) {
            // Step Number Badge
            ZStack {
                Circle()
                    .fill(AppleBooksColors.accent.opacity(0.1))
                    .frame(width: 32, height: 32)

                Text("\(stepNumber)")
                    .font(AppleBooksTypography.headlineSmall)
                    .foregroundColor(AppleBooksColors.accent)
                    .fontWeight(.bold)
            }

            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppleBooksColors.accent)
                .frame(width: 40, height: 40)
                .background(AppleBooksColors.accent.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                Text(title)
                    .font(AppleBooksTypography.headlineSmall)
                    .foregroundColor(AppleBooksColors.text)

                Text(description)
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
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