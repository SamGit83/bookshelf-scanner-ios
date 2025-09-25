import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("Alex's Reading Journey")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(.horizontal, 32)

            Text("Meet Alex, a busy college student passionate about reading. See how she navigates her daily reading challenges and discovers how Bookshelf Scanner transforms her experience.")
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppleBooksSpacing.space24)

            VStack(spacing: AppleBooksSpacing.space16) {
                 JourneyCard(
                     icon: "person.fill",
                     title: "Alex's Daily Reading Routine",
                     problem: "Alex, a passionate college student, starts her mornings with coffee and a good book. However, she struggles to discover new titles that match her interests, loses track of her reading progress, and finds it hard to organize her growing physical book collection.",
                     solution: "These challenges make her reading experience less enjoyable and efficient."
                 )

                 JourneyCard(
                     icon: "sparkles",
                     title: "How Bookshelf Scanner Helps",
                     problem: "Traditional methods of book discovery and organization are time-consuming and frustrating.",
                     solution: "Our app uses AI to provide personalized recommendations, tracks reading progress seamlessly, and allows easy scanning of bookshelves to build a digital library."
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
        .frame(width: .infinity, height: 160)
        .frame(maxWidth: .infinity)
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