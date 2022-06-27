import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelLoginIssuesTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-loginIssues"
    }
    
    func testLoginFailKnownDevice() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testLoginFailKnownDeviceText(cellViewModel: cellViewModel)
        try testLoginFailKnownDeviceIcons(cellViewModel: cellViewModel)
        try testLoginFailKnownDeviceActions(cellViewModel: cellViewModel)
    }
    
    private func testLoginFailKnownDeviceText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Multiple failed log in attempts", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "There have been 5 failed attempts to log in to your account since the last time you logged in. If it wasn\'t you, please make sure your account has a strong password.")
        XCTAssertEqual(cellViewModel.footerText, "Change password")
        XCTAssertEqual(cellViewModel.dateText, "7/16/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testLoginFailKnownDeviceIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .lock, "Invalid footerIconType")
    }
    
    private func testLoginFailKnownDeviceActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 4, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "Change password"
        let expectedURL1: URL? = URL(string: "https://mediawiki.org/wiki/Special:ChangeCredentials")!
        let expectedIcon1: NotificationsCenterIconType = .lock
        let expectedDestinationText1 = "On web"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: .changePassword)

        let expectedText2 = "Login notifications"
        let expectedURL2: URL? = URL(string: "https://www.mediawiki.org/wiki/Help:Login_notifications")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "On web"
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: .login)

        let expectedText3 = "Notification settings"
        let expectedURL3: URL? = nil
        let expectedIcon3: NotificationsCenterIconType? = nil
        let expectedDestinationText4: String? = nil
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[3], isNotificationSettings: true, actionType: expectedAction3)
        
    }

}
