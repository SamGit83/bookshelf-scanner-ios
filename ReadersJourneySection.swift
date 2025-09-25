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
                     description: "Alex, a passionate college student, starts her mornings with coffee and a good book. She effortlessly discovers new titles that match her interests, tracks her reading progress seamlessly, and organizes her growing physical book collection with ease."
                 )

                 JourneyCard(
                     icon: "sparkles",
                     title: "How Bookshelf Scanner Helps",
                     description: "With Bookshelf Scanner, Alex now has an AI companion that suggests books she'll love, keeps her reading progress at her fingertips, and lets her scan her shelves to create a beautiful digital library."
                 )
             }
            .padding(.horizontal, 32)
        }
    }
}

struct JourneyCard: View {
    let icon: String
    let title: String
    let description: String

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

            Text(description)
                .font(AppleBooksTypography.bodyMedium)
                .foregroundColor(AppleBooksColors.textSecondary)
        }
        .padding(AppleBooksSpacing.space16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppleBooksColors.card)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
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