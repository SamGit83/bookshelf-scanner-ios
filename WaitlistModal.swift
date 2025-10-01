import SwiftUI

struct WaitlistModal: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
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
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppleBooksSpacing.space20) {
                Text("Join Premium Waitlist")
                .font(AppleBooksTypography.headlineLarge)
                .foregroundColor(AppleBooksColors.text)
                .multilineTextAlignment(.center)
 
                Text("Enter your details to get notified when Premium is available.")
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.textSecondary)
                .multilineTextAlignment(.center)
 
                TextField("First Name", text: $firstName)
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(AppleBooksSpacing.space12)
                .background(AppleBooksColors.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                    .stroke(firstName.isEmpty ? AppleBooksColors.textTertiary : AppleBooksColors.accent, lineWidth: 1)
                )
                .autocapitalization(.words)
                .textContentType(.givenName)
 
                TextField("Last Name", text: $lastName)
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(AppleBooksSpacing.space12)
                .background(AppleBooksColors.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                    .stroke(lastName.isEmpty ? AppleBooksColors.textTertiary : AppleBooksColors.accent, lineWidth: 1)
                )
                .autocapitalization(.words)
                .textContentType(.familyName)
 
                TextField("Enter your email", text: $email)
                .font(AppleBooksTypography.bodyLarge)
                .foregroundColor(AppleBooksColors.text)
                .padding(AppleBooksSpacing.space12)
                .background(AppleBooksColors.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                    .stroke(email.isEmpty ? AppleBooksColors.textTertiary : AppleBooksColors.accent, lineWidth: 1)
                )
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                 
                Button(action: {
                    if isValidEmail(email) && !firstName.isEmpty && !lastName.isEmpty {
                        isSubmitting = true
                        Task {
                            do {
                                try await authService.joinWaitlist(firstName: firstName, lastName: lastName, email: email, userId: userId)
                                await MainActor.run {
                                    isSubmitting = false
                                    showSuccessAlert = true
                                }
                            } catch {
                                await MainActor.run {
                                    isSubmitting = false
                                    authService.errorMessage = "Failed to join waitlist. Please try again."
                                }
                            }
                        }
                    }
                }) {
                    if isSubmitting {
                        ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    } else {
                        Text("Join Waitlist")
                        .font(AppleBooksTypography.buttonLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppleBooksSpacing.space16)
                    }
                }
                .background(AppleBooksColors.accent)
                .cornerRadius(12)
                .disabled(isSubmitting || !isValidEmail(email) || email.isEmpty || firstName.isEmpty || lastName.isEmpty)
                 
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(AppleBooksTypography.buttonMedium)
                .foregroundColor(AppleBooksColors.textSecondary)
            }
            .padding(AppleBooksSpacing.space32)
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
    }
}