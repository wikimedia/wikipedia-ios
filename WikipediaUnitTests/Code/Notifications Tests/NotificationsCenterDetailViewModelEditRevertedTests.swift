import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelEditRevertedTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-editReverted"
    }
    
    func testEditRevertedOnUserTalkEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testEditRevertedOnUserTalkEditText(detailViewModel: detailViewModel)
        try testEditRevertedOnUserTalkEditImage(detailViewModel: detailViewModel)
        try testEditRevertedOnUserTalkEditActions(detailViewModel: detailViewModel)
    }
    
    func testEditRevertedOnArticleEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testEditRevertedOnArticleEditText(detailViewModel: detailViewModel)
        try testEditRevertedOnArticleEditImage(detailViewModel: detailViewModel)
        try testEditRevertedOnArticleEditActions(detailViewModel: detailViewModel)
    }
    
    private func testEditRevertedOnUserTalkEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/19/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Edit reverted", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your edit was reverted", "Invalid contentBody")
    }
    
    private func testEditRevertedOnUserTalkEditImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-edit-revert", "Invalid headerImageName")
    }
    
    private func testEditRevertedOnUserTalkEditActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Diff"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1034388502&title=User_talk%253AFred_The_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .diff
        let expectedPrimaryDestinationText = "In app"
        let expetedAction: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expetedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expetedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expetedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expetedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expetedAction1)
        
        let expectedText2 = "Talk page"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "In app"
        let expetedAction2: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: detailViewModel.secondaryActions[2], actionType: expetedAction2)
    }
    
    private func testEditRevertedOnArticleEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "9/2/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Edit reverted", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your edit was reverted", "Invalid contentBody")
    }
    
    private func testEditRevertedOnArticleEditImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-edit-revert", "Invalid headerImageName")
    }
    
    private func testEditRevertedOnArticleEditActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Diff"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=480410&title=Blue_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .diff
        let expectedPrimaryDestinationText = "In app"
        let expetedAction: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expetedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expetedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expetedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/Talk:Blue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expetedAction1: NotificationsCenterActionData.LoggingLabel = .articleTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expetedAction1)
        
        let expectedText2 = "Article"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "In app"
        let expetedAction2: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: detailViewModel.secondaryActions[2], actionType: expetedAction2)
    }

}
