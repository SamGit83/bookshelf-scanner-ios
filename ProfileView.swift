import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var authService: AuthService
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var accentColorManager = AccentColorManager.shared
    @ObservedObject var usageTracker = UsageTracker.shared
    @State private var showSignOutAlert = false
    @State private var showUpgradeModal = false
    @State private var showSubscriptionView = false
    @State private var expandedUsageDetails = false

    var body: some View {
            ZStack {
                // Apple Books background
                AppleBooksColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppleBooksSpacing.space32) {
                        // User Info Section
                        VStack(spacing: AppleBooksSpacing.space20) {
                            // Profile picture
                            HStack {
                                Spacer()
                                ProfilePictureView(authService: authService)
                                    .background(
                                        Circle()
                                            .fill(AppleBooksColors.card)
                                            .shadow(color: AppleBooksShadow.subtle.color, radius: AppleBooksShadow.subtle.radius, x: AppleBooksShadow.subtle.x, y: AppleBooksShadow.subtle.y)
                                    )
                                Spacer()
                            }
                            .padding(.bottom, AppleBooksSpacing.space16)

                            if let user = authService.currentUser {
                                VStack(spacing: AppleBooksSpacing.space8) {
                                    HStack(spacing: AppleBooksSpacing.space8) {
                                        Image(systemName: "person.circle")
                                            .font(AppleBooksTypography.headlineMedium)
                                            .foregroundColor(AppleBooksColors.accent)
                                        Text(user.displayName ?? user.email ?? "User")
                                            .font(AppleBooksTypography.headlineLarge)
                                            .foregroundColor(AppleBooksColors.text)
                                            .multilineTextAlignment(.center)
                                    }

                                    HStack(spacing: AppleBooksSpacing.space8) {
                                        Image(systemName: "envelope")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(colorScheme == .dark ? AppleBooksColors.accent : AppleBooksColors.textSecondary)
                                        Text(user.email ?? "")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(colorScheme == .dark ? AppleBooksColors.accent : AppleBooksColors.textSecondary)
                                    }

                                    HStack(spacing: AppleBooksSpacing.space8) {
                                        Image(systemName: "calendar")
                                            .font(AppleBooksTypography.caption)
                                            .foregroundColor(colorScheme == .dark ? AppleBooksColors.accent : AppleBooksColors.textTertiary)
                                        Text("Member since \(formattedDate(user.creationDate))")
                                            .font(AppleBooksTypography.caption)
                                            .foregroundColor(colorScheme == .dark ? AppleBooksColors.accent : AppleBooksColors.textTertiary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)
                        .padding(.top, AppleBooksSpacing.space32)

                        // Usage Stats Section with Progressive Disclosure
                        if let user = authService.currentUser {
                            VStack(spacing: AppleBooksSpacing.space16) {
                                AppleBooksSectionHeader(
                                    title: "Usage This Month",
                                    subtitle: user.tier == .free ? "Free tier limits" : "Premium - Unlimited",
                                    showSeeAll: user.tier == .free,
                                    seeAllAction: user.tier == .free ? { expandedUsageDetails.toggle() } : nil
                                )

                                AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                    VStack(spacing: AppleBooksSpacing.space16) {
                                        // Scans
                                        EnhancedUsageRow(
                                            icon: "camera.fill",
                                            title: "AI Scans",
                                            current: usageTracker.monthlyScans,
                                            limit: usageTracker.scanLimit,
                                            color: AppleBooksColors.accent,
                                            showTeaser: user.tier == .free && usageTracker.monthlyScans >= usageTracker.scanLimit * 3 / 4,
                                            onUpgradeTap: {
                                                showUpgradeModal = true
                                            }
                                        )

                                        // Books
                                        EnhancedUsageRow(
                                            icon: "book.fill",
                                            title: "Books in Library",
                                            current: usageTracker.totalBooks,
                                            limit: usageTracker.bookLimit,
                                            color: AppleBooksColors.success,
                                            showTeaser: user.tier == .free && usageTracker.totalBooks >= usageTracker.bookLimit * 3 / 4,
                                            onUpgradeTap: {
                                                showUpgradeModal = true
                                            }
                                        )

                                        // Recommendations
                                        EnhancedUsageRow(
                                            icon: "sparkles",
                                            title: "AI Recommendations",
                                            current: usageTracker.monthlyRecommendations,
                                            limit: usageTracker.recommendationLimit,
                                            color: AppleBooksColors.promotional,
                                            showTeaser: user.tier == .free && usageTracker.monthlyRecommendations >= usageTracker.recommendationLimit * 3 / 4,
                                            onUpgradeTap: {
                                                showUpgradeModal = true
                                            }
                                        )

                                        // Progressive disclosure for detailed usage
                                        if expandedUsageDetails && user.tier == .free {
                                            Divider()
                                                .background(AppleBooksColors.textTertiary.opacity(0.3))
                                            
                                            VStack(spacing: AppleBooksSpacing.space16) {
                                                Text("Premium Features Coming Soon")
                                                    .font(AppleBooksTypography.captionBold)
                                                    .foregroundColor(AppleBooksColors.accent)
                                                
                                                Text("Unlock unlimited access to advanced analytics, unlimited scans, and more – stay tuned!")
                                                    .font(AppleBooksTypography.caption)
                                                    .foregroundColor(AppleBooksColors.textSecondary)
                                                    .multilineTextAlignment(.center)
                                                
                                                Button(action: {
                                                    // Premium coming soon - no action
                                                    print("DEBUG ProfileView: Premium coming soon - view plans button tap ignored")
                                                }) {
                                                    Text("Coming Soon")
                                                        .font(.caption.bold())
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(AppleBooksColors.promotional.opacity(0.7))
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                }
                                                .disabled(true)
                                                .glassBackground()
                                                .opacity(0.6)
                                                .accessibilityLabel("Premium Coming Soon")
                                            }
                                            .padding(.top, AppleBooksSpacing.space8)
                                        }
                                    }
                                }
                                .frame(maxWidth: 350)
                            }
                            .padding(.horizontal, AppleBooksSpacing.space24)
                        }

                        // Settings Options Section
                        VStack(spacing: AppleBooksSpacing.space16) {
                            AppleBooksSectionHeader(
                                title: "Manage your account and preferences",
                                subtitle: nil,
                                showSeeAll: false,
                                seeAllAction: nil
                            )

                            VStack(spacing: AppleBooksSpacing.space16) {
                                NavigationLink(destination: AccountSettingsView()) {
                                    AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                        HStack(spacing: AppleBooksSpacing.space12) {
                                            Image(systemName: "gear")
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.accent)
                                                .frame(width: 24, height: 24)
                                            Text("Account Settings")
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.text)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppleBooksTypography.caption)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                        }
                                    }
                                    .frame(maxWidth: 350)
                                }
                                .buttonStyle(PlainButtonStyle())

                                NavigationLink(destination: ReadingStatsView()) {
                                    AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                        HStack(spacing: AppleBooksSpacing.space12) {
                                            Image(systemName: "chart.bar.fill")
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.success)
                                                .frame(width: 24, height: 24)
                                            Text("Detailed Statistics")
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.text)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppleBooksTypography.caption)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                        }
                                    }
                                    .frame(maxWidth: 350)
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Theme Section
                                AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                    VStack(spacing: AppleBooksSpacing.space12) {
                                        HStack {
                                            Text("Appearance")
                                                .font(AppleBooksTypography.headlineSmall)
                                                .foregroundColor(AppleBooksColors.text)
                                            Spacer()
                                        }

                                        GlassSegmentedPicker(
                                            title: "",
                                            selection: $themeManager.currentPreference,
                                            options: ColorSchemePreference.allCases,
                                            displayText: { $0.rawValue.capitalized },
                                            isMandatory: false
                                        )
                                    }
                                }
                                .frame(maxWidth: 350)

                                // Accent Color Section
                                AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                    VStack(spacing: AppleBooksSpacing.space12) {
                                        HStack {
                                            Text("Accent Color")
                                                .font(AppleBooksTypography.headlineSmall)
                                                .foregroundColor(AppleBooksColors.text)
                                            Spacer()
                                        }

                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppleBooksSpacing.space12) {
                                            ForEach(AccentColorScheme.allCases) { colorScheme in
                                                AccentColorOption(
                                                    colorScheme: colorScheme,
                                                    isSelected: accentColorManager.currentAccentColor == colorScheme
                                                )
                                                .onTapGesture {
                                                    accentColorManager.currentAccentColor = colorScheme
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: 350)

                                // Sign Out
                                Button(action: {
                                    showSignOutAlert = true
                                }) {
                                    AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                        HStack(spacing: AppleBooksSpacing.space12) {
                                            Image(systemName: "arrow.right.square")
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.promotional)
                                                .frame(width: 24, height: 24)
                                            Text("Sign Out")
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.promotional)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(AppleBooksTypography.caption)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                        }
                                    }
                                    .frame(maxWidth: 350)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, AppleBooksSpacing.space24)
                        }

                        // Subscription Management Section (Premium coming soon)
                        if let user = authService.currentUser, user.tier == .free {
                            VStack(spacing: AppleBooksSpacing.space16) {
                                AppleBooksSectionHeader(
                                    title: "Premium Subscription",
                                    subtitle: "Coming Soon",
                                    showSeeAll: false,
                                    seeAllAction: nil
                                )
                        
                                VStack(spacing: AppleBooksSpacing.space16) {
                                    AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                        VStack(spacing: AppleBooksSpacing.space12) {
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 48, weight: .medium))
                                                .foregroundColor(PrimaryColors.vibrantPurple.opacity(0.3))
                                            
                                            Text("Premium Coming Soon")
                                                .font(AppleBooksTypography.headlineMedium)
                                                .foregroundColor(AppleBooksColors.text)
                                                .multilineTextAlignment(.center)
                                            
                                            Text("Stay tuned for unlimited scans, advanced analytics, and exclusive features!")
                                                .font(AppleBooksTypography.bodyMedium)
                                                .foregroundColor(AppleBooksColors.textSecondary)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .frame(maxWidth: 350)

                                    Button(action: {
                                        showUpgradeModal = true
                                    }) {
                                        Text("Upgrade Now")
                                            .font(AppleBooksTypography.buttonLarge)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, AppleBooksSpacing.space16)
                                            .padding(.horizontal, AppleBooksSpacing.space24)
                                            .background(
                                                LinearGradient(
                                                    colors: [PrimaryColors.vibrantPurple, PrimaryColors.vibrantPurple.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .cornerRadius(12)
                                            .shadow(color: PrimaryColors.vibrantPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, AppleBooksSpacing.space24)
                                    .glassBackground()
                                    .accessibilityLabel("Upgrade Now Button")
                                }
                                .padding(.horizontal, AppleBooksSpacing.space24)
                            }
                        }

                        Spacer(minLength: AppleBooksSpacing.space64)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeModalView()
            }
            .animation(.easeInOut(duration: 0.3), value: showUpgradeModal)
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

struct AccentColorOption: View {
    let colorScheme: AccentColorScheme
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(colorScheme.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: colorScheme.color.opacity(0.3), radius: 4, x: 0, y: 2)

            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .frame(width: 50, height: 50)
    }
}

struct ProfilePictureView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showImagePicker = false

    private let userDefaultsKey = "profileImagePath"

    init(authService: AuthService) {
        self._authService = ObservedObject(wrappedValue: authService)
        _selectedImage = State(initialValue: loadImageFromFile())
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
                        .fill(AppleBooksColors.card)
                        .frame(width: 120, height: 120)
                        .shadow(color: AppleBooksShadow.subtle.color, radius: AppleBooksShadow.subtle.radius, x: AppleBooksShadow.subtle.x, y: AppleBooksShadow.subtle.y)

                    Text(initials)
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundColor(AppleBooksColors.text)
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
                            .padding(AppleBooksSpacing.space6)
                            .background(AppleBooksColors.accent)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppleBooksColors.card, lineWidth: 2)
                            )
                            .shadow(color: AppleBooksColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(SpacingSystem.xs)
                }
            }
            .frame(width: 120, height: 120)
        }
        .frame(width: 120, height: 120)
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            print("DEBUG ProfilePictureView: onChange triggered with newItem: \(newItem != nil ? "not nil" : "nil")")
            Task {
                print("DEBUG ProfilePictureView: Starting Task to load transferable")
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    print("DEBUG ProfilePictureView: Loaded transferable data, size: \(data.count) bytes")
                    if let uiImage = UIImage(data: data) {
                        print("DEBUG ProfilePictureView: Created UIImage from data, size: \(uiImage.size)")
                        selectedImage = uiImage
                        saveImageToFile(uiImage)
                    } else {
                        print("DEBUG ProfilePictureView: Failed to create UIImage from data")
                    }
                } else {
                    print("DEBUG ProfilePictureView: Failed to load transferable data")
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

    private func loadImageFromFile() -> UIImage? {
        print("DEBUG ProfilePictureView: loadImageFromFile called")
        guard let path = UserDefaults.standard.string(forKey: userDefaultsKey) else {
            print("DEBUG ProfilePictureView: No path found in UserDefaults for key \(userDefaultsKey)")
            return nil
        }
        print("DEBUG ProfilePictureView: Path from UserDefaults: \(path)")
        let url = URL(fileURLWithPath: path)
        print("DEBUG ProfilePictureView: URL: \(url)")
        do {
            let data = try Data(contentsOf: url)
            print("DEBUG ProfilePictureView: Successfully loaded data, size: \(data.count) bytes")
            guard let image = UIImage(data: data) else {
                print("DEBUG ProfilePictureView: Failed to create UIImage from data")
                return nil
            }
            print("DEBUG ProfilePictureView: Successfully created UIImage, size: \(image.size)")
            return image
        } catch {
            print("DEBUG ProfilePictureView: Error loading image from file: \(error)")
            return nil
        }
    }

    private func saveImageToFile(_ image: UIImage) {
        print("DEBUG ProfilePictureView: saveImageToFile called")
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            print("DEBUG ProfilePictureView: Failed to get JPEG data from image")
            return
        }
        print("DEBUG ProfilePictureView: JPEG data size: \(data.count) bytes")
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("DEBUG ProfilePictureView: Failed to get documents directory URL")
            return
        }
        print("DEBUG ProfilePictureView: Documents URL: \(documentsURL)")
        let fileURL = documentsURL.appendingPathComponent("profile_image.jpg")
        print("DEBUG ProfilePictureView: File URL: \(fileURL)")
        // Remove old file if exists
        if fileManager.fileExists(atPath: fileURL.path) {
            print("DEBUG ProfilePictureView: Removing old file")
            try? fileManager.removeItem(at: fileURL)
        }
        do {
            try data.write(to: fileURL)
            print("DEBUG ProfilePictureView: Successfully wrote data to file")
            UserDefaults.standard.set(fileURL.path, forKey: userDefaultsKey)
            print("DEBUG ProfilePictureView: Set UserDefaults key \(userDefaultsKey) to \(fileURL.path)")
        } catch {
            print("DEBUG ProfilePictureView: Error saving image to file: \(error)")
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

struct EnhancedUsageRow: View {
    let icon: String
    let title: String
    let current: Int
    let limit: Int
    let color: Color
    let showTeaser: Bool
    let onUpgradeTap: () -> Void

    var body: some View {
        VStack(spacing: AppleBooksSpacing.space8) {
            HStack(spacing: AppleBooksSpacing.space12) {
                Image(systemName: icon)
                    .font(AppleBooksTypography.bodyLarge)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                    Text(title)
                        .font(AppleBooksTypography.bodyMedium)
                        .foregroundColor(AppleBooksColors.text)

                    if limit == Int.max {
                        Text("Unlimited")
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(AppleBooksColors.textSecondary)
                    } else {
                        HStack {
                            Text("\(current) / \(limit)")
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(current >= limit ? AppleBooksColors.promotional : AppleBooksColors.textSecondary)

                            if current >= limit {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppleBooksColors.promotional)
                            }
                        }
                    }
                }

                Spacer()

                if limit != Int.max {
                    ProgressView(value: min(Float(current), Float(limit)), total: Float(limit))
                        .progressViewStyle(LinearProgressViewStyle(tint: current >= limit ? AppleBooksColors.promotional : color))
                        .frame(width: 60)
                }
            }

            // Usage teaser when approaching limit
            if showTeaser && limit != Int.max {
                VStack(spacing: AppleBooksSpacing.space6) {
                    HStack(spacing: AppleBooksSpacing.space8) {
                        Image(systemName: current >= limit ? "exclamationmark.triangle.fill" : "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(current >= limit ? SemanticColors.warningPrimary : PrimaryColors.vibrantPurple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(current >= limit ? "Limit reached!" : "Running low on \(title.lowercased())")
                                .font(AppleBooksTypography.captionBold)
                                .foregroundColor(current >= limit ? SemanticColors.warningPrimary : AppleBooksColors.accent)

                            if current < limit {
                                let remaining = limit - current
                                Text("\(remaining) \(title.lowercased()) remaining this month")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                            }
                        }

                        Spacer()

                        Button(action: onUpgradeTap) {
                            Text(current >= limit ? "Upgrade Now" : "Upgrade")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(current >= limit ? Color.orange : Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .glassBackground()
                        .accessibilityLabel("Upgrade Button")
                    }

                    // Urgency message for when very close to limit
                    if current >= limit * 9 / 10 && current < limit {
                        Text("⚡ Don't lose access to \(title.lowercased()) - upgrade before you reach the limit!")
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(SemanticColors.warningPrimary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.top, AppleBooksSpacing.space4)
                .padding(.horizontal, AppleBooksSpacing.space4)
                .background(current >= limit ? SemanticColors.warningSecondary : AppleBooksColors.accent.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
}

struct UsageRow: View {
    let icon: String
    let title: String
    let current: Int
    let limit: Int
    let color: Color

    var body: some View {
        HStack(spacing: AppleBooksSpacing.space12) {
            Image(systemName: icon)
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                Text(title)
                    .font(AppleBooksTypography.bodyMedium)
                    .foregroundColor(AppleBooksColors.text)

                if limit == Int.max {
                    Text("Unlimited")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)
                } else {
                    Text("\(current) / \(limit)")
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(current >= limit ? AppleBooksColors.promotional : AppleBooksColors.textSecondary)
                }
            }

            Spacer()

            if limit != Int.max {
                ProgressView(value: min(Float(current), Float(limit)), total: Float(limit))
                    .progressViewStyle(LinearProgressViewStyle(tint: current >= limit ? AppleBooksColors.promotional : color))
                    .frame(width: 60)
            }
        }
    }
}