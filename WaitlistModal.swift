import SwiftUI

struct WaitlistModal: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var selectedPlan: String = "monthly"
    @State private var userId: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @ObservedObject private var authService = AuthService.shared
    
    init(initialFirstName: String? = nil, initialLastName: String? = nil, initialEmail: String? = nil, initialUserId: String? = nil) {
        _firstName = State(initialValue: initialFirstName ?? "")
        _lastName = State(initialValue: initialLastName ?? "")
        _email = State(initialValue: initialEmail ?? "")
        _userId = State(initialValue: initialUserId ?? "")
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 375.0, geo.size.height / 812.0)
            let dynamicPadding = AppleBooksSpacing.space32 * scale
            let dynamicSpacing = AppleBooksSpacing.space20 * scale
            let dynamicFieldPadding = AppleBooksSpacing.space12 * scale
            let dynamicCornerRadius = 8.0 * scale
            let dynamicButtonCorner = 20.0 * scale
            let dynamicButtonPadding = AppleBooksSpacing.space16 * scale
            let dynamicShadowRadius = 12.0 * scale
            let dynamicShadowY = 6.0 * scale
            let dynamicPickerSpacing = AppleBooksSpacing.space8 * scale
            
            NavigationView {
                ScrollView {
                    VStack(spacing: dynamicSpacing) {
                        Text("Join Premium Waitlist")
                            .font(AppleBooksTypography.headlineLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        
                        Text("Enter your details to get notified when Premium is available.")
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        
                        TextField("First Name", text: $firstName)
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .padding(dynamicFieldPadding)
                            .background(AppleBooksColors.card)
                            .cornerRadius(dynamicCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: dynamicCornerRadius)
                                    .stroke(firstName.isEmpty ? AppleBooksColors.textTertiary : AppleBooksColors.accent, lineWidth: 1)
                            )
                            .autocapitalization(.words)
                            .textContentType(.givenName)
                            .frame(maxWidth: .infinity)
                        
                        TextField("Last Name", text: $lastName)
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .padding(dynamicFieldPadding)
                            .background(AppleBooksColors.card)
                            .cornerRadius(dynamicCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: dynamicCornerRadius)
                                    .stroke(lastName.isEmpty ? AppleBooksColors.textTertiary : AppleBooksColors.accent, lineWidth: 1)
                            )
                            .autocapitalization(.words)
                            .textContentType(.familyName)
                            .frame(maxWidth: .infinity)
                        
                        TextField("Enter your email", text: $email)
                            .font(AppleBooksTypography.bodyLarge)
                            .foregroundColor(AppleBooksColors.text)
                            .padding(dynamicFieldPadding)
                            .background(AppleBooksColors.card)
                            .cornerRadius(dynamicCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: dynamicCornerRadius)
                                    .stroke(email.isEmpty ? AppleBooksColors.textTertiary : AppleBooksColors.accent, lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                            .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: dynamicPickerSpacing) {
                            Text("Select Plan")
                                .font(AppleBooksTypography.bodyLarge)
                                .foregroundColor(AppleBooksColors.text)
                            Picker("Plan", selection: $selectedPlan) {
                                Text("Monthly").tag("monthly")
                                Text("Yearly").tag("yearly")
                            }
                            .pickerStyle(.segmented)
                            .background(AppleBooksColors.card)
                            .cornerRadius(dynamicCornerRadius)
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        
                        if let errorMessage = authService.errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: {
                            print("Button tapped")
                            print("firstName: \(firstName)")
                            print("lastName: \(lastName)")
                            print("email: \(email)")
                            print("isValidEmail(email): \(isValidEmail(email))")
                            if isValidEmail(email) && !firstName.isEmpty && !lastName.isEmpty {
                                print("Validation passed")
                                isSubmitting = true
                                Task {
                                    print("Starting async task")
                                    do {
                                        try await authService.joinWaitlist(firstName: firstName, lastName: lastName, email: email, plan: selectedPlan, userId: userId)
                                        print("Join waitlist successful")
                                        authService.errorMessage = nil
                                        await MainActor.run {
                                            isSubmitting = false
                                            showSuccessAlert = true
                                        }
                                    } catch {
                                        print("Error joining waitlist: \(error.localizedDescription)")
                                        await MainActor.run {
                                            isSubmitting = false
                                            if let waitlistError = error as? AuthService.WaitlistError {
                                                switch waitlistError {
                                                case .alreadyJoined:
                                                    authService.errorMessage = "You are already on the waitlist."
                                                }
                                            } else {
                                                authService.errorMessage = "Failed to join waitlist. Please try again."
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8 * scale)
                            } else {
                                Text("Join Waitlist")
                                    .font(AppleBooksTypography.buttonLarge)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, dynamicButtonPadding)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(AppleBooksColors.accent)
                        .cornerRadius(dynamicButtonCorner)
                        .shadow(color: AppleBooksColors.accent.opacity(0.4), radius: dynamicShadowRadius, x: 0, y: dynamicShadowY)
                        .overlay(
                            RoundedRectangle(cornerRadius: dynamicButtonCorner)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .disabled(isSubmitting || !isValidEmail(email) || email.isEmpty || firstName.isEmpty || lastName.isEmpty)
                        
                        Button("Skip for Free Tier") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(AppleBooksTypography.buttonMedium)
                        .foregroundColor(AppleBooksColors.textSecondary)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, dynamicPadding)
                .padding(.vertical, dynamicPadding * 0.5)
                .navigationTitle("Premium Waitlist")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Thanks for joining!"),
                    message: Text("We'll notify you when Premium is available."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .onDisappear {
                authService.errorMessage = nil
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
    }
}