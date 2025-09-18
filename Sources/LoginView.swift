import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showPasswordReset = false
    @State private var animateForm = false

    var body: some View {
        ZStack {
            // Dynamic Gradient Background
            LinearGradient(
                colors: [
                    LiquidGlass.primary.opacity(0.8),
                    LiquidGlass.secondary.opacity(0.6),
                    LiquidGlass.accent.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle animated overlay
            GeometryReader { geometry in
                Circle()
                    .fill(LiquidGlass.secondary.opacity(0.1))
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .blur(radius: 40)

                Circle()
                    .fill(LiquidGlass.accent.opacity(0.1))
                    .frame(width: geometry.size.width * 0.6)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
                    .blur(radius: 30)
            }

            ScrollView {
                VStack(spacing: LiquidGlass.Spacing.space32) {
                    Spacer(minLength: LiquidGlass.Spacing.space64)

                    // App Logo/Title with Liquid Glass effect
                    LiquidGlassCard {
                        VStack(spacing: LiquidGlass.Spacing.space16) {
                            ZStack {
                                Circle()
                                    .fill(LiquidGlass.primary.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)

                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                    .symbolEffect(.bounce, value: animateForm)
                            }

                            Text("Bookshelf Scanner")
                                .font(LiquidGlass.Typography.displayMedium)
                                .foregroundColor(.white)

                            Text("Digitize your library with AI")
                                .font(LiquidGlass.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(LiquidGlass.Animation.spring.delay(0.2), value: animateForm)

                    // Login/Signup Form with Liquid Glass
                    LiquidGlassCard(padding: LiquidGlass.Spacing.space24) {
                        VStack(spacing: LiquidGlass.Spacing.space20) {
                            // Form Header
                            VStack(spacing: LiquidGlass.Spacing.space8) {
                                Text(isSignUp ? "Create Account" : "Welcome Back")
                                    .font(LiquidGlass.Typography.headlineLarge)
                                    .foregroundColor(.white)

                                Text(isSignUp ? "Join our reading community" : "Sign in to your account")
                                    .font(LiquidGlass.Typography.bodySmall)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            // Email Field
                            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                Text("Email")
                                    .font(LiquidGlass.Typography.captionLarge)
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("", text: $email)
                                    .textFieldStyle(LiquidTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                                Text("Password")
                                    .font(LiquidGlass.Typography.captionLarge)
                                    .foregroundColor(.white.opacity(0.8))

                                SecureField("", text: $password)
                                    .textFieldStyle(LiquidTextFieldStyle())
                                    .textContentType(isSignUp ? .newPassword : .password)
                            }

                            // Sign In/Sign Up Button
                            LiquidGlassButton(
                                title: isSignUp ? "Create Account" : "Sign In",
                                style: .primary,
                                isLoading: isLoading
                            ) {
                                if isSignUp {
                                    signUp()
                                } else {
                                    signIn()
                                }
                            }

                            // Toggle between login and signup
                            Button(action: {
                                withAnimation(LiquidGlass.Animation.spring) {
                                    isSignUp.toggle()
                                }
                            }) {
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .font(LiquidGlass.Typography.bodySmall)
                                    .foregroundColor(LiquidGlass.accent)
                            }

                            // Forgot password
                            if !isSignUp {
                                Button(action: {
                                    showPasswordReset = true
                                }) {
                                    Text("Forgot Password?")
                                        .font(LiquidGlass.Typography.captionMedium)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LiquidGlass.Spacing.space32)
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(LiquidGlass.Animation.spring.delay(0.4), value: animateForm)

                    // Error message with Liquid Glass
                    if let error = authService.errorMessage {
                        LiquidGlassCard(padding: LiquidGlass.Spacing.space16) {
                            HStack(spacing: LiquidGlass.Spacing.space12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(LiquidGlass.error)
                                    .font(.system(size: 20))

                                Text(error)
                                    .font(LiquidGlass.Typography.bodySmall)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal, LiquidGlass.Spacing.space32)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: LiquidGlass.Spacing.space64)
                }
            }
        }
        .onAppear {
            withAnimation(LiquidGlass.Animation.spring.delay(0.1)) {
                animateForm = true
            }
        }
        .sheet(isPresented: $showPasswordReset) {
            LiquidPasswordResetView()
        }
    }

    private func signIn() {
        isLoading = true
        authService.signIn(email: email, password: password) { result in
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

    private func signUp() {
        isLoading = true
        authService.signUp(email: email, password: password) { result in
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

struct LiquidPasswordResetView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var animateContent = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background matching login view
            LinearGradient(
                colors: [
                    LiquidGlass.primary.opacity(0.8),
                    LiquidGlass.secondary.opacity(0.6),
                    LiquidGlass.accent.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: LiquidGlass.Spacing.space32) {
                Spacer()

                // Header with close button
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .liquidInteraction()
                    }
                }
                .padding(.horizontal, LiquidGlass.Spacing.space24)

                // Main content card
                LiquidGlassCard(padding: LiquidGlass.Spacing.space24) {
                    VStack(spacing: LiquidGlass.Spacing.space24) {
                        // Icon and title
                        VStack(spacing: LiquidGlass.Spacing.space16) {
                            ZStack {
                                Circle()
                                    .fill(LiquidGlass.warning.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 8)

                                Image(systemName: "key.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }

                            Text("Reset Password")
                                .font(LiquidGlass.Typography.headlineLarge)
                                .foregroundColor(.white)

                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(LiquidGlass.Typography.bodySmall)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: LiquidGlass.Spacing.space8) {
                            Text("Email")
                                .font(LiquidGlass.Typography.captionLarge)
                                .foregroundColor(.white.opacity(0.8))

                            TextField("", text: $email)
                                .textFieldStyle(LiquidTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                        }

                        // Send reset link button
                        LiquidGlassButton(
                            title: "Send Reset Link",
                            style: .accent,
                            isLoading: isLoading
                        ) {
                            resetPassword()
                        }
                        .disabled(email.isEmpty || isLoading)

                        // Success/error message
                        if !message.isEmpty {
                            LiquidGlassCard(padding: LiquidGlass.Spacing.space16) {
                                HStack(spacing: LiquidGlass.Spacing.space12) {
                                    Image(systemName: message.contains("sent") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(message.contains("sent") ? LiquidGlass.success : LiquidGlass.error)
                                        .font(.system(size: 20))

                                    Text(message)
                                        .font(LiquidGlass.Typography.bodySmall)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, LiquidGlass.Spacing.space32)
                .offset(y: animateContent ? 0 : 50)
                .opacity(animateContent ? 1 : 0)
                .animation(LiquidGlass.Animation.spring.delay(0.2), value: animateContent)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(LiquidGlass.Animation.spring.delay(0.1)) {
                animateContent = true
            }
        }
    }

    private func resetPassword() {
        isLoading = true
        AuthService().resetPassword(email: email) { result in
            isLoading = false
            withAnimation(LiquidGlass.Animation.spring) {
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