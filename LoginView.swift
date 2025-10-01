import SwiftUI


struct LoginView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp: Bool
    @State private var isLoading = false
    @State private var showPasswordReset = false
    @State private var animateForm = false
    @State private var showMoreFields = false

    // Additional signup fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var gender = ""
    @State private var phone = ""
    @State private var country = ""
    @State private var city = ""
    @State private var favoriteBookGenre = ""
    @State private var showWaitlistModal = false
    @State private var selectedTier: UserTier? = nil
    @State private var selectedPeriod: SubscriptionPeriod = SubscriptionPeriod(unit: .month)
    
    init(isSignUp: Bool = false) {
        _isSignUp = State(initialValue: isSignUp)
    }

    var body: some View {
        ZStack {
            // Clean Apple Books background
            AppleBooksColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppleBooksSpacing.space32) {
                    Spacer(minLength: AppleBooksSpacing.space64)

                    // Clean App Logo/Title
                    VStack(spacing: AppleBooksSpacing.space16) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppleBooksColors.accent, AppleBooksColors.accent.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .scaleEffect(animateForm ? 1.0 : 0.8)
                            .animation(AnimationTiming.transition.delay(0.3), value: animateForm)

                        VStack(spacing: AppleBooksSpacing.space8) {
                            Text("Book Shelfie")
                                .font(AppleBooksTypography.displayMedium)
                                .foregroundColor(AppleBooksColors.text)

                            Text("Digitize your library with AI")
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.textSecondary)
                        }
                    }
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(AnimationTiming.transition.delay(0.2), value: animateForm)

                    if isSignUp {
                        ExpandableTierSelection(selectedTier: $selectedTier, selectedPeriod: $selectedPeriod, showWaitlistModal: $showWaitlistModal)
                        .padding(.horizontal, AppleBooksSpacing.space24)
                        .padding(.bottom, AppleBooksSpacing.space16)
                    }

                    if !isSignUp || (isSignUp && selectedTier == .free) {
                        // Clean Login/Signup Form
                        AppleBooksCard(
                            cornerRadius: 16,
                            padding: AppleBooksSpacing.space24,
                            shadowStyle: .subtle
                        ) {
                            VStack(spacing: AppleBooksSpacing.space20) {
                                // Form Header
                                VStack(spacing: AppleBooksSpacing.space8) {
                                    Text(isSignUp ? "Create Account" : "Welcome Back")
                                        .font(AppleBooksTypography.headlineLarge)
                                        .foregroundColor(AppleBooksColors.text)

                                    Text(isSignUp ? "Join our reading community" : "Sign in to your account")
                                        .font(AppleBooksTypography.bodyMedium)
                                        .foregroundColor(AppleBooksColors.textSecondary)
                                }

                            // Email Field
                            VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                HStack {
                                    Text("Email")
                                        .font(AppleBooksTypography.headlineSmall)
                                        .foregroundColor(AppleBooksColors.text)
                                    Text("*")
                                        .foregroundColor(AppleBooksColors.promotional)
                                        .font(AppleBooksTypography.headlineSmall)
                                }

                                TextField("Enter your email", text: $email)
                                    .font(AppleBooksTypography.bodyLarge)
                                    .foregroundColor(AppleBooksColors.text)
                                    .padding(AppleBooksSpacing.space12)
                                    .background(AppleBooksColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                HStack {
                                    Text("Password")
                                        .font(AppleBooksTypography.headlineSmall)
                                        .foregroundColor(AppleBooksColors.text)
                                    if isSignUp {
                                        Text("*")
                                            .foregroundColor(AppleBooksColors.promotional)
                                            .font(AppleBooksTypography.headlineSmall)
                                    }
                                }

                                SecureField("Enter your password", text: $password)
                                    .font(AppleBooksTypography.bodyLarge)
                                    .foregroundColor(AppleBooksColors.text)
                                    .padding(AppleBooksSpacing.space12)
                                    .background(AppleBooksColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .textContentType(isSignUp ? .newPassword : .password)
                            }

                            // Required Name Fields (only for signup and free tier)
                            if isSignUp && selectedTier == .free {
                                HStack(spacing: AppleBooksSpacing.space12) {
                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        HStack {
                                            Text("First Name")
                                                .font(AppleBooksTypography.headlineSmall)
                                                .foregroundColor(AppleBooksColors.text)
                                            Text("*")
                                                .foregroundColor(AppleBooksColors.promotional)
                                                .font(AppleBooksTypography.headlineSmall)
                                        }

                                        TextField("Enter first name", text: $firstName)
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.text)
                                            .padding(AppleBooksSpacing.space12)
                                            .background(AppleBooksColors.background)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .textContentType(.givenName)
                                    }

                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        HStack {
                                            Text("Last Name")
                                            .font(AppleBooksTypography.headlineSmall)
                                            .foregroundColor(AppleBooksColors.text)
                                            Text("*")
                                                .foregroundColor(AppleBooksColors.promotional)
                                                .font(AppleBooksTypography.headlineSmall)
                                        }

                                        TextField("Enter last name", text: $lastName)
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.text)
                                            .padding(AppleBooksSpacing.space12)
                                            .background(AppleBooksColors.background)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .textContentType(.familyName)
                                    }
                                }
                            }

                            // Show More Button (only for signup and free tier)
                            if isSignUp && selectedTier == .free {
                                Button(action: {
                                    withAnimation(AnimationTiming.transition) {
                                        showMoreFields.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text(showMoreFields ? "Show Less" : "Show More")
                                            .font(AppleBooksTypography.bodyMedium)
                                            .foregroundColor(AppleBooksColors.accent)
                                        Image(systemName: showMoreFields ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppleBooksColors.accent)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppleBooksSpacing.space8)
                                }
                            }

                            // Additional Fields (shown when expanded and free tier)
                            if isSignUp && showMoreFields && selectedTier == .free {
                                VStack(spacing: AppleBooksSpacing.space16) {

                                    // Date of Birth
                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        Text("Date of Birth")
                                            .font(AppleBooksTypography.headlineSmall)
                                            .foregroundColor(AppleBooksColors.text)

                                        DatePicker("Select date of birth", selection: $dateOfBirth, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.text)
                                            .padding(AppleBooksSpacing.space12)
                                            .background(AppleBooksColors.background)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }

                                    // Gender
                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        Text("Gender")
                                            .font(AppleBooksTypography.headlineSmall)
                                            .foregroundColor(AppleBooksColors.text)

                                        Picker("Select gender", selection: $gender) {
                                            Text("Prefer not to say").tag("")
                                            Text("Male").tag("Male")
                                            Text("Female").tag("Female")
                                            Text("Non-binary").tag("Non-binary")
                                            Text("Other").tag("Other")
                                        }
                                        .pickerStyle(.menu)
                                        .font(AppleBooksTypography.bodyLarge)
                                        .foregroundColor(AppleBooksColors.text)
                                        .padding(AppleBooksSpacing.space12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppleBooksColors.background)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }

                                    // Phone
                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        Text("Phone")
                                            .font(AppleBooksTypography.headlineSmall)
                                            .foregroundColor(AppleBooksColors.text)

                                        TextField("Enter phone number", text: $phone)
                                            .font(AppleBooksTypography.bodyLarge)
                                            .foregroundColor(AppleBooksColors.text)
                                            .padding(AppleBooksSpacing.space12)
                                            .background(AppleBooksColors.background)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .keyboardType(.phonePad)
                                            .textContentType(.telephoneNumber)
                                    }

                                    // Country & City
                                    HStack(spacing: AppleBooksSpacing.space12) {
                                        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                            Text("Country")
                                                .font(AppleBooksTypography.headlineSmall)
                                                .foregroundColor(AppleBooksColors.text)

                                            TextField("Enter country", text: $country)
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.text)
                                                .padding(AppleBooksSpacing.space12)
                                                .background(AppleBooksColors.background)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .textContentType(.countryName)
                                        }

                                        VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                            Text("City")
                                                .font(AppleBooksTypography.headlineSmall)
                                                .foregroundColor(AppleBooksColors.text)

                                            TextField("Enter city", text: $city)
                                                .font(AppleBooksTypography.bodyLarge)
                                                .foregroundColor(AppleBooksColors.text)
                                                .padding(AppleBooksSpacing.space12)
                                                .background(AppleBooksColors.background)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                            .textContentType(.addressCity)
                                        }
                                    }

                                    // Favorite Book Genre
                                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                                        Text("Favorite Book Genre")
                                            .font(AppleBooksTypography.headlineSmall)
                                            .foregroundColor(AppleBooksColors.text)

                                        Picker("Select favorite genre", selection: $favoriteBookGenre) {
                                            Text("Not specified").tag("")
                                            Text("Fiction").tag("Fiction")
                                            Text("Non-Fiction").tag("Non-Fiction")
                                            Text("Mystery").tag("Mystery")
                                            Text("Romance").tag("Romance")
                                            Text("Science Fiction").tag("Science Fiction")
                                            Text("Fantasy").tag("Fantasy")
                                            Text("Biography").tag("Biography")
                                            Text("History").tag("History")
                                            Text("Self-Help").tag("Self-Help")
                                            Text("Other").tag("Other")
                                        }
                                        .pickerStyle(.menu)
                                        .font(AppleBooksTypography.bodyLarge)
                                        .foregroundColor(AppleBooksColors.text)
                                        .padding(AppleBooksSpacing.space12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppleBooksColors.background)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                                .transition(.slide)
                            }

                            // Sign In/Sign Up Button (only for login or free signup)
                            if !(isSignUp && selectedTier == .premium) {
                                Button(action: {
                                    if isSignUp {
                                        signUp()
                                    } else {
                                        signIn()
                                    }
                                }) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppleBooksColors.card))
                                            .scaleEffect(1.2)
                                    } else {
                                        Text(isSignUp ? "Create Account" : "Sign In")
                                            .font(AppleBooksTypography.buttonLarge)
                                            .foregroundColor(AppleBooksColors.card)
                                            .frame(maxWidth: .infinity)
                                            .padding(AppleBooksSpacing.space16)
                                            .background(AppleBooksColors.accent)
                                            .cornerRadius(12)
                                    }
                                }
                                .disabled(isLoading)
                            }

                            // Toggle between login and signup
                            Button(action: {
                                withAnimation(AnimationTiming.transition) {
                                    isSignUp.toggle()
                                }
                            }) {
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.accent)
                            }

                            // Forgot password
                            if !isSignUp {
                                Button(action: {
                                    showPasswordReset = true
                                }) {
                                    Text("Forgot Password?")
                                        .font(AppleBooksTypography.caption)
                                        .foregroundColor(AppleBooksColors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppleBooksSpacing.space24)
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(AnimationTiming.transition.delay(0.4), value: animateForm)
                    }

                    // Error message
                    if let error = authService.errorMessage {
                        AppleBooksCard(
                            cornerRadius: 12,
                            padding: AppleBooksSpacing.space16,
                            backgroundColor: AppleBooksColors.promotional.opacity(0.1),
                            shadowStyle: .subtle
                        ) {
                            HStack(spacing: AppleBooksSpacing.space12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppleBooksColors.promotional)
                                    .font(.system(size: 20, weight: .semibold))

                                Text(error)
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.text)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal, AppleBooksSpacing.space24)
                        .transition(.scale.combined(with: .opacity))
                        .animation(AnimationTiming.feedback, value: authService.errorMessage)
                    }

                    Spacer(minLength: AppleBooksSpacing.space64)
                }
            }
        }
        .onAppear {
            withAnimation(AnimationTiming.transition.delay(0.1)) {
                animateForm = true
            }
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
        .sheet(isPresented: $showWaitlistModal) {
            WaitlistModal(
                initialFirstName: firstName,
                initialLastName: lastName,
                initialEmail: email,
                initialUserId: nil
            )
        }
    }

    private func signIn() {
        print("LoginView: Sign in started for email: \(email)")
        isLoading = true
        authService.signIn(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success:
                print("LoginView: Sign in success")
                // Navigation will be handled by the parent view
                break
            case .failure:
                print("LoginView: Sign in failure")
                // Error is handled by the auth service
                break
            }
        }
    }

    private func signUp() {
        // Validate required fields
        guard !email.isEmpty else {
            authService.errorMessage = "Email is required"
            return
        }
        guard !password.isEmpty else {
            authService.errorMessage = "Password is required"
            return
        }
        guard !firstName.isEmpty else {
            authService.errorMessage = "First name is required"
            return
        }
        guard !lastName.isEmpty else {
            authService.errorMessage = "Last name is required"
            return
        }

        guard let tier = selectedTier else {
            authService.errorMessage = "Please select a tier"
            return
        }

        isLoading = true
        authService.signUp(
            email: email,
            password: password,
            firstName: firstName.isEmpty ? nil : firstName,
            lastName: lastName.isEmpty ? nil : lastName,
            dateOfBirth: showMoreFields ? dateOfBirth : nil,
            gender: gender.isEmpty ? nil : gender,
            phone: phone.isEmpty ? nil : phone,
            country: country.isEmpty ? nil : country,
            city: city.isEmpty ? nil : city,
            favoriteBookGenre: favoriteBookGenre.isEmpty ? nil : favoriteBookGenre,
            tier: tier
        ) { result in
            isLoading = false
            switch result {
            case .success:
                // Navigation will be handled by the parent view
                break
            case .failure:
                // Error is handled by the auth service
                break
            }
        }
    }
}

struct PasswordResetView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var animateContent = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Enhanced background matching login view
            BackgroundGradients.heroGradient
                .ignoresSafeArea()

            VStack(spacing: SpacingSystem.xl) {
                Spacer()

                // Enhanced Header with close button
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(SpacingSystem.sm)
                            .background(AdaptiveColors.glassBackground)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AdaptiveColors.glassBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, SpacingSystem.lg)

                // Enhanced Main content card
                VStack(spacing: SpacingSystem.xl) {
                    // Enhanced Icon and title
                    VStack(spacing: SpacingSystem.lg) {
                        ZStack {
                            Circle()
                                .fill(PrimaryColors.dynamicOrange.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .blur(radius: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 100, height: 100)
                                )

                            Image(systemName: "key.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .shadow(color: PrimaryColors.dynamicOrange.opacity(0.4), radius: 16, x: 0, y: 8)

                        VStack(spacing: SpacingSystem.sm) {
                            Text("Reset Password")
                                .font(TypographySystem.displaySmall)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)

                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }

                    // Enhanced Email field
                    VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                        Text("Email")
                            .font(TypographySystem.headlineSmall)
                            .foregroundColor(.white.opacity(0.9))

                        TextField("Enter your email address", text: $email)
                            .font(TypographySystem.bodyMedium)
                            .foregroundColor(AdaptiveColors.primaryText)
                            .glassFieldStyle(isValid: !email.isEmpty || email.isEmpty)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                    }

                    // Enhanced Send reset link button
                    Button(action: {
                        resetPassword()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            HStack(spacing: SpacingSystem.sm) {
                                Text("Send Reset Link")
                                    .font(TypographySystem.buttonLarge)
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                    .buttonStyle(LiquidButtonStyle(
                        background: LinearGradient(colors: [Color.white], startPoint: .leading, endPoint: .trailing),
                        foregroundColor: PrimaryColors.dynamicOrange,
                        cornerRadius: 16,
                        padding: EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24),
                        font: TypographySystem.buttonLarge,
                        shadow: (color: Color.white.opacity(0.3), radius: 12, x: 0, y: 6)
                    ))

                    // Enhanced Success/error message
                    if !message.isEmpty {
                        HStack(spacing: SpacingSystem.md) {
                            Image(systemName: message.contains("sent") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(message.contains("sent") ? SemanticColors.successPrimary : SemanticColors.errorPrimary)
                                .font(.system(size: 24, weight: .semibold))

                            Text(message)
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(SpacingSystem.md)
                        .background(message.contains("sent") ? SemanticColors.successSecondary : SemanticColors.errorSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke((message.contains("sent") ? SemanticColors.successPrimary : SemanticColors.errorPrimary).opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .transition(.scale.combined(with: .opacity))
                        .animation(AnimationTiming.feedback, value: message)
                    }
                }
                .padding(SpacingSystem.xl)
                .featureCardStyle()
                .padding(.horizontal, SpacingSystem.lg)
                .offset(y: animateContent ? 0 : 50)
                .opacity(animateContent ? 1 : 0)
                .animation(AnimationTiming.transition.delay(0.2), value: animateContent)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(AnimationTiming.transition.delay(0.1)) {
                animateContent = true
            }
        }
    }

    private func resetPassword() {
        isLoading = true
        AuthService.shared.resetPassword(email: email) { result in
            isLoading = false
            withAnimation(.spring()) {
                switch result {
                case .success:
                    message = "Password reset email sent! Check your inbox."
                case .failure(let error):
                    message = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Mobile-First Expandable Tier Selection

struct ExpandableTierSelection: View {
    @Binding var selectedTier: UserTier?
    @Binding var selectedPeriod: SubscriptionPeriod
    @Binding var showWaitlistModal: Bool
    @State private var expandedTier: UserTier? = nil
    private let premiumFeatures = [
        "Unlimited scans",
        "Unlimited books",
        "Unlimited AI recommendations",
        "Advanced reading analytics",
        "Priority support"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppleBooksSpacing.space16) {
            Text("Choose Your Plan")
                .font(AppleBooksTypography.headlineSmall)
                .foregroundColor(AppleBooksColors.text)

            VStack(spacing: AppleBooksSpacing.space12) {
                // Free Tier Button
                ExpandableTierButton(
                    tier: .free,
                    icon: "📚",
                    title: "Free - Get Started",
                    badge: "FREE",
                    badgeColor: Color.gray,
                    pricing: nil,
                    features: [
                        "20 scans per month",
                        "25 books in library",
                        "5 AI recommendations",
                        "Basic reading insights"
                    ],
                    selectedTier: $selectedTier,
                    expandedTier: $expandedTier,
                    showWaitlistModal: $showWaitlistModal
                )

                // Premium Tier Button
                ExpandableTierButton(
                    tier: .premium,
                    icon: "👑",
                    title: "Premium",
                    badge: "PREMIUM",
                    badgeColor: AppleBooksColors.accent,
                    pricing: nil,
                    features: premiumFeatures,
                    selectedTier: $selectedTier,
                    expandedTier: $expandedTier,
                    showWaitlistModal: $showWaitlistModal
                )
            }
        }
    }
}

struct ExpandableTierButton: View {
    let tier: UserTier
    let icon: String
    let title: String
    let badge: String
    let badgeColor: Color
    let pricing: String?
    let pricingSubtext: String?
    let features: [String]
    @Binding var selectedTier: UserTier?
    @Binding var expandedTier: UserTier?
    @Binding var selectedPeriod: SubscriptionPeriod
    @Binding var showWaitlistModal: Bool

    // Initialize with optional pricing subtext and period
    init(tier: UserTier, icon: String, title: String, badge: String, badgeColor: Color, pricing: String? = nil, pricingSubtext: String? = nil, features: [String], selectedTier: Binding<UserTier?>, expandedTier: Binding<UserTier?>, selectedPeriod: Binding<SubscriptionPeriod> = .constant(SubscriptionPeriod(unit: .month)), showWaitlistModal: Binding<Bool>) {
        self.tier = tier
        self.icon = icon
        self.title = title
        self.badge = badge
        self.badgeColor = badgeColor
        self.pricing = pricing
        self.pricingSubtext = pricingSubtext
        self.features = features
        self._selectedTier = selectedTier
        self._expandedTier = expandedTier
        self._selectedPeriod = selectedPeriod
        self._showWaitlistModal = showWaitlistModal
    }
    
    private var isSelected: Bool { selectedTier == tier }
    private var isExpanded: Bool { expandedTier == tier }
    private var isPremium: Bool { tier == .premium }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Button
            Button(action: {
                withAnimation(AnimationTiming.transition) {
                    if selectedTier == tier && isExpanded {
                        // Deselect
                        selectedTier = nil
                        expandedTier = nil
                    } else {
                        // Select and expand
                        selectedTier = tier
                        expandedTier = tier
                    }
                }
            }) {
                HStack(spacing: AppleBooksSpacing.space12) {
                    // Icon
                    Text(icon)
                        .font(.system(size: 28))
                    
                    // Title and Badge
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space4) {
                        Text(title)
                            .font(AppleBooksTypography.headlineMedium)
                            .foregroundColor(buttonTextColor)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(badge)
                                .font(AppleBooksTypography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppleBooksSpacing.space8)
                                .padding(.vertical, AppleBooksSpacing.space4)
                                .background(badgeColor)
                                .cornerRadius(8)
                            
                            if let pricing = pricing {
                                Text(pricing)
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(buttonTextColor)
                                    .bold()
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    // Selection Indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? AppleBooksColors.accent : Color.gray.opacity(0.4), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(AppleBooksColors.accent)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .padding(AppleBooksSpacing.space16)
                .background(buttonBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(buttonBorderColor, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(
                    color: buttonShadowColor,
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Features Section
            if isExpanded {
                VStack(alignment: .leading, spacing: AppleBooksSpacing.space12) {
                    // Features List
                    VStack(alignment: .leading, spacing: AppleBooksSpacing.space8) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: AppleBooksSpacing.space8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppleBooksColors.success)

                                Text(feature)
                                    .font(AppleBooksTypography.bodyMedium)
                                    .foregroundColor(AppleBooksColors.text)

                                Spacer()
                            }
                        }
                    }

                    // Waitlist Button for Premium
                    if isPremium {
                        Button(action: {
                            showWaitlistModal = true
                        }) {
                            Text("Join Waitlist")
                                .font(AppleBooksTypography.buttonLarge)
                                .foregroundColor(AppleBooksColors.card)
                                .frame(maxWidth: .infinity)
                                .padding(AppleBooksSpacing.space16)
                                .background(AppleBooksColors.accent)
                                .cornerRadius(12)
                        }
                    }

                    // Pricing Subtext for Premium
                    if let pricingSubtext = pricingSubtext {
                        Text(pricingSubtext)
                            .font(AppleBooksTypography.caption)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .padding(.top, AppleBooksSpacing.space4)
                    }
                }
                .padding(AppleBooksSpacing.space16)
                .background(AppleBooksColors.card)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, AppleBooksSpacing.space8)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top)),
                    removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top))
                ))
            }
        }
    }
    
    // MARK: - Computed Properties for Styling
    
    private var buttonBackground: LinearGradient {
        if isSelected && isPremium {
            return LinearGradient(
                colors: [
                    AppleBooksColors.accent,
                    AppleBooksColors.accent.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isSelected {
            return LinearGradient(
                colors: [
                    AppleBooksColors.accent.opacity(0.1),
                    AppleBooksColors.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppleBooksColors.card, AppleBooksColors.card],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var buttonTextColor: Color {
        if isSelected && isPremium {
            return .white
        } else {
            return AppleBooksColors.text
        }
    }
    
    private var buttonBorderColor: Color {
        if isSelected {
            return isPremium ? Color.clear : AppleBooksColors.accent
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var buttonShadowColor: Color {
        if isSelected {
            return AppleBooksColors.accent.opacity(isPremium ? 0.4 : 0.2)
        } else {
            return Color.black.opacity(0.05)
        }
    }
}

// MARK: - Period Selector Card Component

struct PeriodSelectorCard: View {
    let period: SubscriptionPeriod
    let price: Double
    let priceLabel: String
    let savings: String?
    let monthlyEquivalent: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppleBooksSpacing.space8) {
                // Savings Badge
                if let savings = savings {
                    Text(savings)
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppleBooksSpacing.space8)
                        .padding(.vertical, AppleBooksSpacing.space4)
                        .background(AppleBooksColors.success)
                        .cornerRadius(8)
                } else {
                    Spacer(minLength: 24) // Balance height
                }
                
                // Price
                Text("$\(String(format: "%.2f", price))")
                    .font(AppleBooksTypography.headlineLarge)
                    .foregroundColor(AppleBooksColors.text)
                    .bold()
                
                // Period Label
                Text("per \(priceLabel)")
                    .font(AppleBooksTypography.caption)
                    .foregroundColor(AppleBooksColors.textSecondary)
                
                // Monthly Equivalent for Yearly
                if let monthlyEquivalent = monthlyEquivalent {
                    Text(monthlyEquivalent)
                        .font(AppleBooksTypography.caption)
                        .foregroundColor(AppleBooksColors.textSecondary)
                } else {
                    Spacer(minLength: 16) // Balance height
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(AppleBooksSpacing.space12)
            .background(
                isSelected ?
                AppleBooksColors.accent.opacity(0.1) :
                AppleBooksColors.background
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AppleBooksColors.accent : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? AppleBooksColors.accent.opacity(0.2) : Color.clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Components for Enhanced Tier Selection

struct TierFeatureRow: View {
    let text: String
    let isSelected: Bool
    let isPremium: Bool

    init(text: String, isSelected: Bool, isPremium: Bool = false) {
        self.text = text
        self.isSelected = isSelected
        self.isPremium = isPremium
    }

    var body: some View {
        HStack(spacing: AppleBooksSpacing.space8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(
                    isSelected ?
                    (isPremium ? .white : AppleBooksColors.accent) :
                    AppleBooksColors.success
                )

            Text(text)
                .font(AppleBooksTypography.caption)
                .foregroundColor(
                    isSelected ?
                    (isPremium ? .white.opacity(0.9) : AppleBooksColors.text) :
                    AppleBooksColors.textSecondary
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
