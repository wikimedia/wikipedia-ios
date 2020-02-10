import XCTest
@testable import Wikipedia
@testable import WMF

class DataStoreTests: XCTestCase {
    /// The reading lists VCs and the reading lists controller assume that the default reading list has been created.
    /// Ensure it's created when a new data store is created.
    func testInitialMigrationCreatesDefaultReadingList() {
        let dataStore = MWKDataStore.temporary()
        XCTAssertNotNil(dataStore.viewContext.defaultReadingList)
    }
}
