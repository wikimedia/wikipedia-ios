import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelUserGroupRightsChangeTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-userRights"
    }
    
    func testUserRightsChange() throws {
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testUserRightsChangeText(cellViewModel: cellViewModel)
        try testUserRightsChangeIcons(cellViewModel: cellViewModel)
        try testUserRightsChangeActions(cellViewModel: cellViewModel)
    }
    
    private func testUserRightsChangeText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "User rights change", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Jack The Cat", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Your user rights were changed. You have been added to: Confirmed users.", "Invalid bodyText")
        XCTAssertEqual(cellViewModel.footerText, nil, "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "5/13/20", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testUserRightsChangeIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, nil, "Invalid footerIconType")
    }
    
    private func testUserRightsChangeActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expetedAction: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expetedAction)

        let expectedText1 = "Special:ListGroupRights"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:ListGroupRights?")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "On web"
        let expetedAction1: NotificationsCenterActionData.LoggingLabel = .listGroupRights
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expetedAction1)

        let expectedText2 = "Special:ListGroupRights#confirmed"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:ListGroupRights?#confirmed")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "On web"
        let expetedAction2: NotificationsCenterActionData.LoggingLabel = .listGroupRights
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expetedAction2)
        
        let expectedText3 = "Jack The Cat\'s user page"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        let expectedIcon3: NotificationsCenterIconType = .person
        let expectedDestinationText3 = "On web"
        let expetedAction3: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], actionType: expetedAction3)

        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        let expectedIcon4: NotificationsCenterIconType? = nil
        let expectedDestinationText4: String? = nil
        let expetedAction4: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, expectedIcon: expectedIcon4, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true, actionType: expetedAction4)
        
        
    }

}
