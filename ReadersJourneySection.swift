import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("Alex's Reading Journey")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(.horizontal, 32)

            Text("Meet Alex, a young college student passionate about reading. Follow her journey as she discovers, builds, tracks, and finds her perfect books.")
                .font(AppleBooksTypography.bodyMedium)
                .foregroundColor(AppleBooksColors.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: AppleBooksSpacing.space16) {
                JourneyCard(
                    icon: "magnifyingglass",
                    title: "Discover",
                    problem: "Struggling to discover new books that match my interests",
                    solution: "Get personalized recommendations powered by AI"
                )

                JourneyCard(
                    icon: "plus",
                    title: "Build",
                    problem: "Hard to organize and catalog my physical book collection",
                    solution: "Build your digital library by scanning bookshelves or adding manually"
                )

                JourneyCard(
                    icon: "chart.bar",
                    title: "Track",
                    problem: "Losing track of reading progress and goals",
                    solution: "Track your reading progress, set goals, and monitor your reading habits"
                )

                JourneyCard(
                    icon: "books.vertical",
                    title: "Find",
                    problem: "Can't easily find books in my growing collection",
                    solution: "Find your books easily with smart organization and powerful search"
                )
            }
            .padding(.horizontal, 32)
        }
    }
}

struct JourneyCard: View {
    let icon: String
    let title: String
    let problem: String
    let solution: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space12) {
            HStack(spacing: AppleBooksSpacing.space12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppleBooksColors.accent)
                    .frame(width: 32, height: 32)
                    .background(AppleBooksColors.accent.opacity(0.1))
                    .cornerRadius(6)

                Text(title)
                    .font(AppleBooksTypography.headlineSmall)
                    .foregroundColor(AppleBooksColors.text)
            }

            VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                Text("Problem")
                    .font(AppleBooksTypography.bodySmall)
                    .foregroundColor(AppleBooksColors.textSecondary)
                    .fontWeight(.semibold)

                Text(problem)
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                Text("Solution")
                    .font(AppleBooksTypography.bodySmall)
                    .foregroundColor(AppleBooksColors.accent)
                    .fontWeight(.semibold)

                Text(solution)
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.text)
            }
        }
        .padding(AppleBooksSpacing.space16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppleBooksColors.card)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .frame(minHeight: 140)
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