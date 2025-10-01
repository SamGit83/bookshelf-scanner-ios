import FirebaseAuth
import FirebaseFirestore
import Combine
import Foundation

// Analytics integration
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var hasCompletedOnboarding = false
    @Published var isLoadingOnboardingStatus = false
    @Published var errorMessage: String?

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var sessionStartTime: Date?

    private init() {
        // Listen to authentication state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("Auth state changed: authenticated = \(user != nil), user: \(user?.email ?? "none")")
            let wasAuthenticated = self?.isAuthenticated ?? false
            self?.isAuthenticated = user != nil

            if let user = user {
                // User signed in
                if !wasAuthenticated {
                    self?.sessionStartTime = Date()
                    AnalyticsManager.shared.trackSessionStart()
                }
                self?.isLoadingOnboardingStatus = true
                self?.fetchUserProfile(for: user) { result in
                    switch result {
                    case .success(let userProfile):
                        self?.currentUser = userProfile
                        self?.hasCompletedOnboarding = userProfile.hasCompletedOnboarding
                        // Refresh A/B testing limits for the new user
                        UsageTracker.shared.refreshOnUserChange()
                    case .failure:
                        self?.currentUser = nil
                        self?.hasCompletedOnboarding = false
                    }
                    self?.isLoadingOnboardingStatus = false
                }
            } else {
                // User signed out
                if wasAuthenticated, let startTime = self?.sessionStartTime {
                    let sessionDuration = Date().timeIntervalSince(startTime)
                    AnalyticsManager.shared.trackSessionEnd(duration: sessionDuration)
                }
                self?.sessionStartTime = nil
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
                                self?.currentUser = userProfile
                                self?.hasCompletedOnboarding = userProfile.hasCompletedOnboarding
                                // Refresh A/B testing limits for new user
                                UsageTracker.shared.refreshOnUserChange()
                                // Track user acquisition
                                AnalyticsManager.shared.trackUserAcquisition(source: "email_signup")
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
                        self?.currentUser = userProfile
                        self?.hasCompletedOnboarding = userProfile.hasCompletedOnboarding
                        // Refresh A/B testing limits
                        UsageTracker.shared.refreshOnUserChange()
                        // Track sign in
                        AnalyticsManager.shared.trackFeatureUsage(feature: "sign_in", context: "email")
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
            // Track sign out
            AnalyticsManager.shared.trackFeatureUsage(feature: "sign_out")
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
                // Track onboarding completion
                AnalyticsManager.shared.trackOnboardingStep(step: "onboarding_complete", completed: true)
                AnalyticsManager.shared.trackConversionFunnelStep(step: "onboarding", stepNumber: 1, totalSteps: 3)

                // Trigger onboarding feedback survey
                Task {
                    await FeedbackManager.shared.triggerSurvey(type: .onboarding)
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
                // Track subscription completion
                AnalyticsManager.shared.trackSubscriptionCompleted(tier: tier, subscriptionId: subscriptionId)
                AnalyticsManager.shared.trackConversionFunnelStep(step: "subscription", stepNumber: 3, totalSteps: 3)
            }
        }
    }

    func joinWaitlist(firstName: String, lastName: String, email: String, userId: String? = nil) async throws {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "timestamp": Timestamp()
        ]
        if let userId = userId {
            data["userId"] = userId
        }
        do {
            _ = try await db.collection("waitlist").addDocument(data: data)
            print("DEBUG AuthService: Successfully added to waitlist with email \(email)")
        } catch {
            print("DEBUG AuthService: Failed to add to waitlist: \(error)")
            throw error
        }
    }
}