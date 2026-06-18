import XCTest
@testable import WMFData

final class WMFUserDefaultsStoreTests: XCTestCase {
    
    private struct MockObject: Codable {
        let id: UUID
        let title: String
        let flag: Bool
        
        internal init(id: UUID = UUID(), title: String = "Object Test", flag: Bool = true) {
            self.id = id
            self.title = title
            self.flag = flag
        }
    }

    private var defaultsSuiteName: String!
    private var defaults: UserDefaults!
    private var userDefaultsStore: WMFUserDefaultsStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        defaultsSuiteName = "WMFUserDefaultsStoreTests-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        userDefaultsStore = WMFUserDefaultsStore(defaults: defaults)
    }

    override func tearDownWithError() throws {
        defaults?.removePersistentDomain(forName: defaultsSuiteName)
        userDefaultsStore = nil
        defaults = nil
        defaultsSuiteName = nil

        try super.tearDownWithError()
    }
    
    func testLoadAndSaveSingleKeyString() throws {
        let testStringToSave = "String Test"
        let key = "test-user-defaults-store-string"
        try userDefaultsStore.save(key: key, value: testStringToSave)
        let loadedTestString: String? = try userDefaultsStore.load(key: key)
        
        XCTAssertEqual(testStringToSave, loadedTestString)
    }

    func testLoadAndSaveSingleKeyObject() throws {
        let testObject = MockObject()
        let key = "test-user-defaults-store-object"
        try userDefaultsStore.save(key: key, value: testObject)
        let loadedTestObject: MockObject? = try userDefaultsStore.load(key: key)
        
        XCTAssertNotNil(loadedTestObject?.id)
        XCTAssertEqual(testObject.id, loadedTestObject?.id)
    }
    
    func testLoadAndSaveMultipleKeyString() throws {
        let testStringToSave = "String Test"
        let key1 = "test"
        let key2 = "user-defaults-store"
        let key3 = "string"
        try userDefaultsStore.save(key: key1, key2, key3, value: testStringToSave)
        let loadedTestString: String? = try userDefaultsStore.load(key: key1, key2, key3)
        
        XCTAssertEqual(testStringToSave, loadedTestString)
    }
    
    func testLoadAndSaveMultipleKeyObject() throws {
        let testObject = MockObject()
        let key1 = "test"
        let key2 = "user-defaults-store"
        let key3 = "object"
        try userDefaultsStore.save(key: key1, key2, key3, value: testObject)
        let loadedTestObject: MockObject? = try userDefaultsStore.load(key: key1, key2, key3)
        
        XCTAssertNotNil(loadedTestObject?.id)
        XCTAssertEqual(testObject.id, loadedTestObject?.id)
    }
}
