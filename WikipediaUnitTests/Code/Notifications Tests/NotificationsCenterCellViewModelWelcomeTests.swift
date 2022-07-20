import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelWelcomeTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-welcome"
    }
    
    func testWelcome() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testWelcomeText(cellViewModel: cellViewModel)
        try testWelcomeIcons(cellViewModel: cellViewModel)
        try testWelcomeActions(cellViewModel: cellViewModel)
    }
    
    private func testWelcomeText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Welcome!", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "English Wikipedia", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Welcome to Wikipedia, Jack The Cat! We\'re glad you\'re here.")
        XCTAssertEqual(cellViewModel.footerText, nil)
        XCTAssertEqual(cellViewModel.dateText, "12/19/18", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testWelcomeIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertNil(cellViewModel.footerIconType, "Invalid footerIconType")
    }
    
    private func testWelcomeActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 2, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)
        
        let expectedText1 = "Notification settings"
        let expectedURL1: URL? = nil
        let expectedIcon1: NotificationsCenterIconType? = nil
        let expectedDestinationText1: String? = nil
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], isNotificationSettings: true, actionType: expectedAction1)
        
    }

}
