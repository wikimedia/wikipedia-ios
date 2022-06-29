import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelPageLinkTests: NotificationsCenterViewModelTests {
    
    override var dataFileName: String {
        return "notifications-pageLink"
    }

    func testPageLink() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testPageLinkText(detailViewModel: detailViewModel)
        try testPageLinkImage(detailViewModel: detailViewModel)
        try testPageLinkActions(detailViewModel: detailViewModel)
    }
    
    private func testPageLinkText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/25/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Page link", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "A link was made from Black Cat to Blue Bird.", "Invalid contentBody")
    }
    
    private func testPageLinkImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-link", "Invalid headerImageName")
    }
    
    private func testPageLinkActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Black Cat"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Black_Cat?")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .linkedFromArticle
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Jack The Cat's user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Blue Bird"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Diff"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=937467985&title=Blue_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .diff
        let expectedDestinationText2 = "In app"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: detailViewModel.secondaryActions[2], actionType: expectedAction2)
    }

}
