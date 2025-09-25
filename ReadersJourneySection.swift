import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("Alex's Reading Journey")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(.horizontal, 32)

            Text("Meet Alex, a college student overwhelmed by her growing physical bookshelf. Discover how traditional reading struggles led her to Bookshelf Scanner, and how our app transformed her entire reading experience.")
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppleBooksSpacing.space24)

            VStack(spacing: AppleBooksSpacing.space16) {
                 JourneyCard(
                     icon: "books.vertical.fill",
                     title: "Traditional Reading Struggles",
                     description: "Alex spent countless hours manually cataloging her growing book collection. She struggled with disorganized shelves, forgetting which books she owned, and wasting time searching for titles she couldn't remember. Physical bookshelves made it impossible to track her reading progress or discover new books efficiently."
                 )

                 JourneyCard(
                     icon: "sparkles",
                     title: "Enhanced Reading Experience",
                     description: "With Bookshelf Scanner, Alex now scans her bookshelves instantly using AI. Her entire collection is organized digitally, she tracks reading progress effortlessly, and receives personalized recommendations. No more lost books or forgotten titles - just pure reading enjoyment and discovery."
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