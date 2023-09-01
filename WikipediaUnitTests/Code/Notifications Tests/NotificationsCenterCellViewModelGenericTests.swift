import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelGenericTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-generic"
    }
    
    func testPageReview() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testPageReviewText(notificationDate: notification.date!, cellViewModel: cellViewModel)
        try testPageReviewIcons(cellViewModel: cellViewModel)
        try testPageReviewActions(cellViewModel: cellViewModel)
    }
    
    func testFlowReply() throws {
        
        let notification = try fetchManagedObject(identifier: "2")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testFlowReplyText(notificationDate: notification.date!, cellViewModel: cellViewModel)
        try testFlowReplyIcons(cellViewModel: cellViewModel)
        try testFlowReplyActions(cellViewModel: cellViewModel)
    }
    
    func testFlowTopicRenamed() throws {
        
        let notification = try fetchManagedObject(identifier: "3")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testFlowTopicRenamedText(notificationDate: notification.date!, cellViewModel: cellViewModel)
        try testFlowTopicRenamedIcons(cellViewModel: cellViewModel)
        try testFlowTopicRenamedActions(cellViewModel: cellViewModel)
    }
    
    private func testPageReviewText(notificationDate: Date, cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "A reviewer suggested improvements to the page Bird. Tags: notability, blp sources.", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert from Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, nil)
        XCTAssertEqual(cellViewModel.footerText, "View page", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, DateFormatter.wmf_short().string(from: notificationDate), "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testPageReviewIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .link, "Invalid footerIconType")
    }
    
    private func testPageReviewActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = CommonStrings.notificationsCenterMarkAsReadSwipe
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markRead
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "View page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Black_Bird?markasread=181035797&markasreadwiki=enwiki")!
        let expectedIcon1: NotificationsCenterIconType = .link
        let expectedDestinationText1 = CommonStrings.notificationsCenterDestinationApp
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: .linkNonspecific)

        let expectedText2 = "Fred The Bird"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .link
        let expectedDestinationText2 = CommonStrings.notificationsCenterDestinationWeb
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: .linkNonspecific)

        let expectedText3 = "Thank"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:Thanks/937441471")!
        let expectedIcon3: NotificationsCenterIconType = .link
        let expectedDestinationText3 = CommonStrings.notificationsCenterDestinationWeb
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], actionType: .linkNonspecific)

        let expectedText4 = CommonStrings.notificationsCenterNotificationsSettings
        let expectedURL4: URL? = nil
        let expectedIcon4: NotificationsCenterIconType? = nil
        let expectedDestinationText4: String? = nil
        let expectedAction4: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, expectedIcon: expectedIcon4, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true, actionType: expectedAction4)
    }
    
    private func testFlowReplyText(notificationDate: Date, cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Fred The Bird replied in \"Section Title\".", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert from Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Reply text")
        XCTAssertEqual(cellViewModel.footerText, "View post", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, DateFormatter.wmf_short().string(from: notificationDate), "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testFlowReplyIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .link, "Invalid footerIconType")
    }
    
    private func testFlowReplyActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 4, "Invalid sheetActionsCount")
        
        let expectedText0 = CommonStrings.notificationsCenterMarkAsUnreadSwipe
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "View post"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/w/index.php?title=Topic:Wcd3birxz0ixz4di&topic_showPostId=wd321irw4jqrwsyf&fromnotif=1&markasread=75530&markasreadwiki=testwiki#flow-post-wd321irw4jqrwsyf")!
        let expectedIcon1: NotificationsCenterIconType = .link
        let expectedDestinationText1 = CommonStrings.notificationsCenterDestinationWeb
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: .linkNonspecific)

        let expectedText2 = String.localizedStringWithFormat(CommonStrings.notificationsUserPageFormat, "Fred The Bird")
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .person
        let expectedDestinationText2 = CommonStrings.notificationsCenterDestinationWeb
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expectedAction2)

        let expectedText3 = CommonStrings.notificationsCenterNotificationsSettings
        let expectedURL3: URL? = nil
        let expectedIcon3: NotificationsCenterIconType? = nil
        let expectedDestinationText3: String? = nil
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], isNotificationSettings: true, actionType: expectedAction3)
    }

    private func testFlowTopicRenamedText(notificationDate: Date, cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "The topic \"Topic:Section Title\" was renamed to \"Section Title 2\".", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert from 47.234.198.142", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, nil)
        XCTAssertEqual(cellViewModel.footerText, "View topic", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, DateFormatter.wmf_short().string(from: notificationDate), "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testFlowTopicRenamedIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .link, "Invalid footerIconType")
    }
    
    private func testFlowTopicRenamedActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 4, "Invalid sheetActionsCount")
        
        let expectedText0 = CommonStrings.notificationsCenterMarkAsUnreadSwipe
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "View topic"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/Topic:Section_Title?markasread=88298&markasreadwiki=testwiki")!
        let expectedIcon1: NotificationsCenterIconType = .link
        let expectedDestinationText1 = CommonStrings.notificationsCenterDestinationWeb
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: .linkNonspecific)

        let expectedText2 = String.localizedStringWithFormat(CommonStrings.notificationsUserPageFormat, "47.234.198.142")
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/User:47.234.198.142")!
        let expectedIcon2: NotificationsCenterIconType = .person
        let expectedDestinationText2 = CommonStrings.notificationsCenterDestinationWeb
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expectedAction2)

        let expectedText3 = CommonStrings.notificationsCenterNotificationsSettings
        let expectedURL3: URL? = nil
        let expectedIcon3: NotificationsCenterIconType? = nil
        let expectedDestinationText3: String? = nil
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], isNotificationSettings: true, actionType: expectedAction3)
    }
}
