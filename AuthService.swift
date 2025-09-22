import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var hasCompletedOnboarding = false
    @Published var errorMessage: String?

    private var authStateListener: AuthStateDidChangeListenerHandle?

    private init() {
        // Listen to authentication state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("Auth state changed: authenticated = \(user != nil), user: \(user?.email ?? "none")")
            self?.isAuthenticated = user != nil
            self?.currentUser = user
            if let user = user {
                self?.fetchOnboardingStatus(for: user)
            } else {
                self?.hasCompletedOnboarding = false
            }
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    func signUp(email: String, password: String, firstName: String? = nil, lastName: String? = nil, dateOfBirth: Date? = nil, gender: String? = nil, phone: String? = nil, country: String? = nil, city: String? = nil, favoriteBookGenre: String? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
            } else if let user = result?.user {
                // Update user profile with additional data
                let changeRequest = user.createProfileChangeRequest()
                var displayName = ""
                if let firstName = firstName {
                    displayName = firstName
                    if let lastName = lastName {
                        displayName += " \(lastName)"
                    }
                }
                changeRequest.displayName = displayName
                changeRequest.commitChanges { error in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    } else {
                        // Save additional fields to Firestore
                        let db = Firestore.firestore()
                        let userDoc = db.collection("users").document(user.uid)
                        var data: [String: Any] = [:]
                        if let firstName = firstName { data["firstName"] = firstName }
                        if let lastName = lastName { data["lastName"] = lastName }
                        if let dateOfBirth = dateOfBirth { data["dateOfBirth"] = Timestamp(date: dateOfBirth) }
                        if let gender = gender { data["gender"] = gender }
                        if let phone = phone { data["phone"] = phone }
                        if let country = country { data["country"] = country }
                        if let city = city { data["city"] = city }
                        if let favoriteBookGenre = favoriteBookGenre { data["favoriteBookGenre"] = favoriteBookGenre }
                        print("DEBUG: Saving user data to Firestore: \(data)")
                        userDoc.setData(data) { error in
                            if let error = error {
                                self?.errorMessage = error.localizedDescription
                                completion(.failure(error))
                            } else {
                                self?.errorMessage = nil
                                completion(.success(user))
                            }
                        }
                    }
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
            } else if let user = result?.user {
                self?.errorMessage = nil
                completion(.success(user))
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            errorMessage = nil
        } catch let error {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func fetchOnboardingStatus(for user: User) {
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(user.uid)
        userDoc.getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching onboarding status: \(error.localizedDescription)")
                self?.hasCompletedOnboarding = false // Default to false on error
            } else if let document = document, document.exists {
                let completed = document.get("hasCompletedOnboarding") as? Bool ?? false
                print("Fetched hasCompletedOnboarding: \(completed) for user \(user.email ?? "unknown")")
                self?.hasCompletedOnboarding = completed
            } else {
                print("User document does not exist, setting hasCompletedOnboarding to false")
                self?.hasCompletedOnboarding = false
            }
        }
    }

    func completeOnboarding() {
        guard let user = currentUser else { return }
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(user.uid)
        userDoc.updateData(["hasCompletedOnboarding": true]) { [weak self] error in
            if let error = error {
                print("Error updating onboarding status: \(error.localizedDescription)")
            } else {
                print("Onboarding completed for user \(user.email ?? "unknown")")
                self?.hasCompletedOnboarding = true
            }
        }
    }
}