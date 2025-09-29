import Foundation
import FirebaseAuth

enum UserTier: String, Codable, CaseIterable {
    case free
    case premium
}

struct UserProfile: Codable, Identifiable {
    var id: String
    var email: String?
    var firstName: String?
    var lastName: String?
    var dateOfBirth: Date?
    var gender: String?
    var phone: String?
    var country: String?
    var city: String?
    var favoriteBookGenre: String?
    var tier: UserTier
    var subscriptionId: String?
    var hasCompletedOnboarding: Bool

    init(from firebaseUser: FirebaseAuth.User, firestoreData: [String: Any]) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.firstName = firestoreData["firstName"] as? String
        self.lastName = firestoreData["lastName"] as? String
        if let timestamp = firestoreData["dateOfBirth"] as? Timestamp {
            self.dateOfBirth = timestamp.dateValue()
        }
        self.gender = firestoreData["gender"] as? String
        self.phone = firestoreData["phone"] as? String
        self.country = firestoreData["country"] as? String
        self.city = firestoreData["city"] as? String
        self.favoriteBookGenre = firestoreData["favoriteBookGenre"] as? String
        self.tier = UserTier(rawValue: firestoreData["tier"] as? String ?? "free") ?? .free
        self.subscriptionId = firestoreData["subscriptionId"] as? String
        self.hasCompletedOnboarding = firestoreData["hasCompletedOnboarding"] as? Bool ?? false
    }

    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else {
            return email ?? "User"
        }
    }
}