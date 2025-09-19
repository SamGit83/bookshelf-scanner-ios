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
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.pink.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle animated overlay
            GeometryReader { geometry in
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .blur(radius: 40)

                Circle()
                    .fill(Color.pink.opacity(0.1))
                    .frame(width: geometry.size.width * 0.6)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
                    .blur(radius: 30)
            }

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 64)

                    // App Logo/Title with glass effect
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .blur(radius: 1)
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))

                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)

                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                    .symbolEffect(.bounce, value: animateForm)
                            }

                            Text("Bookshelf Scanner")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Digitize your library with AI")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 32)
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(.spring().delay(0.2), value: animateForm)

                    // Login/Signup Form
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .blur(radius: 1)
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))

                        VStack(spacing: 20) {
                            // Form Header
                            VStack(spacing: 8) {
                                Text(isSignUp ? "Create Account" : "Welcome Back")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text(isSignUp ? "Join our reading community" : "Sign in to your account")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("", text: $email)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))

                                SecureField("", text: $password)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                    .textContentType(isSignUp ? .newPassword : .password)
                            }

                            // Sign In/Sign Up Button
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
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .foregroundColor(Color.blue)
                                        .cornerRadius(10)
                                        .font(.headline)
                                }
                            }
                            .disabled(isLoading)

                            // Toggle between login and signup
                            Button(action: {
                                withAnimation(.spring()) {
                                    isSignUp.toggle()
                                }
                            }) {
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .font(.subheadline)
                                    .foregroundColor(Color.pink)
                            }

                            // Forgot password
                            if !isSignUp {
                                Button(action: {
                                    showPasswordReset = true
                                }) {
                                    Text("Forgot Password?")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 32)
                    .offset(y: animateForm ? 0 : 50)
                    .opacity(animateForm ? 1 : 0)
                    .animation(.spring().delay(0.4), value: animateForm)

                    // Error message
                    if let error = authService.errorMessage {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                                .blur(radius: 1)
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.05))

                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))

                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 32)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 64)
                }
            }
        }
        .onAppear {
            withAnimation(.spring().delay(0.1)) {
                animateForm = true
            }
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
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

struct PasswordResetView: View {
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
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.pink.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
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
                    }
                }
                .padding(.horizontal, 24)

                // Main content card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 1)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))

                    VStack(spacing: 24) {
                        // Icon and title
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 8)

                                Image(systemName: "key.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }

                            Text("Reset Password")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))

                            TextField("", text: $email)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                        }

                        // Send reset link button
                        Button(action: {
                            resetPassword()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Reset Link")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(Color.orange)
                                    .cornerRadius(10)
                                    .font(.headline)
                            }
                        }
                        .disabled(email.isEmpty || isLoading)

                        // Success/error message
                        if !message.isEmpty {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(message.contains("sent") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                    .blur(radius: 1)
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(message.contains("sent") ? Color.green.opacity(0.05) : Color.red.opacity(0.05))

                                HStack(spacing: 12) {
                                    Image(systemName: message.contains("sent") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(message.contains("sent") ? .green : .red)
                                        .font(.system(size: 20))

                                    Text(message)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(16)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(24)
                }
                .padding(.horizontal, 32)
                .offset(y: animateContent ? 0 : 50)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring().delay(0.2), value: animateContent)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring().delay(0.1)) {
                animateContent = true
            }
        }
    }

    private func resetPassword() {
        isLoading = true
        AuthService().resetPassword(email: email) { result in
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