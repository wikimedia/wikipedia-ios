import XCTest
@testable import Wikipedia
@testable import WMF

class DataStoreTests: XCTestCase {
    
    var dataStore: MWKDataStore!
    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore { dataStore in
            self.dataStore = dataStore
            completion(nil)
        }
    }
    
    /// The reading lists VCs and the reading lists controller assume that the default reading list has been created.
    /// Ensure it's created when a new data store is created.
    func testInitialMigrationCreatesDefaultReadingList() {
        XCTAssertNotNil(dataStore.viewContext.defaultReadingList)
    }
}
