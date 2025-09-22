import SwiftUI

struct LoginView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender = "Prefer not to say"
    @State private var phone = ""
    @State private var country = ""
    @State private var city = ""
    @State private var favoriteBookGenre = ""
    @State private var showAdditionalFields = false
    @State private var isSignUp: Bool
    @State private var isLoading = false
    @State private var showPasswordReset = false
    @State private var animateForm = false
    @State private var hasShownAdditionalFields = false

    init(isSignUp: Bool = false) {
        _isSignUp = State(initialValue: isSignUp)
    }

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]

    var body: some View {
        ZStack {
            // Enhanced vibrant background gradient
            BackgroundGradients.heroGradient
                .ignoresSafeArea()

            // Enhanced animated floating elements
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .blur(radius: 40)
                    .offset(x: animateForm ? 20 : -20)
                    .animation(.easeInOut(duration: 4).repeatForever(), value: animateForm)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: geometry.size.width * 0.6)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
                    .blur(radius: 30)
                    .offset(y: animateForm ? -15 : 15)
                    .animation(.easeInOut(duration: 3).repeatForever(), value: animateForm)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: geometry.size.width * 0.4)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
                    .blur(radius: 25)
                    .offset(x: animateForm ? -10 : 10, y: animateForm ? 10 : -10)
                    .animation(.easeInOut(duration: 5).repeatForever(), value: animateForm)
            }

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 64)

                    // Enhanced App Logo/Title with vibrant glass effect
                    VStack(spacing: SpacingSystem.lg) {
                        ZStack {
                            Circle()
                                .fill(PrimaryColors.energeticPink.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .blur(radius: 15)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 120, height: 120)
                                )

                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 56, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                                .scaleEffect(animateForm ? 1.0 : 0.8)
                                .animation(AnimationTiming.transition.delay(0.3), value: animateForm)
                        }
                        .shadow(color: PrimaryColors.energeticPink.opacity(0.4), radius: 20, x: 0, y: 10)

                        VStack(spacing: SpacingSystem.sm) {
                            Text("Bookshelf Scanner")
                                .font(TypographySystem.displayMedium)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)

                            Text("Digitize your library with AI")
                                .font(TypographySystem.bodyLarge)
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        }
                    }
                    .padding(SpacingSystem.xl)
                    .featureCardStyle()
                    .padding(.horizontal, SpacingSystem.lg)
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(AnimationTiming.transition.delay(0.2), value: animateForm)

                    // Enhanced Login/Signup Form
                    VStack(spacing: SpacingSystem.lg) {
                        // Enhanced Form Header
                        VStack(spacing: SpacingSystem.sm) {
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(TypographySystem.displaySmall)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)

                            Text(isSignUp ? "Join our reading community" : "Sign in to your account")
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.bottom, SpacingSystem.md)

                        // Enhanced Email Field
                        VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                            HStack {
                                Text("Email")
                                    .font(TypographySystem.headlineSmall)
                                    .foregroundColor(.white.opacity(0.9))
                                Text("*")
                                    .foregroundColor(SemanticColors.errorPrimary)
                                    .font(TypographySystem.headlineSmall)
                            }

                            TextField("Enter your email", text: $email)
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(AdaptiveColors.primaryText)
                                .glassFieldStyle(isValid: !email.isEmpty || email.isEmpty)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                        }

                        if isSignUp {
                            // Enhanced First Name Field
                            VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                HStack {
                                    Text("First Name")
                                        .font(TypographySystem.headlineSmall)
                                        .foregroundColor(.white.opacity(0.9))
                                    Text("*")
                                        .foregroundColor(SemanticColors.errorPrimary)
                                        .font(TypographySystem.headlineSmall)
                                }

                                TextField("Enter your first name", text: $firstName)
                                    .font(TypographySystem.bodyMedium)
                                    .foregroundColor(AdaptiveColors.primaryText)
                                    .glassFieldStyle(isValid: !firstName.isEmpty || firstName.isEmpty)
                                    .textContentType(.givenName)
                            }

                            // Enhanced Last Name Field
                            VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                HStack {
                                    Text("Last Name")
                                        .font(TypographySystem.headlineSmall)
                                        .foregroundColor(.white.opacity(0.9))
                                    Text("*")
                                        .foregroundColor(SemanticColors.errorPrimary)
                                        .font(TypographySystem.headlineSmall)
                                }

                                TextField("Enter your last name", text: $lastName)
                                    .font(TypographySystem.bodyMedium)
                                    .foregroundColor(AdaptiveColors.primaryText)
                                    .glassFieldStyle(isValid: !lastName.isEmpty || lastName.isEmpty)
                                    .textContentType(.familyName)
                            }

                            // Enhanced Date of Birth Field
                            VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                HStack {
                                    Text("Date of Birth")
                                        .font(TypographySystem.headlineSmall)
                                        .foregroundColor(.white.opacity(0.9))
                                    Text("*")
                                        .foregroundColor(SemanticColors.errorPrimary)
                                        .font(TypographySystem.headlineSmall)
                                }

                                GlassDatePicker(title: "", date: $dateOfBirth, isMandatory: true)
                            }

                            // Enhanced Gender Field
                            VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                Text("Gender")
                                    .font(TypographySystem.headlineSmall)
                                    .foregroundColor(.white.opacity(0.9))

                                GlassSegmentedPicker(
                                    title: "",
                                    selection: $gender,
                                    options: genderOptions,
                                    displayText: { $0 }
                                )
                            }

                            // Enhanced Additional Fields (shown when expanded)
                            if showAdditionalFields {
                                VStack(spacing: SpacingSystem.md) {
                                    // Phone Number Field
                                    VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                        Text("Phone Number")
                                            .font(TypographySystem.headlineSmall)
                                            .foregroundColor(.white.opacity(0.9))

                                        TextField("Enter your phone number", text: $phone)
                                            .font(TypographySystem.bodyMedium)
                                            .foregroundColor(AdaptiveColors.primaryText)
                                            .glassFieldStyle()
                                            .keyboardType(.phonePad)
                                            .textContentType(.telephoneNumber)
                                    }

                                    // Country Field
                                    VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                        Text("Country")
                                            .font(TypographySystem.headlineSmall)
                                            .foregroundColor(.white.opacity(0.9))

                                        TextField("Enter your country", text: $country)
                                            .font(TypographySystem.bodyMedium)
                                            .foregroundColor(AdaptiveColors.primaryText)
                                            .glassFieldStyle()
                                            .textContentType(.countryName)
                                    }

                                    // City Field
                                    VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                        Text("City")
                                            .font(TypographySystem.headlineSmall)
                                            .foregroundColor(.white.opacity(0.9))

                                        TextField("Enter your city", text: $city)
                                            .font(TypographySystem.bodyMedium)
                                            .foregroundColor(AdaptiveColors.primaryText)
                                            .glassFieldStyle()
                                            .textContentType(.addressCity)
                                    }

                                    // Favorite Book Genre Field
                                    VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                                        Text("Favorite Book Genre")
                                            .font(TypographySystem.headlineSmall)
                                            .foregroundColor(.white.opacity(0.9))

                                        TextField("e.g., Fiction, Mystery, Romance", text: $favoriteBookGenre)
                                            .font(TypographySystem.bodyMedium)
                                            .foregroundColor(AdaptiveColors.primaryText)
                                            .glassFieldStyle()
                                    }
                                }
                                .transition(.slide.combined(with: .opacity))
                            }
                        }

                        // Enhanced Password Field
                        VStack(alignment: .leading, spacing: SpacingSystem.sm) {
                            HStack {
                                Text("Password")
                                    .font(TypographySystem.headlineSmall)
                                    .foregroundColor(.white.opacity(0.9))
                                if isSignUp {
                                    Text("*")
                                        .foregroundColor(SemanticColors.errorPrimary)
                                        .font(TypographySystem.headlineSmall)
                                }
                            }

                            SecureField("Enter your password", text: $password)
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(AdaptiveColors.primaryText)
                                .glassFieldStyle(isValid: !password.isEmpty || password.isEmpty)
                                .textContentType(isSignUp ? .newPassword : .password)
                        }

                        if isSignUp {
                            // Enhanced Show More Button
                            Button(action: {
                                withAnimation(AnimationTiming.transition) {
                                    showAdditionalFields.toggle()
                                    if showAdditionalFields {
                                        hasShownAdditionalFields = true
                                    }
                                }
                            }) {
                                HStack(spacing: SpacingSystem.sm) {
                                    Text(showAdditionalFields ? "Show Less Options" : "Show More Options")
                                        .font(TypographySystem.bodyMedium)
                                    Image(systemName: showAdditionalFields ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(PrimaryColors.electricBlue)
                            }
                            .padding(.top, SpacingSystem.sm)
                        }

                        // Enhanced Sign In/Sign Up Button
                        Button(action: {
                            if isSignUp {
                                signUp()
                            } else {
                                signIn()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                HStack(spacing: SpacingSystem.sm) {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(TypographySystem.buttonLarge)
                                    Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .primaryButtonStyle()
                        .disabled(isLoading)

                        // Enhanced Toggle between login and signup
                        Button(action: {
                            withAnimation(AnimationTiming.transition) {
                                isSignUp.toggle()
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(PrimaryColors.energeticPink)
                        }

                        // Enhanced Forgot password
                        if !isSignUp {
                            Button(action: {
                                showPasswordReset = true
                            }) {
                                Text("Forgot Password?")
                                    .font(TypographySystem.captionLarge)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(SpacingSystem.xl)
                    .featureCardStyle()
                    .padding(.horizontal, SpacingSystem.lg)
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(AnimationTiming.transition.delay(0.4), value: animateForm)

                    // Enhanced Error message
                    if let error = authService.errorMessage {
                        HStack(spacing: SpacingSystem.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(SemanticColors.errorPrimary)
                                .font(.system(size: 24, weight: .semibold))

                            Text(error)
                                .font(TypographySystem.bodyMedium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(SpacingSystem.md)
                        .background(SemanticColors.errorSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SemanticColors.errorPrimary.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, SpacingSystem.lg)
                        .transition(.scale.combined(with: .opacity))
                        .animation(AnimationTiming.feedback, value: authService.errorMessage)
                    }

                    Spacer(minLength: 64)
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
        print("DEBUG: Sign up button tapped")
        // Validation
        guard !email.isEmpty else {
            print("DEBUG: Validation failed - email empty")
            authService.errorMessage = "Email is required"
            return
        }
        guard !password.isEmpty else {
            print("DEBUG: Validation failed - password empty")
            authService.errorMessage = "Password is required"
            return
        }
        guard !firstName.isEmpty else {
            print("DEBUG: Validation failed - first name empty")
            authService.errorMessage = "First name is required"
            return
        }
        guard !lastName.isEmpty else {
            print("DEBUG: Validation failed - last name empty")
            authService.errorMessage = "Last name is required"
            return
        }
        // Date of birth is required and must be in the past
        print("DEBUG: Validating dateOfBirth: \(dateOfBirth)")
        if dateOfBirth >= Date() {
            print("DEBUG: Date of birth validation failed - date is not in the past")
            authService.errorMessage = "Date of birth must be in the past"
            return
        }

        print("DEBUG: All validations passed")
        isLoading = true
        print("LoginView: Starting sign up for email: \(email)")
        authService.signUp(
            email: email,
            password: password,
            firstName: firstName.isEmpty ? nil : firstName,
            lastName: lastName.isEmpty ? nil : lastName,
            dateOfBirth: dateOfBirth,
            gender: gender == "Prefer not to say" ? nil : gender,
            phone: phone.isEmpty ? nil : phone,
            country: country.isEmpty ? nil : country,
            city: city.isEmpty ? nil : city,
            favoriteBookGenre: favoriteBookGenre.isEmpty ? nil : favoriteBookGenre
        ) { result in
            isLoading = false
            switch result {
            case .success:
                print("LoginView: Sign up success")
                // Navigation will be handled by the parent view
                break
            case .failure:
                print("LoginView: Sign up failure")
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
                    .modifier(LiquidButtonStyle(
                        background: LinearGradient(colors: [Color.white], startPoint: .leading, endPoint: .trailing),
                        foregroundColor: PrimaryColors.dynamicOrange,
                        cornerRadius: 16,
                        padding: EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24),
                        font: TypographySystem.buttonLarge,
                        shadow: (color: Color.white.opacity(0.3), radius: 12, x: 0, y: 6)
                    ))
                    .disabled(email.isEmpty || isLoading)

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