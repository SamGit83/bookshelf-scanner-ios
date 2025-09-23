import SwiftUI

struct HomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var showLogin = false
    @State private var showSignup = false

    // Sample data - in a real app, this would come from a view model
    private var currentlyReadingBooks: [Book] {
        // Placeholder books - replace with actual data
        [
            Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Fiction"),
            Book(title: "To Kill a Mockingbird", author: "Harper Lee", genre: "Fiction"),
            Book(title: "1984", author: "George Orwell", genre: "Dystopian")
        ]
    }

    private var favoriteBooks: [Book] {
        [
            Book(title: "Pride and Prejudice", author: "Jane Austen", genre: "Romance"),
            Book(title: "The Catcher in the Rye", author: "J.D. Salinger", genre: "Fiction"),
            Book(title: "Harry Potter", author: "J.K. Rowling", genre: "Fantasy")
        ]
    }

    private var trendingBooks: [Book] {
        [
            Book(title: "The Midnight Library", author: "Matt Haig", genre: "Fiction"),
            Book(title: "Atomic Habits", author: "James Clear", genre: "Self-Help"),
            Book(title: "Project Hail Mary", author: "Andy Weir", genre: "Sci-Fi")
        ]
    }

    private var promotionalGradient: LinearGradient {
        LinearGradient(
            colors: [AppleBooksColors.promotional, AppleBooksColors.promotional.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Daily Reading Goals Section
                ReadingGoalsSection()

                // Currently Reading Collection
                AppleBooksCollection(
                    books: currentlyReadingBooks,
                    title: "Continue Reading",
                    subtitle: "Pick up where you left off",
                    onSeeAllTap: nil,
                    viewModel: nil
                ) {
                    // Handle book tap - navigate to book detail
                    print("Book tapped: \($0.title ?? "Unknown")")
                }

                // Featured Promotional Banner
                AppleBooksPromoBanner(
                    title: "$9.99 Audiobooks",
                    subtitle: "Limited time offer",
                    gradient: promotionalGradient
                ) {
                    // Handle promo tap
                    print("Promo banner tapped")
                }

                // Customer Favorites
                AppleBooksCollection(
                    books: favoriteBooks,
                    title: "Customer Favorites",
                    subtitle: "See the books readers love",
                    onSeeAllTap: nil,
                    viewModel: nil
                ) {
                    // Handle book tap
                    print("Book tapped: \($0.title ?? "Unknown")")
                }

                // New & Trending
                AppleBooksCollection(
                    books: trendingBooks,
                    title: "New & Trending",
                    subtitle: "Explore what's hot in audiobooks",
                    onSeeAllTap: nil,
                    viewModel: nil
                ) {
                    // Handle book tap
                    print("Book tapped: \($0.title ?? "Unknown")")
                }
            }
        }
        .background(AppleBooksColors.background)
        .navigationBarHidden(true)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}