import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class PrivacyManager {
    static let shared = PrivacyManager()

    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard()

    // Consent states
    enum ConsentType: String, CaseIterable {
        case analytics = "analytics"
        case crashReporting = "crash_reporting"
        case personalization = "personalization"
        case marketing = "marketing"
    }

    enum ConsentStatus: String {
        case granted = "granted"
        case denied = "denied"
        case pending = "pending"
    }

    // Published properties for UI updates
    @Published private(set) var consentStates: [ConsentType: ConsentStatus] = [:]
    @Published private(set) var isGDPRRegion: Bool = false
    @Published private(set) var isCCPARegion: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        determineJurisdiction()
        loadConsentStates()
        setupAuthStateListener()
    }

    // MARK: - Jurisdiction Detection

    private func determineJurisdiction() {
        let country = Locale.current.region?.identifier ?? ""
        let gdprCountries = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "GB", "UK"]
        let ccpaStates = ["CA"] // California

        isGDPRRegion = gdprCountries.contains(country)
        isCCPARegion = ccpaStates.contains(country) && Locale.current.region?.identifier == "US"
    }

    // MARK: - Consent Management

    func requestConsent(for type: ConsentType, granted: Bool) {
        let status: ConsentStatus = granted ? .granted : .denied
        consentStates[type] = status
        saveConsentState(type: type, status: status)

        // Apply consent immediately
        applyConsent(for: type, status: status)

        // Track consent change
        AnalyticsManager.shared.logEvent("consent_updated", parameters: [
            "consent_type": type.rawValue,
            "status": status.rawValue
        ])
    }

    func getConsentStatus(for type: ConsentType) -> ConsentStatus {
        return consentStates[type] ?? .pending
    }

    func hasRequiredConsents() -> Bool {
        // Check if user has made decisions on all consent types
        return ConsentType.allCases.allSatisfy { consentStates[$0] != nil }
    }

    func grantAllConsents() {
        for type in ConsentType.allCases {
            requestConsent(for: type, granted: true)
        }
    }

    func denyAllConsents() {
        for type in ConsentType.allCases {
            requestConsent(for: type, granted: false)
        }
    }

    private func applyConsent(for type: ConsentType, status: ConsentStatus) {
        switch type {
        case .analytics:
            if status == .denied {
                AnalyticsManager.shared.disableAnalyticsForUser()
            } else {
                AnalyticsManager.shared.enableAnalyticsForUser()
            }
        case .crashReporting:
            // Implement crash reporting consent (e.g., disable Crashlytics)
            if status == .denied {
                // Disable crash reporting
                print("Crash reporting disabled due to user consent")
            }
        case .personalization:
            // Handle personalization consent
            if status == .denied {
                // Disable personalized features
                print("Personalization disabled due to user consent")
            }
        case .marketing:
            // Handle marketing consent
            if status == .denied {
                // Disable marketing communications
                print("Marketing communications disabled due to user consent")
            }
        }
    }

    // MARK: - Data Export (GDPR Article 20)

    func exportUserData() async throws -> [String: Any] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw PrivacyError.userNotAuthenticated
        }

        var exportData: [String: Any] = [
            "export_timestamp": Date().ISO8601Format(),
            "user_id": userId
        ]

        // Export user profile data
        let userProfile = try await exportUserProfile(userId: userId)
        exportData["user_profile"] = userProfile

        // Export books data
        let booksData = try await exportBooksData(userId: userId)
        exportData["books"] = booksData

        // Export analytics data (if consented)
        if getConsentStatus(for: .analytics) == .granted {
            let analyticsData = try await AnalyticsManager.shared.exportAnalyticsData(userId: userId, startDate: Date.distantPast, endDate: Date())
            exportData["analytics"] = analyticsData
        }

        // Export A/B testing data
        let abTestingData = try await exportABTestingData(userId: userId)
        exportData["ab_testing"] = abTestingData

        return exportData
    }

    private func exportUserProfile(userId: String) async throws -> [String: Any] {
        let docRef = db.collection("users").document(userId)
        let document = try await docRef.getDocument()

        guard let data = document.data() else {
            throw PrivacyError.dataNotFound
        }

        return data
    }

    private func exportBooksData(userId: String) async throws -> [[String: Any]] {
        let booksRef = db.collection("users").document(userId).collection("books")
        let snapshot = try await booksRef.getDocuments()

        return snapshot.documents.map { $0.data() }
    }

    private func exportABTestingData(userId: String) async throws -> [[String: Any]] {
        let assignmentsRef = db.collection("userExperimentAssignments")
            .whereField("userId", isEqualTo: userId)

        let snapshot = try await assignmentsRef.getDocuments()
        return snapshot.documents.map { $0.data() }
    }

    // MARK: - Data Deletion (Right to be Forgotten - GDPR Article 17)

    func deleteUserData() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw PrivacyError.userNotAuthenticated
        }

        // Delete user profile
        try await db.collection("users").document(userId).delete()

        // Delete all books
        let booksRef = db.collection("users").document(userId).collection("books")
        let booksSnapshot = try await booksRef.getDocuments()
        for document in booksSnapshot.documents {
            try await document.reference.delete()
        }

        // Delete A/B testing assignments
        let assignmentsRef = db.collection("userExperimentAssignments")
            .whereField("userId", isEqualTo: userId)
        let assignmentsSnapshot = try await assignmentsRef.getDocuments()
        for document in assignmentsSnapshot.documents {
            try await document.reference.delete()
        }

        // Delete Firebase Auth user
        try await Auth.auth().currentUser?.delete()

        // Clear local data
        clearLocalData()

        // Track deletion
        AnalyticsManager.shared.logEvent("user_data_deleted", parameters: [
            "user_id": userId,
            "deletion_timestamp": Date().ISO8601Format()
        ])
    }

    // MARK: - Data Portability

    func exportDataInMachineReadableFormat() async throws -> Data {
        let exportData = try await exportUserData()
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }

    // MARK: - Consent Withdrawal

    func withdrawConsent(for type: ConsentType) {
        requestConsent(for: type, granted: false)

        // If analytics consent is withdrawn, anonymize existing data
        if type == .analytics {
            anonymizeAnalyticsData()
        }
    }

    private func anonymizeAnalyticsData() {
        // Implement analytics data anonymization
        // This would typically involve server-side processing
        AnalyticsManager.shared.logEvent("analytics_consent_withdrawn", parameters: nil)
    }

    // MARK: - CCPA Specific Features

    func submitCCPARequest(requestType: CCPARequestType) async throws {
        guard isCCPARegion else {
            throw PrivacyError.invalidJurisdiction
        }

        let requestData: [String: Any] = [
            "request_type": requestType.rawValue,
            "timestamp": Date().ISO8601Format(),
            "user_id": Auth.auth().currentUser?.uid ?? "anonymous"
        ]

        // Store CCPA request for processing
        try await db.collection("ccpa_requests").addDocument(data: requestData)

        // Track CCPA request
        AnalyticsManager.shared.logEvent("ccpa_request_submitted", parameters: [
            "request_type": requestType.rawValue
        ])
    }

    enum CCPARequestType: String {
        case doNotSell = "do_not_sell"
        case deleteData = "delete_data"
        case accessData = "access_data"
    }

    // MARK: - Helper Methods

    private func loadConsentStates() {
        for type in ConsentType.allCases {
            if let statusString = userDefaults.string(forKey: consentKey(for: type)),
               let status = ConsentStatus(rawValue: statusString) {
                consentStates[type] = status
            }
        }
    }

    private func saveConsentState(type: ConsentType, status: ConsentStatus) {
        userDefaults.set(status.rawValue, forKey: consentKey(for: type))
    }

    private func consentKey(for type: ConsentType) -> String {
        return "consent_\(type.rawValue)"
    }

    private func clearLocalData() {
        // Clear UserDefaults
        for type in ConsentType.allCases {
            userDefaults.removeObject(forKey: consentKey(for: type))
        }

        // Clear other local data as needed
        OfflineCache.shared.clearAllCache()
    }

    private func setupAuthStateListener() {
        AuthService.shared.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if !isAuthenticated {
                    self?.clearLocalData()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Error Handling

    enum PrivacyError: Error {
        case userNotAuthenticated
        case dataNotFound
        case invalidJurisdiction
        case exportFailed(String)
        case deletionFailed(String)
    }
}