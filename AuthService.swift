import FirebaseAuth
import FirebaseFirestore
import Combine
import Foundation

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var hasCompletedOnboarding = false
    @Published var isLoadingOnboardingStatus = false
    @Published var errorMessage: String?

    private var authStateListener: AuthStateDidChangeListenerHandle?

    private init() {
        // Listen to authentication state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("Auth state changed: authenticated = \(user != nil), user: \(user?.email ?? "none")")
            self?.isAuthenticated = user != nil
            if let user = user {
                self?.isLoadingOnboardingStatus = true
                self?.fetchUserProfile(for: user) { result in
                    switch result {
                    case .success(let userProfile):
                        self?.currentUser = userProfile
                        self?.hasCompletedOnboarding = userProfile.hasCompletedOnboarding
                    case .failure:
                        self?.currentUser = nil
                        self?.hasCompletedOnboarding = false
                    }
                    self?.isLoadingOnboardingStatus = false
                }
            } else {
                self?.currentUser = nil
                self?.hasCompletedOnboarding = false
                self?.isLoadingOnboardingStatus = false
            }
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    func signUp(email: String, password: String, firstName: String? = nil, lastName: String? = nil, dateOfBirth: Date? = nil, gender: String? = nil, phone: String? = nil, country: String? = nil, city: String? = nil, favoriteBookGenre: String? = nil, tier: UserTier = .free, completion: @escaping (Result<UserProfile, Error>) -> Void) {
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
                        var data: [String: Any] = [
                            "tier": tier.rawValue,
                            "hasCompletedOnboarding": false
                        ]
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
                                let userProfile = UserProfile(from: user, firestoreData: data)
                                completion(.success(userProfile))
                            }
                        }
                    }
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(.failure(error))
            } else if let user = result?.user {
                self?.errorMessage = nil
                // Fetch user profile from Firestore
                self?.fetchUserProfile(for: user) { result in
                    switch result {
                    case .success(let userProfile):
                        completion(.success(userProfile))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            errorMessage = nil
            // Clear cached books to prevent them from being loaded in unauthenticated state
            OfflineCache.shared.clearBooksCache()
            print("DEBUG AuthService: Cleared books cache on sign out")
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

    private func fetchUserProfile(for user: FirebaseAuth.User, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(user.uid)
        userDoc.getDocument { document, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let document = document, document.exists {
                let data = document.data() ?? [:]
                let userProfile = UserProfile(from: user, firestoreData: data)
                print("Fetched user profile for \(user.email ?? "unknown")")
                completion(.success(userProfile))
            } else {
                print("User document does not exist, creating default profile")
                // Create default profile if not exists
                let defaultData: [String: Any] = [
                    "tier": UserTier.free.rawValue,
                    "hasCompletedOnboarding": false
                ]
                let userProfile = UserProfile(from: user, firestoreData: defaultData)
                completion(.success(userProfile))
            }
        }
    }

    func completeOnboarding() {
        guard let userId = currentUser?.id else { return }
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userId)
        userDoc.updateData(["hasCompletedOnboarding": true]) { [weak self] error in
            if let error = error {
                print("Error updating onboarding status: \(error.localizedDescription)")
            } else {
                print("Onboarding completed for user \(self?.currentUser?.email ?? "unknown")")
                self?.hasCompletedOnboarding = true
                // Update currentUser
                if var updatedUser = self?.currentUser {
                    updatedUser.hasCompletedOnboarding = true
                    self?.currentUser = updatedUser
                }
            }
        }
    }

    func updateUserTier(_ tier: UserTier, subscriptionId: String? = nil) {
        guard let userId = currentUser?.id else { return }
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userId)
        var data: [String: Any] = ["tier": tier.rawValue]
        if let subscriptionId = subscriptionId {
            data["subscriptionId"] = subscriptionId
        }
        userDoc.updateData(data) { [weak self] error in
            if let error = error {
                print("Error updating user tier: \(error.localizedDescription)")
            } else {
                print("User tier updated to \(tier.rawValue)")
                // Update currentUser
                if var updatedUser = self?.currentUser {
                    updatedUser.tier = tier
                    updatedUser.subscriptionId = subscriptionId
                    self?.currentUser = updatedUser
                }
            }
        }
    }
}