import XCTest
import FirebaseRemoteConfig
@testable import BookshelfScanner

class MockRemoteConfig: RemoteConfigProtocol {
    var lastFetchStatus: RemoteConfigFetchStatus = .success
    var lastFetchTime: Date? = Date()
    var configSettings: RemoteConfigSettings = RemoteConfigSettings()

    var fetchCompletion: ((RemoteConfigFetchStatus, Error?) -> Void)?
    var activateCompletion: ((Bool, Error?) -> Void)?

    var mockValues: [String: RemoteConfigValue] = [:]

    func setDefaults(_ defaults: [String: NSObject]) {
        // Mock implementation
    }

    func fetch(completionHandler: @escaping (RemoteConfigFetchStatus, Error?) -> Void) {
        fetchCompletion = completionHandler
        // Simulate async call
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            completionHandler(self.lastFetchStatus, nil)
        }
    }

    func activate(completion: ((Bool, Error?) -> Void)?) {
        activateCompletion = completion
        // Simulate async call
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            completion?(true, nil)
        }
    }

    func configValue(forKey key: String) -> RemoteConfigValue {
        return mockValues[key] ?? MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 0)
    }

    func triggerFetch(status: RemoteConfigFetchStatus, error: Error?) {
        fetchCompletion?(status, error)
    }

    func triggerActivate(changed: Bool, error: Error?) {
        activateCompletion?(changed, error)
    }
}

class MockRemoteConfigValue: RemoteConfigValue {
    private let mockString: String
    private let mockBool: Bool
    private let mockNumber: NSNumber

    init(stringValue: String, boolValue: Bool, numberValue: Int64) {
        self.mockString = stringValue
        self.mockBool = boolValue
        self.mockNumber = NSNumber(value: numberValue)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var stringValue: String {
        return mockString
    }

    override var boolValue: Bool {
        return mockBool
    }

    override var numberValue: NSNumber {
        return mockNumber
    }
}

class RemoteConfigManagerTests: XCTestCase {

    var mockRemoteConfig: MockRemoteConfig!
    var remoteConfigManager: RemoteConfigManager!

    override func setUp() {
        super.setUp()
        mockRemoteConfig = MockRemoteConfig()
        remoteConfigManager = RemoteConfigManager(remoteConfig: mockRemoteConfig)
    }

    override func tearDown() {
        mockRemoteConfig = nil
        remoteConfigManager = nil
        super.tearDown()
    }

    // MARK: - Fetch and Activate Tests

    func testFetchAndActivateSuccess() {
        let expectation = self.expectation(description: "Fetch and activate completes successfully")

        mockRemoteConfig.lastFetchStatus = .success

        remoteConfigManager.fetchAndActivate { result in
            switch result {
            case .success:
                XCTAssertTrue(self.remoteConfigManager.isRemoteConfigInitialized)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testFetchAndActivateFailureWithRetry() {
        let expectation = self.expectation(description: "Fetch fails and retries")

        mockRemoteConfig.lastFetchStatus = .failure

        // Simulate failure on first attempt, success on second
        var attemptCount = 0
        mockRemoteConfig.fetchCompletion = { status, error in
            attemptCount += 1
            if attemptCount == 1 {
                self.mockRemoteConfig.triggerFetch(status: .failure, error: NSError(domain: "test", code: 1, userInfo: nil))
            } else {
                self.mockRemoteConfig.triggerFetch(status: .success, error: nil)
            }
        }

        remoteConfigManager.fetchAndActivate { result in
            switch result {
            case .success:
                XCTAssertEqual(attemptCount, 2)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success after retry")
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testFetchAndActivateMaxRetriesExceeded() {
        let expectation = self.expectation(description: "Max retries exceeded")

        mockRemoteConfig.lastFetchStatus = .failure

        remoteConfigManager.fetchAndActivate { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if case .maxRetriesExceeded = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected maxRetriesExceeded error")
                }
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testActivationFailure() {
        let expectation = self.expectation(description: "Activation fails")

        mockRemoteConfig.lastFetchStatus = .success
        mockRemoteConfig.activateCompletion = { changed, error in
            self.mockRemoteConfig.triggerActivate(changed: false, error: NSError(domain: "test", code: 2, userInfo: nil))
        }

        remoteConfigManager.fetchAndActivate { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if case .activationFailed = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected activationFailed error")
                }
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - Data Retrieval Tests

    func testGetString() {
        mockRemoteConfig.mockValues["test_key"] = MockRemoteConfigValue(stringValue: "test_value", boolValue: false, numberValue: 0)
        XCTAssertEqual(remoteConfigManager.getString(forKey: "test_key"), "test_value")
        XCTAssertEqual(remoteConfigManager.getString(forKey: "nonexistent"), "")
    }

    func testGetBool() {
        mockRemoteConfig.mockValues["bool_key"] = MockRemoteConfigValue(stringValue: "", boolValue: true, numberValue: 0)
        XCTAssertTrue(remoteConfigManager.getBool(forKey: "bool_key"))
        XCTAssertFalse(remoteConfigManager.getBool(forKey: "nonexistent"))
    }

    func testGetInt() {
        mockRemoteConfig.mockValues["int_key"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 42)
        XCTAssertEqual(remoteConfigManager.getInt(forKey: "int_key"), 42)
        XCTAssertEqual(remoteConfigManager.getInt(forKey: "nonexistent"), 0)
    }

    func testGetDouble() {
        mockRemoteConfig.mockValues["double_key"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 3)
        XCTAssertEqual(remoteConfigManager.getDouble(forKey: "double_key"), 3.0)
        XCTAssertEqual(remoteConfigManager.getDouble(forKey: "nonexistent"), 0.0)
    }

    // MARK: - Validation Tests

    func testHasValidData() {
        // Set up valid data
        mockRemoteConfig.mockValues["feature_enabled"] = MockRemoteConfigValue(stringValue: "", boolValue: true, numberValue: 0)
        mockRemoteConfig.mockValues["max_books_limit"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 100)
        mockRemoteConfig.mockValues["api_timeout"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 30)

        remoteConfigManager = RemoteConfigManager(remoteConfig: mockRemoteConfig)
        remoteConfigManager.isInitialized = true

        XCTAssertTrue(remoteConfigManager.hasValidData())
    }

    func testHasValidDataInvalid() {
        mockRemoteConfig.mockValues["max_books_limit"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 2000) // Invalid range

        remoteConfigManager = RemoteConfigManager(remoteConfig: mockRemoteConfig)
        remoteConfigManager.isInitialized = true

        XCTAssertFalse(remoteConfigManager.hasValidData())
    }

    func testGetValidatedStringSuccess() {
        mockRemoteConfig.mockValues["string_key"] = MockRemoteConfigValue(stringValue: "valid_string", boolValue: false, numberValue: 0)
        remoteConfigManager.isInitialized = true

        let result = remoteConfigManager.getValidatedString(forKey: "string_key")
        switch result {
        case .success(let value):
            XCTAssertEqual(value, "valid_string")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testGetValidatedStringFailure() {
        mockRemoteConfig.mockValues["string_key"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 0)
        remoteConfigManager.isInitialized = true

        let result = remoteConfigManager.getValidatedString(forKey: "string_key")
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .validationFailed = error {
                // Expected
            } else {
                XCTFail("Expected validationFailed error")
            }
        }
    }

    func testGetValidatedIntSuccess() {
        mockRemoteConfig.mockValues["int_key"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: 50)
        remoteConfigManager.isInitialized = true

        let result = remoteConfigManager.getValidatedInt(forKey: "int_key")
        switch result {
        case .success(let value):
            XCTAssertEqual(value, 50)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testGetValidatedIntFailure() {
        mockRemoteConfig.mockValues["int_key"] = MockRemoteConfigValue(stringValue: "", boolValue: false, numberValue: -1)
        remoteConfigManager.isInitialized = true

        let result = remoteConfigManager.getValidatedInt(forKey: "int_key")
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .validationFailed = error {
                // Expected
            } else {
                XCTFail("Expected validationFailed error")
            }
        }
    }

    func testNotInitializedError() {
        remoteConfigManager.isInitialized = false

        let result = remoteConfigManager.getValidatedString(forKey: "any_key")
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .notInitialized = error {
                // Expected
            } else {
                XCTFail("Expected notInitialized error")
            }
        }
    }

    // MARK: - Properties

    func testLastFetchStatus() {
        mockRemoteConfig.lastFetchStatus = .success
        XCTAssertEqual(remoteConfigManager.lastFetchStatus, .success)
    }

    func testLastFetchTime() {
        let testDate = Date()
        mockRemoteConfig.lastFetchTime = testDate
        XCTAssertEqual(remoteConfigManager.lastFetchTime, testDate)
    }

    func testIsRemoteConfigInitialized() {
        remoteConfigManager.isInitialized = true
        XCTAssertTrue(remoteConfigManager.isRemoteConfigInitialized)

        remoteConfigManager.isInitialized = false
        XCTAssertFalse(remoteConfigManager.isRemoteConfigInitialized)
    }
}