import SwiftUI

struct HomeNavigationBar: View {
    @Binding var showLogin: Bool
    @Binding var showSignup: Bool
    @State private var showPopover = false

    var body: some View {
        ZStack {
            // Translucent background with blur
            Color.white.opacity(0.1)
                .blur(radius: 1)
                .ignoresSafeArea()

            HStack {
                Spacer()

                // Centered Title
                Text("Bookshelf Scanner")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                // Menu Button
                Button(action: {
                    showPopover = true
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
        .popover(isPresented: $showPopover) {
            GlassCard {
                VStack(spacing: 16) {
                    Button(action: {
                        print("HomeNavigationBar: Login button tapped")
                        showLogin = true
                        showPopover = false
                    }) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button(action: {
                        print("HomeNavigationBar: Sign Up button tapped")
                        showSignup = true
                        showPopover = false
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(Color.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .padding(20)
            }
            .frame(width: 200)
            .presentationCompactAdaptation(.popover)
        }
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