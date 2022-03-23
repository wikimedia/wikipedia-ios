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
        try testWikidataConnectionActions(detailViewModel: detailViewModel)
    }
    
    private func testWikidataConnectionText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/25/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Wikidata connection made", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "The page Blue Bird was connected to the Wikidata item Q83380765, where data relevant to the topic can be collected.", "Invalid contentBody")
    }
    
    private func testWikidataConnectionActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to Wikidata item"
        let expectedPrimaryURL: URL? = URL(string: "https://www.wikidata.org/wiki/Special:EntityPage/Q83380765")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .wikidata
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to article"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, actionToTest: detailViewModel.secondaryActions[1])
    }

}
