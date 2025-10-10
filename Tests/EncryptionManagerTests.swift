import XCTest
import CryptoKit
import Security
@testable import BookshelfScanner

class EncryptionManagerTests: XCTestCase {

    var encryptionManager: EncryptionManager!
    var mockUserDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        // Clear any existing keychain items for testing
        clearTestKeychainItems()
        mockUserDefaults = MockUserDefaults()
        encryptionManager = EncryptionManager()
    }

    override func tearDown() {
        clearTestKeychainItems()
        mockUserDefaults.reset()
        super.tearDown()
    }

    // MARK: - Key Generation Tests

    func testKeyGeneration() {
        // Test that encryption/decryption works, implying key generation
        let testText = "Test key generation"
        XCTAssertNoThrow(try encryptionManager.encrypt(testText), "Encryption should work with generated key")
    }

    func testKeyPersistence() {
        // Test that the same key persists across encryption operations
        let testText = "Test persistence"

        // First encryption
        let encrypted1 = try! encryptionManager.encrypt(testText)

        // Second encryption of same text should produce different ciphertext (due to GCM nonce)
        let encrypted2 = try! encryptionManager.encrypt(testText)

        XCTAssertNotEqual(encrypted1, encrypted2, "Same text should produce different ciphertext due to nonce")

        // But both should decrypt to the same original text
        let decrypted1 = try! encryptionManager.decrypt(encrypted1)
        let decrypted2 = try! encryptionManager.decrypt(encrypted2)

        XCTAssertEqual(decrypted1, testText)
        XCTAssertEqual(decrypted2, testText)
    }

    // MARK: - Encryption Tests

    func testEncryptionDecryption() throws {
        let originalText = "This is a test message for encryption"
        let encrypted = try encryptionManager.encrypt(originalText)
        let decrypted = try encryptionManager.decrypt(encrypted)

        XCTAssertEqual(originalText, decrypted, "Decrypted text should match original")
        XCTAssertNotEqual(originalText, encrypted, "Encrypted text should be different from original")
    }

    func testEncryptionWithEmptyString() throws {
        let originalText = ""
        let encrypted = try encryptionManager.encrypt(originalText)
        let decrypted = try encryptionManager.decrypt(encrypted)

        XCTAssertEqual(originalText, decrypted, "Empty string should encrypt and decrypt correctly")
    }

    func testEncryptionWithUnicode() throws {
        let originalText = "Hello 🌍 with émojis and ümlauts"
        let encrypted = try encryptionManager.encrypt(originalText)
        let decrypted = try encryptionManager.decrypt(encrypted)

        XCTAssertEqual(originalText, decrypted, "Unicode text should encrypt and decrypt correctly")
    }

    func testEncryptionWithLongText() throws {
        let originalText = String(repeating: "This is a long test message. ", count: 1000)
        let encrypted = try encryptionManager.encrypt(originalText)
        let decrypted = try encryptionManager.decrypt(encrypted)

        XCTAssertEqual(originalText, decrypted, "Long text should encrypt and decrypt correctly")
    }

    // MARK: - Error Handling Tests

    func testDecryptWithInvalidData() {
        let invalidData = "invalid-base64-string"
        XCTAssertThrowsError(try encryptionManager.decrypt(invalidData)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
            if case EncryptionError.decryptionFailed = error {
                // Expected error
            } else {
                XCTFail("Expected decryptionFailed error")
            }
        }
    }

    func testDecryptWithWrongKey() throws {
        let originalText = "Test message"
        let encrypted = try encryptionManager.encrypt(originalText)

        // Create a new manager with a different key
        clearTestKeychainItems()
        let newManager = EncryptionManager()

        XCTAssertThrowsError(try newManager.decrypt(encrypted)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
            if case EncryptionError.decryptionFailed = error {
                // Expected error
            } else {
                XCTFail("Expected decryptionFailed error")
            }
        }
    }

    func testDecryptWithCorruptedData() throws {
        let originalText = "Test message"
        var encrypted = try encryptionManager.encrypt(originalText)

        // Corrupt the encrypted data
        if let corruptedData = Data(base64Encoded: encrypted) {
            var corruptedBytes = [UInt8](corruptedData)
            if corruptedBytes.count > 0 {
                corruptedBytes[0] ^= 0xFF // Flip bits
                encrypted = Data(corruptedBytes).base64EncodedString()
            }
        }

        XCTAssertThrowsError(try encryptionManager.decrypt(encrypted)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    // MARK: - Keychain Integration Tests

    func testKeychainStorage() {
        // Generate a key
        _ = encryptionManager.getSymmetricKey()

        // Verify key exists in Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: EncryptionManager.keychainService,
            kSecAttrAccount as String: EncryptionManager.keychainAccount,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        XCTAssertEqual(status, errSecSuccess, "Key should be stored in Keychain")
        XCTAssertNotNil(item, "Key data should be retrieved from Keychain")
    }

    func testKeychainIntegration() {
        // Test that encryption works, implying keychain integration
        let testText = "Keychain integration test"
        XCTAssertNoThrow(try encryptionManager.encrypt(testText))

        // Test that we can decrypt what we encrypted
        let encrypted = try! encryptionManager.encrypt(testText)
        let decrypted = try! encryptionManager.decrypt(encrypted)
        XCTAssertEqual(decrypted, testText)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentEncryption() {
        let expectation = XCTestExpectation(description: "Concurrent encryption")
        expectation.expectedFulfillmentCount = 10

        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            do {
                let text = "Concurrent test \(Thread.current)"
                let encrypted = try self.encryptionManager.encrypt(text)
                let decrypted = try self.encryptionManager.decrypt(encrypted)
                XCTAssertEqual(text, decrypted)
                expectation.fulfill()
            } catch {
                XCTFail("Concurrent encryption failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Helper Methods

    private func clearTestKeychainItems() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: EncryptionManager.keychainService,
            kSecAttrAccount as String: EncryptionManager.keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
    }
}
