import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelGenericTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-generic"
        }
    }
    
    func testPageReview() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testPageReviewText(cellViewModel: cellViewModel)
        try testPageReviewIcons(cellViewModel: cellViewModel)
        try testPageReviewActions(cellViewModel: cellViewModel)
    }
    
    func testFlowReply() throws {
        
        let notification = try fetchManagedObject(identifier: "2")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testFlowReplyText(cellViewModel: cellViewModel)
        try testFlowReplyIcons(cellViewModel: cellViewModel)
        try testFlowReplyActions(cellViewModel: cellViewModel)
    }
    
    func testFlowTopicRenamed() throws {
        
        let notification = try fetchManagedObject(identifier: "3")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testFlowTopicRenamedText(cellViewModel: cellViewModel)
        try testFlowTopicRenamedIcons(cellViewModel: cellViewModel)
        try testFlowTopicRenamedActions(cellViewModel: cellViewModel)
    }
    
    private func testPageReviewText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "A reviewer suggested improvements to the page Bird. Tags: notability, blp sources.", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert from Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "")
        XCTAssertEqual(cellViewModel.footerText, "View page", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "1/24/20", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testPageReviewIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .link, "Invalid footerIconType")
    }
    
    private func testPageReviewActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as read"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Fred The Bird"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Thank"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:Thanks/937441471")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "View page"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/wiki/Black_Bird?markasread=181035797&markasreadwiki=enwiki")!
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true)
    }
    
    private func testFlowReplyText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Fred The Bird replied in \"Section Title\".", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert from Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Reply text")
        XCTAssertEqual(cellViewModel.footerText, "View post", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/20/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testFlowReplyIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .link, "Invalid footerIconType")
    }
    
    private func testFlowReplyActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 4, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to Fred The Bird\'s user page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "View post"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/w/index.php?title=Topic:Wcd3birxz0ixz4di&topic_showPostId=wd321irw4jqrwsyf&fromnotif=1&markasread=75530&markasreadwiki=testwiki#flow-post-wd321irw4jqrwsyf")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Notification settings"
        let expectedURL3: URL? = nil
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3], isNotificationSettings: true)
    }

    private func testFlowTopicRenamedText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "The topic \"Topic:Section Title\" was renamed to \"Section Title 2\".", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert from 47.234.198.142", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "")
        XCTAssertEqual(cellViewModel.footerText, "View topic", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "1/30/22", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testFlowTopicRenamedIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .link, "Invalid footerIconType")
    }
    
    private func testFlowTopicRenamedActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 4, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to 47.234.198.142\'s user page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/User:47.234.198.142")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "View topic"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/Topic:Section_Title?markasread=88298&markasreadwiki=testwiki")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Notification settings"
        let expectedURL3: URL? = nil
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3], isNotificationSettings: true)
    }
}
