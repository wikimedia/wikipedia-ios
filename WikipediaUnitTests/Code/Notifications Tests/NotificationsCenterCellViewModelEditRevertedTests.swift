import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelEditRevertedTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-editReverted"
        }
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

        XCTAssertEqual(cellViewModel.sheetActions.count, 6, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to Fred The Bird\'s user page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Go to diff"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1034388502&title=User_talk%253AFred_The_Bird")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Go to talk page"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Go to User talk:Fred The Bird"
        let expectedURL4: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk%3AFred_The_Bird")!
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, actionToTest: cellViewModel.sheetActions[4])
        
        let expectedText5 = "Notification settings"
        let expectedURL5: URL? = nil
        try testActions(expectedText: expectedText5, expectedURL: expectedURL5, actionToTest: cellViewModel.sheetActions[5], isNotificationSettings: true)
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
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to Fred The Bird\'s user page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Go to diff"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=480410&title=Blue_Bird")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Go to talk page"
        let expectedURL3: URL? = URL(string: "https://test.wikipedia.org/wiki/Talk:Blue_Bird")!
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Go to Blue Bird"
        let expectedURL4: URL? = URL(string: "https://test.wikipedia.org/wiki/Blue_Bird")!
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, actionToTest: cellViewModel.sheetActions[4])
        
        let expectedText5 = "Notification settings"
        let expectedURL5: URL? = nil
        try testActions(expectedText: expectedText5, expectedURL: expectedURL5, actionToTest: cellViewModel.sheetActions[5], isNotificationSettings: true)
    }

}
