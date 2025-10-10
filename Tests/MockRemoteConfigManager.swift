import Foundation

/// Mock implementation of RemoteConfigManagerProtocol for testing
class MockRemoteConfigManager: RemoteConfigManagerProtocol {
    var mockStringValues: [String: String] = [:]
    var fetchAndActivateCallCount = 0
    var lastFetchAndActivateCompletion: ((Result<Void, RemoteConfigError>) -> Void)?

    func getString(forKey key: String) -> String {
        return mockStringValues[key] ?? ""
    }

    func fetchAndActivate(completion: @escaping (Result<Void, RemoteConfigError>) -> Void) {
        fetchAndActivateCallCount += 1
        lastFetchAndActivateCompletion = completion
        // Simulate successful fetch
        completion(.success(()))
    }

    func simulateFetchFailure(error: RemoteConfigError) {
        lastFetchAndActivateCompletion?(.failure(error))
    }

    func reset() {
        mockStringValues.removeAll()
        fetchAndActivateCallCount = 0
        lastFetchAndActivateCompletion = nil
    }
}

/// Mock implementation of AuthService for testing
class MockAuthService {
    var mockCurrentUser: MockUser?

    var currentUser: MockUser? {
        return mockCurrentUser
    }
}

class MockUser {
    var id: String
    var email: String?

    init(id: String, email: String? = nil) {
        self.id = id
        self.email = email
    }
}

/// Mock implementation of UserDefaults for testing
class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]

    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }

    override func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }

    override func array(forKey defaultName: String) -> [Any]? {
        return storage[defaultName] as? [Any]
    }

    override func integer(forKey defaultName: String) -> Int {
        return storage[defaultName] as? Int ?? 0
    }

    override func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }

    override func data(forKey defaultName: String) -> Data? {
        return storage[defaultName] as? Data
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    override func synchronize() -> Bool {
        return true
    }

    func reset() {
        storage.removeAll()
    }
}