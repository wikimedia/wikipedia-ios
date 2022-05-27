@testable import Wikipedia

import XCTest

class NotificationsCenterCellViewModelEditMilestoneTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-editMilestone"
    }
    
    func testEditMilestoneOneOnUserPage() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testEditMilestoneOneOnUserPageText(cellViewModel: cellViewModel)
        try testEditMilestoneOneOnUserPageIcons(cellViewModel: cellViewModel)
        try testEditMilestoneOneOnUserPageActions(cellViewModel: cellViewModel)
    }
    
    func testEditMilestoneTenOnArticle() throws {
        
        let notification = try fetchManagedObject(identifier: "2")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testEditMilestoneTenOnArticleText(cellViewModel: cellViewModel)
        try testEditMilestoneTenOnArticleIcons(cellViewModel: cellViewModel)
        try testEditMilestoneTenOnArticleActions(cellViewModel: cellViewModel)
    }
    
    func testEditMilestoneHundredOnUserTalkPage() throws {
        
        let notification = try fetchManagedObject(identifier: "3")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testEditMilestoneHundredOnUserTalkPageText(cellViewModel: cellViewModel)
        try testEditMilestoneHundredOnUserTalkPageIcons(cellViewModel: cellViewModel)
        try testEditMilestoneHundredOnUserTalkPageActions(cellViewModel: cellViewModel)
    }
    
    private func testEditMilestoneOneOnUserPageText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Editing milestone", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "English Wikipedia", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "You just made your first edit; thank you, and welcome!")
        XCTAssertEqual(cellViewModel.footerText, "User:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "4/2/19", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testEditMilestoneOneOnUserPageIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testEditMilestoneOneOnUserPageActions(cellViewModel: NotificationsCenterCellViewModel) throws {

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
    
    private func testEditMilestoneTenOnArticleText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Editing milestone", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "English Wikipedia", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "You just made your tenth edit; thank you, and please keep going!")
        XCTAssertEqual(cellViewModel.footerText, "Blue Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "4/16/19", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testEditMilestoneTenOnArticleIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .documentFill, "Invalid footerIconType")
    }
    
    private func testEditMilestoneTenOnArticleActions(cellViewModel: NotificationsCenterCellViewModel) throws {

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
    
    private func testEditMilestoneHundredOnUserTalkPageText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Editing milestone", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "English Wikipedia", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "You just made your hundredth edit; thank you very much!")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/16/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testEditMilestoneHundredOnUserTalkPageIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testEditMilestoneHundredOnUserTalkPageActions(cellViewModel: NotificationsCenterCellViewModel) throws {

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
