import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseConfig {
    static let shared = FirebaseConfig()

    private init() {
        // Configure Firebase
        FirebaseApp.configure()
    }

    // Firestore database reference
    var db: Firestore {
        return Firestore.firestore()
    }

    // Current user ID
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }

    // Check if user is authenticated
    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
}