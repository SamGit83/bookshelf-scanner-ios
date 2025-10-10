import Foundation
import CryptoKit
import Security

/// Manages AES encryption with device-specific keys stored in Keychain
class EncryptionManager {
    static let shared = EncryptionManager()

    private static let keychainService = "com.bookshelfscanner.encryption"
    private static let keychainAccount = "deviceEncryptionKey"

    private var symmetricKey: SymmetricKey?

    private init() {
        self.symmetricKey = getOrGenerateKey()
    }

    /// Retrieves the device-specific encryption key from Keychain or generates a new one
    private func getOrGenerateKey() -> SymmetricKey {
        // Query to retrieve existing key
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: EncryptionManager.keychainService,
            kSecAttrAccount as String: EncryptionManager.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let keyData = item as? Data {
            return SymmetricKey(data: keyData)
        } else {
            // Generate new 256-bit key
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }

            // Store the key in Keychain
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: EncryptionManager.keychainService,
                kSecAttrAccount as String: EncryptionManager.keychainAccount,
                kSecValueData as String: keyData,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                fatalError("Failed to store encryption key in Keychain: \(addStatus)")
            }

            return key
        }
    }

    /// Encrypts a string using AES-GCM
    func encrypt(_ string: String) throws -> String {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }

        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!.base64EncodedString()
    }

    /// Decrypts a base64-encoded encrypted string
    func decrypt(_ encryptedString: String) throws -> String {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }

        guard let combinedData = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidData
        }

        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }

        return decryptedString
    }
}

enum EncryptionError: Error {
    case keyNotAvailable
    case invalidData
    case decryptionFailed
}