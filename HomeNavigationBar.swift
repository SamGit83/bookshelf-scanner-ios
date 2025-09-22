import SwiftUI

struct HomeNavigationBar: View {
    @Binding var showLogin: Bool
    @Binding var showSignup: Bool

    var body: some View {
        ZStack {
            // Translucent background with blur
            Color.white.opacity(0.1)
                .blur(radius: 1)
                .ignoresSafeArea()

            HStack(spacing: 16) {
                // App Logo and Title
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .blur(radius: 5)

                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    Text("Bookshelf Scanner")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        print("HomeNavigationBar: Login button tapped")
                        showLogin = true
                    }) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button(action: {
                        print("HomeNavigationBar: Sign Up button tapped")
                        showSignup = true
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(Color.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
    }
}

struct HomeNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            HomeNavigationBar(showLogin: .constant(false), showSignup: .constant(false))
        }
        .previewLayout(.sizeThatFits)
    }
}