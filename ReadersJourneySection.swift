import SwiftUI

struct ReadersJourneySection: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("Your Reading Journey")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(.horizontal, 32)

            Text("Transform your physical bookshelf into a digital library with AI-powered scanning. Discover how Bookshelf Scanner revolutionizes your reading experience from discovery to organization.")
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppleBooksSpacing.space24)

            VStack(spacing: AppleBooksSpacing.space16) {
                 JourneyCard(
                     icon: "star.fill",
                     title: "Discovery & Onboarding",
                     description: "Start your journey with an intuitive onboarding that highlights bookshelf scanning benefits. Grant camera permissions and dive into the world of digital library management with comprehensive tutorials."
                 )

                 JourneyCard(
                     icon: "camera.fill",
                     title: "Core Bookshelf Scanning",
                     description: "Scan your physical bookshelves with advanced AI recognition. Our app detects multiple books from a single photo, adds them to your library with proper status tracking, and seamlessly integrates with your reading workflow."
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