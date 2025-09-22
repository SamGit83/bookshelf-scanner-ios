import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                // User Info
                VStack(spacing: 10) {
                    GlassCard {
                        ProfilePictureView(authService: authService)
                            .padding()
                    }

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

                        Section(header: Text("Appearance")) {
                            GlassSegmentedPicker(
                                title: "Theme",
                                selection: $themeManager.currentPreference,
                                options: ColorSchemePreference.allCases,
                                displayText: { $0.rawValue.capitalized }
                            )
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

struct ProfilePictureView: View {
    @ObservedObject var authService: AuthService
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showImagePicker = false

    private let userDefaultsKey = "profileImageData"

    init(authService: AuthService) {
        self._authService = ObservedObject(wrappedValue: authService)
        _selectedImage = State(initialValue: loadImageFromUserDefaults())
    }

    var body: some View {
        ZStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Text(initials)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Overlay button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
            }
            .frame(width: 100, height: 100)
        }
        .frame(width: 100, height: 100)
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    saveImageToUserDefaults(uiImage)
                }
            }
        }
    }

    private var initials: String {
        guard let displayName = authService.currentUser?.displayName else { return "?" }
        let components = displayName.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = components[0].first?.uppercased() ?? ""
            let lastInitial = components[1].first?.uppercased() ?? ""
            return firstInitial + lastInitial
        } else if let first = components.first?.first?.uppercased() {
            return first
        }
        return "?"
    }

    private func loadImageFromUserDefaults() -> UIImage? {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }

    private func saveImageToUserDefaults(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
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