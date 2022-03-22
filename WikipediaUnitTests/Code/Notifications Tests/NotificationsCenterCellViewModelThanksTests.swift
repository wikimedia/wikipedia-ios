import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelThanksTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-thanks"
        }
    }
    
    func testThanksOnUserTalkEdit() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testThanksOnUserTalkEditText(cellViewModel: cellViewModel)
        try testThanksOnUserTalkEditIcons(cellViewModel: cellViewModel)
        try testThanksOnUserTalkEditActions(cellViewModel: cellViewModel)
    }
    
    func testThanksOnArticleEdit() throws {
        
        let notification = try fetchManagedObject(identifier: "2")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testThanksOnArticleEditText(cellViewModel: cellViewModel)
        try testThanksOnArticleEditIcons(cellViewModel: cellViewModel)
        try testThanksOnArticleEditActions(cellViewModel: cellViewModel)
    }
    
    private func testThanksOnUserTalkEditText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Thanks", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Fred The Bird thanked you for your edit on User talk:Fred The Bird.")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/19/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testThanksOnUserTalkEditIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testThanksOnUserTalkEditActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to Fred The Bird\'s user page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Go to talk page"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Go to diff"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1034387008&title=User_talk%253AFred_The_Bird")!
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true)
    }
    
    private func testThanksOnArticleEditText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Thanks", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Fred The Bird thanked you for your edit on Blue Bird.")
        XCTAssertEqual(cellViewModel.footerText, "Blue Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "3/13/20", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testThanksOnArticleEditIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .documentFill, "Invalid footerIconType")
    }
    
    private func testThanksOnArticleEditActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to Fred The Bird\'s user page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Go to Blue Bird"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/Blue_Bird")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Go to diff"
        let expectedURL3: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=417114&title=Blue_Bird")!
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true)
    }
}
