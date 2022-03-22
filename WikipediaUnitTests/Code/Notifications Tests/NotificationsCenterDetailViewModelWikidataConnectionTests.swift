import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelWikidataConnectionTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-wikidataConnection"
        }
    }
    
    func testWikidataConnection() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testWikidataConnectionText(detailViewModel: detailViewModel)
    }
    
    private func testWikidataConnectionText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/25/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Wikidata connection made", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "The page Blue Bird was connected to the Wikidata item Q83380765, where data relevant to the topic can be collected.", "Invalid contentBody")
    }

}
