import XCTest

class ReadingListManualPerformanceTests: XCTestCase {
    
    var dataStore: MWKDataStore!

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore { dataStore in
            self.dataStore = dataStore
            completion(nil)
        }
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
