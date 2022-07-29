import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelThanksTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-thanks"
    }
    
    func testThanksOnUserTalkEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testThanksOnUserTalkEditText(detailViewModel: detailViewModel)
        try testThanksOnUserTalkEditImage(detailViewModel: detailViewModel)
        try testThanksOnUserTalkEditActions(detailViewModel: detailViewModel)
    }
    
    func testThanksOnArticleEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testThanksOnArticleEditText(detailViewModel: detailViewModel)
        try testThanksOnArticleEditActions(detailViewModel: detailViewModel)
    }
    
    private func testThanksOnUserTalkEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/19/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Thanks", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Fred The Bird thanked you for your edit on User talk:Fred The Bird.", "Invalid contentBody")
    }
    
    private func testThanksOnUserTalkEditImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-thanks", "Invalid headerImageName")
    }
    
    private func testThanksOnUserTalkEditActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Diff"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1034387008&title=User_talk%253AFred_The_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .diff
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
    }
    
    private func testThanksOnArticleEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/13/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Thanks", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Fred The Bird thanked you for your edit on Blue Bird.", "Invalid contentBody")
    }
    
    private func testThanksOnArticleEditActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Diff"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=417114&title=Blue_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .diff
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Article"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
    }
}
