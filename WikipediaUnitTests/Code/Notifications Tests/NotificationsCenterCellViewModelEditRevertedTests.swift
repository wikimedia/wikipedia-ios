import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelEditRevertedTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-editReverted"
    }
    
    func testEditRevertedOnUserTalkEdit() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testEditRevertedOnUserTalkEditText(cellViewModel: cellViewModel)
        try testEditRevertedOnUserTalkEditIcons(cellViewModel: cellViewModel)
        try testEditRevertedOnUserTalkEditActions(cellViewModel: cellViewModel)
    }
    
    func testEditRevertedOnArticleEdit() throws {
        
        let notification = try fetchManagedObject(identifier: "2")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testEditRevertedOnArticleEditText(cellViewModel: cellViewModel)
        try testEditRevertedOnArticleEditIcons(cellViewModel: cellViewModel)
        try testEditRevertedOnArticleEditActions(cellViewModel: cellViewModel)
    }
    
    private func testEditRevertedOnUserTalkEditText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Your edit was reverted", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, nil)
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/19/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testEditRevertedOnUserTalkEditIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testEditRevertedOnUserTalkEditActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)
        
        let expectedText1 = "Diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1034388502&title=User_talk%253AFred_The_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .diff
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Fred The Bird\'s user page"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .person
        let expectedDestinationText2 = "On web"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expectedAction2)
        
        let expectedText3 = "Talk page"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedIcon3: NotificationsCenterIconType = .document
        let expectedDestinationText3 = "In app"
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], actionType: expectedAction3)
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        let expectedIcon4: NotificationsCenterIconType? = nil
        let expectedDestinationText4: String? = nil
        let expectedAction4: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, expectedIcon: expectedIcon4, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true, actionType: expectedAction4)
    }
    
    private func testEditRevertedOnArticleEditText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Your edit was reverted", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, nil)
        XCTAssertEqual(cellViewModel.footerText, "Blue Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "9/2/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testEditRevertedOnArticleEditIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .documentFill, "Invalid footerIconType")
    }
    
    private func testEditRevertedOnArticleEditActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 6, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "Diff"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=480410&title=Blue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .diff
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Fred The Bird\'s user page"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .person
        let expectedDestinationText2 = "On web"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expectedAction2)
        
        let expectedText3 = "Blue Bird talk page"
        let expectedURL3: URL? = URL(string: "https://test.wikipedia.org/wiki/Talk:Blue_Bird")!
        let expectedIcon3: NotificationsCenterIconType = .document
        let expectedDestinationText3 = "In app"
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .articleTalk
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], actionType: expectedAction3)
        
        let expectedText4 = "Blue Bird"
        let expectedURL4: URL? = URL(string: "https://test.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon4: NotificationsCenterIconType = .document
        let expectedDestinationText4 = "In app"
        let expectedAction4: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, expectedIcon: expectedIcon4, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[4], actionType: expectedAction4)
        
        let expectedText5 = "Notification settings"
        let expectedURL5: URL? = nil
        let expectedIcon5: NotificationsCenterIconType? = nil
        let expectedDestinationText5: String? = nil
        let expectedAction5: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText5, expectedURL: expectedURL5, expectedIcon: expectedIcon5, expectedDestinationText: expectedDestinationText5, actionToTest: cellViewModel.sheetActions[5], isNotificationSettings: true, actionType: expectedAction5)
    }
}
