import XCTest

class ReadingListTests: XCTestCase {
    
    var dataStore: MWKDataStore!
    
    override func setUp() {
        super.setUp()
        dataStore = MWKDataStore.temporary()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testListsWithTheSameName() {
        let originalName = "pebbles"
        let casedName = "pEbBLes"
        let diacriticName = "pEbBLés"
        do {
            let list = try dataStore.readingListsController.createReadingList(named: originalName)
            XCTAssert(list.name == originalName)
        } catch let error {
            XCTAssert(false, "Should be able to create \(originalName) reading list: \(error)")
        }
        do {
            let _ = try dataStore.readingListsController.createReadingList(named: casedName)
            XCTAssert(false, "Should not be able to create list with same title and different case")
        } catch let error as ReadingListError {
            XCTAssert(error == ReadingListError.listExistsWithTheSameName(name: casedName), "Should throw an error when creating a list with the same title and different case")
        } catch let error {
            XCTAssert(false, "Should throw the right kind of error when creating a list with the same title and different case: \(error)")
        }
        
        do {
            let list = try dataStore.readingListsController.createReadingList(named: diacriticName)
            XCTAssert(list.name == diacriticName)
        } catch let error {
            XCTAssert(false, "Should be able to create \(diacriticName) reading list: \(error)")
        }
    }
    
}
