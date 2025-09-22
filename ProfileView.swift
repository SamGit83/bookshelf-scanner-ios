import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                // Vibrant profile background gradient
                BackgroundGradients.profileGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: SpacingSystem.xl) {
                        // Enhanced User Info Section
                        VStack(spacing: SpacingSystem.lg) {
                            // Profile picture with enhanced styling
                            ProfilePictureView(authService: authService)
                                .padding(SpacingSystem.md)
                                .background(
                                    Circle()
                                        .fill(AdaptiveColors.glassBackground)
                                        .overlay(
                                            Circle()
                                                .stroke(ProfileColors.avatarBorder, lineWidth: 3)
                                        )
                                        .shadow(color: ProfileColors.avatarBorder.opacity(0.3), radius: 20, x: 0, y: 10)
                                )

                            if let user = authService.currentUser {
                                VStack(spacing: SpacingSystem.sm) {
                                    Text(user.email ?? "No email")
                                        .font(TypographySystem.displaySmall)
                                        .foregroundColor(AdaptiveColors.primaryText)
                                        .multilineTextAlignment(.center)

                                    Text("Member since \(formattedDate(user.metadata.creationDate))")
                                        .font(TypographySystem.bodyMedium)
                                        .foregroundColor(AdaptiveColors.secondaryText)
                                }
                                .padding(.horizontal, SpacingSystem.lg)
                            }
                        }
                        .padding(.top, SpacingSystem.xl)

                        // Enhanced Menu Options with Glass Cards
                        VStack(spacing: SpacingSystem.md) {
                            // Account Section
                            VStack(spacing: SpacingSystem.sm) {
                                NavigationLink(destination: AccountSettingsView()) {
                                    ProfileMenuRow(
                                        icon: "gear.circle.fill",
                                        title: "Account Settings",
                                        iconColor: PrimaryColors.electricBlue
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())

                                NavigationLink(destination: ReadingStatsView()) {
                                    ProfileMenuRow(
                                        icon: "chart.bar.fill",
                                        title: "Reading Statistics",
                                        iconColor: PrimaryColors.freshGreen
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            // Theme Section
                            VStack(spacing: SpacingSystem.md) {
                                HStack {
                                    Text("Appearance")
                                        .font(TypographySystem.headlineSmall)
                                        .foregroundColor(AdaptiveColors.primaryText)
                                    Spacer()
                                }
                                .padding(.horizontal, SpacingSystem.md)

                                GlassSegmentedPicker(
                                    title: "Theme",
                                    selection: $themeManager.currentPreference,
                                    options: ColorSchemePreference.allCases,
                                    displayText: { $0.rawValue.capitalized }
                                )
                                .padding(.horizontal, SpacingSystem.md)
                                .featureCardStyle()
                            }

                            // Sign Out Section
                            Button(action: {
                                showSignOutAlert = true
                            }) {
                                ProfileMenuRow(
                                    icon: "arrow.right.square.fill",
                                    title: "Sign Out",
                                    iconColor: ProfileColors.dangerActions,
                                    textColor: ProfileColors.dangerActions
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, SpacingSystem.md)
                        
                        Spacer(minLength: SpacingSystem.xxxl)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
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

// Enhanced Profile Menu Row Component
struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let textColor: Color?
    
    init(icon: String, title: String, iconColor: Color, textColor: Color? = nil) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.textColor = textColor
    }
    
    var body: some View {
        HStack(spacing: SpacingSystem.md) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(TypographySystem.bodyLarge)
                .foregroundColor(textColor ?? AdaptiveColors.primaryText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AdaptiveColors.secondaryText)
        }
        .padding(SpacingSystem.md)
        .featureCardStyle()
    }
}

struct ProfilePictureView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showImagePicker = false

    private let userDefaultsKey = "profileImageData"

    init(authService: AuthService) {
        self._authService = ObservedObject(wrappedValue: authService)
        _selectedImage = State(initialValue: loadImageFromUserDefaults())
    }

    private var initialsTextColor: Color {
        AdaptiveColors.primaryText
    }

    var body: some View {
        ZStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    PrimaryColors.energeticPink.opacity(0.3),
                                    PrimaryColors.vibrantPurple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Text(initials)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(initialsTextColor)
                }
            }

            // Enhanced overlay button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(SpacingSystem.sm)
                            .background(PrimaryColors.energeticPink)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: PrimaryColors.energeticPink.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(SpacingSystem.xs)
                }
            }
            .frame(width: 120, height: 120)
        }
        .frame(width: 120, height: 120)
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
        let name = authService.currentUser?.displayName ?? authService.currentUser?.email ?? "?"
        if name == "?" { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let firstInitial = components.first?.first?.uppercased() ?? ""
            let lastInitial = components.last?.first?.uppercased() ?? ""
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
    var body: some View {
        ZStack {
            BackgroundGradients.libraryGradient
                .ignoresSafeArea()
            
            VStack(spacing: SpacingSystem.xl) {
                // Enhanced coming soon message
                VStack(spacing: SpacingSystem.lg) {
                    ZStack {
                        Circle()
                            .fill(PrimaryColors.vibrantPurple.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 15)

                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(PrimaryColors.vibrantPurple)
                    }

                    VStack(spacing: SpacingSystem.sm) {
                        Text("Reading Statistics")
                            .font(TypographySystem.displayMedium)
                            .foregroundColor(AdaptiveColors.primaryText)

                        Text("Coming Soon!")
                            .font(TypographySystem.bodyLarge)
                            .foregroundColor(AdaptiveColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()
            }
            .padding(SpacingSystem.lg)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct HelpView: View {
    var body: some View {
        ZStack {
            BackgroundGradients.heroGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: SpacingSystem.xl) {
                    VStack(alignment: .leading, spacing: SpacingSystem.lg) {
                        Text("How to Use Bookshelf Scanner")
                            .font(TypographySystem.displayMedium)
                            .foregroundColor(AdaptiveColors.primaryText)
                            .padding(.horizontal, SpacingSystem.md)

                        VStack(spacing: SpacingSystem.lg) {
                            HelpSection(
                                icon: "camera.fill",
                                title: "Scanning Books",
                                description: "Point your camera at a bookshelf and tap the capture button. The app will analyze the image and extract book information.",
                                iconColor: PrimaryColors.energeticPink
                            )

                            HelpSection(
                                icon: "books.vertical.fill",
                                title: "Managing Your Library",
                                description: "Books are automatically added to your library. You can move them to 'Currently Reading' or remove them as needed.",
                                iconColor: PrimaryColors.freshGreen
                            )

                            HelpSection(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Sync Across Devices",
                                description: "Your library syncs automatically across all your devices when you're signed in.",
                                iconColor: PrimaryColors.electricBlue
                            )
                        }
                    }
                    .padding(SpacingSystem.lg)
                }
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: SpacingSystem.md) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                Text(title)
                    .font(TypographySystem.headlineSmall)
                    .foregroundColor(AdaptiveColors.primaryText)
                
                Text(description)
                    .font(TypographySystem.bodyMedium)
                    .foregroundColor(AdaptiveColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(SpacingSystem.md)
        .featureCardStyle()
    }
}

struct PrivacyView: View {
    var body: some View {
        ZStack {
            BackgroundGradients.profileGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: SpacingSystem.xl) {
                    VStack(alignment: .leading, spacing: SpacingSystem.lg) {
                        Text("Privacy Policy")
                            .font(TypographySystem.displayMedium)
                            .foregroundColor(AdaptiveColors.primaryText)
                            .padding(.horizontal, SpacingSystem.md)

                        Text("We respect your privacy and are committed to protecting your personal information.")
                            .font(TypographySystem.bodyLarge)
                            .foregroundColor(AdaptiveColors.secondaryText)
                            .padding(.horizontal, SpacingSystem.md)
                            .featureCardStyle()

                        VStack(spacing: SpacingSystem.lg) {
                            PrivacySection(
                                icon: "doc.text.fill",
                                title: "Data Collection",
                                description: "We collect your email address for authentication and book data for your personal library.",
                                iconColor: PrimaryColors.electricBlue
                            )

                            PrivacySection(
                                icon: "gear.circle.fill",
                                title: "Data Usage",
                                description: "Your data is used solely to provide the bookshelf scanning service and sync your library across devices.",
                                iconColor: PrimaryColors.freshGreen
                            )

                            PrivacySection(
                                icon: "lock.shield.fill",
                                title: "Data Security",
                                description: "All data is encrypted and stored securely using Firebase's industry-standard security practices.",
                                iconColor: PrimaryColors.energeticPink
                            )
                        }
                    }
                    .padding(SpacingSystem.lg)
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct PrivacySection: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: SpacingSystem.md) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                Text(title)
                    .font(TypographySystem.headlineSmall)
                    .foregroundColor(AdaptiveColors.primaryText)
                
                Text(description)
                    .font(TypographySystem.bodyMedium)
                    .foregroundColor(AdaptiveColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(SpacingSystem.md)
        .featureCardStyle()
    }
}