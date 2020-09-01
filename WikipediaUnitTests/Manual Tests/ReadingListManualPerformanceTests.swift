
import XCTest

class ReadingListManualPerformanceTests: XCTestCase {
    
    var dataStore: MWKDataStore!

    override func setUp() {
        super.setUp()
        dataStore = MWKDataStore.temporary()
    }
    
    override func tearDown() {
        super.tearDown()
        dataStore.removeFolderAtBasePath()
    }
    
    func testPerformanceCreatingReadingList() {
        let name = "foo"
        
        self.measure {
            _ = try? dataStore.readingListsController.createReadingList(named: name)
        }
    }

}
