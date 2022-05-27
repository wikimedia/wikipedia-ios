import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelWikidataConnectionTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-wikidataConnection"
    }
    
    func testWikidataConnection() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testWikidataConnectionText(detailViewModel: detailViewModel)
        try testWikidataConnectionImage(detailViewModel: detailViewModel)
        try testWikidataConnectionActions(detailViewModel: detailViewModel)
    }
    
    private func testWikidataConnectionText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/25/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Wikidata connection made", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "The page Blue Bird was connected to the Wikidata item Q83380765, where data relevant to the topic can be collected.", "Invalid contentBody")
    }
    
    private func testWikidataConnectionImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-link", "Invalid headerImageName")
    }
    
    private func testWikidataConnectionActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Wikidata item"
        let expectedPrimaryURL: URL? = URL(string: "https://www.wikidata.org/wiki/Special:EntityPage/Q83380765")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .wikidata
        let expectedPrimaryDestinationText = "On web"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .wikidataItem
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Article"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
    }

}
