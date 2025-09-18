import SwiftUI

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                // User Info
                VStack(spacing: 10) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    if let user = authService.currentUser {
                        Text(user.email ?? "No email")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Member since \(formattedDate(user.metadata.creationDate))")
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Menu Options
                VStack(spacing: 0) {
                    List {
                        Section {
                            NavigationLink(destination: AccountSettingsView()) {
                                HStack {
                                    Image(systemName: "gear")
                                        .foregroundColor(.blue)
                                    Text("Account Settings")
                                }
                            }

                            NavigationLink(destination: ReadingStatsView()) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                        .foregroundColor(.green)
                                    Text("Reading Statistics")
                                }
                            }
                        }

                        Section {
                            Button(action: {
                                showSignOutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                        .foregroundColor(.red)
                                    Text("Sign Out")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }

                Spacer()
            }
            .navigationTitle("Profile")
            .alert(isPresented: $showSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        authService.signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AccountSettingsView: View {
    @State private var showPasswordReset = false
    @State private var message = ""

    var body: some View {
        List {
            Section("Account") {
                Button(action: {
                    showPasswordReset = true
                }) {
                    Text("Change Password")
                }
            }

            Section("Support") {
                NavigationLink(destination: HelpView()) {
                    Text("Help & Support")
                }

                NavigationLink(destination: PrivacyView()) {
                    Text("Privacy Policy")
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
    }
}

struct ReadingStatsView: View {
    // This would show reading statistics
    // For now, just a placeholder
    var body: some View {
        VStack(spacing: 20) {
            Text("Reading Statistics")
                .font(.title)
                .fontWeight(.bold)

            Text("Coming Soon!")
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle("Statistics")
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("How to Use Bookshelf Scanner")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 15) {
                    Text("📷 Scanning Books")
                        .font(.headline)
                    Text("Point your camera at a bookshelf and tap the capture button. The app will analyze the image and extract book information.")

                    Text("📚 Managing Your Library")
                        .font(.headline)
                    Text("Books are automatically added to your library. You can move them to 'Currently Reading' or remove them as needed.")

                    Text("🔄 Sync Across Devices")
                        .font(.headline)
                    Text("Your library syncs automatically across all your devices when you're signed in.")
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Help")
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("We respect your privacy and are committed to protecting your personal information.")
                    .font(.body)

                Text("Data Collection")
                    .font(.headline)
                Text("We collect your email address for authentication and book data for your personal library.")

                Text("Data Usage")
                    .font(.headline)
                Text("Your data is used solely to provide the bookshelf scanning service and sync your library across devices.")

                Text("Data Security")
                    .font(.headline)
                Text("All data is encrypted and stored securely using Firebase's industry-standard security practices.")
            }
            .padding()
        }
        .navigationTitle("Privacy")
    }
}