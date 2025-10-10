import SwiftUI

struct APISettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var geminiAPIKey: String = ""
    @State private var googleBooksAPIKey: String = ""
    @State private var showSaveAlert = false
    @State private var saveMessage = ""

    var body: some View {
        ZStack {
            // Apple Books background
            AppleBooksColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppleBooksSpacing.space24) {
                    // Header
                    VStack(spacing: AppleBooksSpacing.space16) {
                        Text("API Settings")
                            .font(AppleBooksTypography.displayMedium)
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.center)

                        Text("Configure your API keys for book scanning and recommendations")
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                    .padding(.top, AppleBooksSpacing.space32)

                    // API Keys Section
                    VStack(spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "API Keys",
                            subtitle: "Required for scanning and recommendations",
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        // Gemini API Key
                        AppleBooksCard(padding: AppleBooksSpacing.space16) {
                            VStack(spacing: AppleBooksSpacing.space12) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(AppleBooksTypography.bodyLarge)
                                        .foregroundColor(AppleBooksColors.accent)
                                        .frame(width: 24, height: 24)
                                    Text("Gemini API Key")
                                        .font(AppleBooksTypography.headlineSmall)
                                        .foregroundColor(AppleBooksColors.text)
                                    Spacer()
                                    if SecureConfig.shared.hasValidGeminiKey {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 20))
                                    }
                                }

                                TextField("Enter your Gemini API key", text: $geminiAPIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .privacySensitive()

                                Text("Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                            }
                        }

                        // Google Books API Key
                        AppleBooksCard(padding: AppleBooksSpacing.space16) {
                            VStack(spacing: AppleBooksSpacing.space12) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(AppleBooksTypography.bodyLarge)
                                        .foregroundColor(AppleBooksColors.success)
                                        .frame(width: 24, height: 24)
                                    Text("Google Books API Key")
                                        .font(AppleBooksTypography.headlineSmall)
                                        .foregroundColor(AppleBooksColors.text)
                                    Spacer()
                                    if SecureConfig.shared.hasValidGoogleBooksKey {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 20))
                                    }
                                }

                                TextField("Enter your Google Books API key", text: $googleBooksAPIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .privacySensitive()

                                Text("Get your API key from [Google Cloud Console](https://console.cloud.google.com/apis/credentials)")
                                    .font(AppleBooksTypography.caption)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                            }
                        }

                        // Save Button
                        Button(action: saveAPIKeys) {
                            AppleBooksCard(padding: AppleBooksSpacing.space12) {
                                HStack(spacing: AppleBooksSpacing.space12) {
                                    Image(systemName: "checkmark.circle")
                                        .font(AppleBooksTypography.bodyLarge)
                                        .foregroundColor(AppleBooksColors.card)
                                        .frame(width: 24, height: 24)
                                    Text("Save API Keys")
                                        .font(AppleBooksTypography.bodyLarge)
                                        .foregroundColor(AppleBooksColors.card)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(AppleBooksTypography.caption)
                                        .foregroundColor(AppleBooksColors.card)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)

                    // Information Section
                    VStack(spacing: AppleBooksSpacing.space16) {
                        AppleBooksSectionHeader(
                            title: "How to Get API Keys",
                            subtitle: nil,
                            showSeeAll: false,
                            seeAllAction: nil
                        )

                        AppleBooksCard(padding: AppleBooksSpacing.space16) {
                            VStack(spacing: AppleBooksSpacing.space12) {
                                Text("**Gemini API Key:**")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.text)
                                Text("1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Text("2. Sign in with your Google account")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Text("3. Create a new API key")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Text("4. Copy and paste the key above")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                            }
                        }

                        AppleBooksCard(padding: AppleBooksSpacing.space16) {
                            VStack(spacing: AppleBooksSpacing.space12) {
                                Text("**Google Books API Key:**")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.text)
                                Text("1. Visit [Google Cloud Console](https://console.cloud.google.com/apis/credentials)")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Text("2. Create or select a project")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Text("3. Enable the Google Books API")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Text("4. Create credentials (API key)")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                                Text("5. Copy and paste the key above")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)

                    Spacer(minLength: AppleBooksSpacing.space64)
                }
            }
        }
        .navigationTitle("API Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadCurrentKeys()
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text("API Keys Saved"),
                message: Text(saveMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func loadCurrentKeys() {
        // Load existing keys (they will be masked or empty for security)
        // We don't pre-fill the text fields for security reasons
        geminiAPIKey = ""
        googleBooksAPIKey = ""
    }

    private func saveAPIKeys() {
        var savedKeys: [String] = []

        if !geminiAPIKey.isEmpty {
            SecureConfig.shared.setGeminiAPIKey(geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines))
            savedKeys.append("Gemini")
        }

        if !googleBooksAPIKey.isEmpty {
            SecureConfig.shared.setGoogleBooksAPIKey(googleBooksAPIKey.trimmingCharacters(in: .whitespacesAndNewlines))
            savedKeys.append("Google Books")
        }

        if savedKeys.isEmpty {
            saveMessage = "No API keys were entered. Please enter at least one API key."
        } else {
            saveMessage = "\(savedKeys.joined(separator: " and ")) API key(s) saved successfully."
            // Clear the text fields after saving
            geminiAPIKey = ""
            googleBooksAPIKey = ""
        }

        showSaveAlert = true
    }
}