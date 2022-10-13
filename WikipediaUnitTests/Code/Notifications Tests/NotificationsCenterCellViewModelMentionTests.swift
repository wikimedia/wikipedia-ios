import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelMentionTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-mentions"
    }
    
    func testMentionInUserTalk() throws {
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionInUserTalkText(cellViewModel: cellViewModel)
        try testMentionInUserTalkIcons(cellViewModel: cellViewModel)
        try testMentionInUserTalkActions(cellViewModel: cellViewModel)
    }
    
    func testMentionInUserTalkEditSummary() throws {
        let notification = try fetchManagedObject(identifier: "2")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionInUserTalkEditSummaryText(cellViewModel: cellViewModel)
        try testMentionInUserTalkEditSummaryIcons(cellViewModel: cellViewModel)
        try testMentionInUserTalkEditSummaryActions(cellViewModel: cellViewModel)
    }
    
    func testMentionInArticleTalk() throws {
        let notification = try fetchManagedObject(identifier: "3")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionInArticleTalkText(cellViewModel: cellViewModel)
        try testMentionInArticleTalkIcons(cellViewModel: cellViewModel)
        try testMentionInArticleTalkActions(cellViewModel: cellViewModel)
    }
    
    func testMentionInArticleTalkEditSummary() throws {
        let notification = try fetchManagedObject(identifier: "4")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionInArticleTalkEditSummaryText(cellViewModel: cellViewModel)
        try testMentionInArticleTalkEditSummaryIcons(cellViewModel: cellViewModel)
        try testMentionInArticleTalkEditSummaryActions(cellViewModel: cellViewModel)
    }
    
    func testMentionFailureAnonymous() throws {
        let notification = try fetchManagedObject(identifier: "5")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionFailureAnonymousText(cellViewModel: cellViewModel)
        try testMentionFailureAnonymousIcons(cellViewModel: cellViewModel)
        try testMentionFailureAnonymousActions(cellViewModel: cellViewModel)
    }
    
    func testMentionFailureNotFound() throws {
        
        let notification = try fetchManagedObject(identifier: "6")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionFailureNotFoundText(cellViewModel: cellViewModel)
        try testMentionFailureNotFoundIcons(cellViewModel: cellViewModel)
        try testMentionFailureNotFoundActions(cellViewModel: cellViewModel)
    }
    
    func testMentionSuccess() throws {
        let notification = try fetchManagedObject(identifier: "7")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionSuccessText(cellViewModel: cellViewModel)
        try testMentionSuccessIcons(cellViewModel: cellViewModel)
        try testMentionSuccessActions(cellViewModel: cellViewModel)
    }
    
    func testMentionSuccessWikidata() throws {
        let notification = try fetchManagedObject(identifier: "8")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionSuccessWikidataText(cellViewModel: cellViewModel)
        try testMentionSuccessWikidataIcons(cellViewModel: cellViewModel)
        try testMentionSuccessWikidataActions(cellViewModel: cellViewModel)
    }
    
    func testMentionInArticleTalkZhWikiquote() throws {
        let notification = try fetchManagedObject(identifier: "9")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testMentionInArticleTalkZhWikiquoteText(cellViewModel: cellViewModel)
        try testMentionInArticleTalkZhWikiquoteIcons(cellViewModel: cellViewModel)
        try testMentionInArticleTalkZhWikiquoteActions(cellViewModel: cellViewModel)
    }
    
    private func testMentionInUserTalkText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Section Title", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Reply text mention in talk page User:Jack The Cat", "Invalid bodyText")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/16/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testMentionInUserTalkIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionInUserTalkActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)

        let expectedText2 = "Fred The Bird\'s user page"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .person
        let expectedDestinationText2 = "On web"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expectedAction2)
        
        let expectedText3 = "Diff"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1033968824&title=User_talk%253AFred_The_Bird")!
        let expectedIcon3: NotificationsCenterIconType = .diff
        let expectedDestinationText3 = "In app"
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], actionType: expectedAction3)
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        let expectedIcon4: NotificationsCenterIconType? = nil
        let expectedDestinationText4: String? = nil
        let expectedAction4: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, expectedIcon: expectedIcon4, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true, actionType: expectedAction4)
    }
    
    private func testMentionInUserTalkEditSummaryText(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.headerText, "Mention in edit summary", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Edit Summary Text: User:Jack The Cat", "Invalid bodyText")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/16/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testMentionInUserTalkEditSummaryIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionInUserTalkEditSummaryActions(cellViewModel: NotificationsCenterCellViewModel) throws {
        
        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "Diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1033968849&title=User_talk%253AFred_The_Bird")!
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
    
    private func testMentionInArticleTalkText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Section Title", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Jack The Cat Reply text mention in talk page.")
        XCTAssertEqual(cellViewModel.footerText, "Talk:Blue Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "3/14/22", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testMentionInArticleTalkIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        
        let notification = try fetchManagedObject(identifier: "3")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionInArticleTalkActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 6, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "Blue Bird talk page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/Talk:Blue_Bird#Section_Title")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .articleTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)

        let expectedText2 = "Fred The Bird\'s user page"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .person
        let expectedDestinationText2 = "On web"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expectedAction2)
        
        let expectedText3 = "Diff"
        let expectedURL3: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=505586&title=Talk%253ABlue_Bird")!
        let expectedIcon3: NotificationsCenterIconType = .diff
        let expectedDestinationText3 = "In app"
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .diff
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
    
    private func testMentionInArticleTalkEditSummaryText(cellViewModel: NotificationsCenterCellViewModel) throws {
        
        XCTAssertEqual(cellViewModel.headerText, "Mention in edit summary", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Edit Summary Text User:Jack The Cat")
        XCTAssertEqual(cellViewModel.footerText, "Black Cat", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "1/6/22", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testMentionInArticleTalkEditSummaryIcons(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .documentFill, "Invalid footerIconType")
    }
    
    private func testMentionInArticleTalkEditSummaryActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "Diff"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=497048&title=Black_Cat")!
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

        let expectedText3 = "Black Cat"
        let expectedURL3: URL? = URL(string: "https://test.wikipedia.org/wiki/Black_Cat")!
        let expectedIcon3: NotificationsCenterIconType = .document
        let expectedDestinationText3 = "In app"
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], actionType: expectedAction3)
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        let expectedIcon4: NotificationsCenterIconType? = nil
        let expectedDestinationText4: String? = nil
        let expectedAction4: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, expectedIcon: expectedIcon4, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true, actionType: expectedAction4)
    }
    
    private func testMentionFailureAnonymousText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Failed mention")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Your mention of 47.188.91.144 was not sent because the user is anonymous.")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/16/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testMentionFailureAnonymousIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionFailureAnonymousActions(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.sheetActions.count, 3, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Notification settings"
        let expectedURL2: URL? = nil
        let expectedIcon2: NotificationsCenterIconType? = nil
        let expectedDestinationText2: String? = nil
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], isNotificationSettings: true, actionType: expectedAction2)
    }
    
    private func testMentionFailureNotFoundText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Failed mention")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Your mention of Fredirufjdjd was not sent because the user was not found.")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Jack The Cat", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "1/6/22", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "TEST", "Invalid projectText")
    }
    
    private func testMentionFailureNotFoundIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionFailureNotFoundActions(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.sheetActions.count, 3, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/User_talk:Jack_The_Cat#Section_Title")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Notification settings"
        let expectedURL2: URL? = nil
        let expectedIcon2: NotificationsCenterIconType? = nil
        let expectedDestinationText2: String? = nil
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], isNotificationSettings: true, actionType: expectedAction2)
    }
    
    private func testMentionSuccessText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Successful mention")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Your mention of Jack The Cat was sent.")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/16/21", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testMentionSuccessIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionSuccessActions(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.sheetActions.count, 3, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Notification settings"
        let expectedURL2: URL? = nil
        let expectedIcon2: NotificationsCenterIconType? = nil
        let expectedDestinationText2: String? = nil
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], isNotificationSettings: true, actionType: expectedAction2)
    }
    
    private func testMentionSuccessWikidataText(cellViewModel: NotificationsCenterCellViewModel) throws {
        
        XCTAssertEqual(cellViewModel.headerText, "Successful mention")
        XCTAssertEqual(cellViewModel.subheaderText, "Alert", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Your mention of Jack The Cat was sent.")
        XCTAssertEqual(cellViewModel.footerText, "User talk:Fred The Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "7/16/21", "Invalid dateText")
        XCTAssertNil(cellViewModel.projectText, "Invalid projectText")
        
    }
    
    private func testMentionSuccessWikidataIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.projectIconName, "wikimedia-project-wikidata", "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionSuccessWikidataActions(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.sheetActions.count, 3, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://wikidata.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Notification settings"
        let expectedURL2: URL? = nil
        let expectedIcon2: NotificationsCenterIconType? = nil
        let expectedDestinationText2: String? = nil
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .settings
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], isNotificationSettings: true, actionType: expectedAction2)
    }
    
    private func testMentionInArticleTalkZhWikiquoteText(cellViewModel: NotificationsCenterCellViewModel) throws {
        
        XCTAssertEqual(cellViewModel.headerText, "Section Title", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Jack The Cat Reply text mention in talk page.")
        XCTAssertEqual(cellViewModel.footerText, "Talk:Blue Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "3/14/22", "Invalid dateText")
        XCTAssertNil(cellViewModel.projectText, "Invalid projectText")
    }
    
    private func testMentionInArticleTalkZhWikiquoteIcons(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.projectIconName, "wikimedia-project-wikiquote", "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .personFill, "Invalid footerIconType")
    }
    
    private func testMentionInArticleTalkZhWikiquoteActions(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.sheetActions.count, 6, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .markUnread
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true, actionType: expectedAction0)

        let expectedText1 = "Blue Bird talk page"
        let expectedURL1: URL? = URL(string: "https://zh.wikiquote.org/wiki/Talk:Blue_Bird#Section_Title")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .articleTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1], actionType: expectedAction1)

        let expectedText2 = "Fred The Bird\'s user page"
        let expectedURL2: URL? = URL(string: "https://zh.wikiquote.org/wiki/User:Fred_The_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .person
        let expectedDestinationText2 = "On web"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2], actionType: expectedAction2)
        
        let expectedText3 = "Diff"
        let expectedURL3: URL? = URL(string:"https://zh.wikiquote.org/w/index.php?oldid=505586&title=Talk%253ABlue_Bird")!
        let expectedIcon3: NotificationsCenterIconType = .diff
        let expectedDestinationText3 = "On web"
        let expectedAction3: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3], actionType: expectedAction3)

        let expectedText4 = "Blue Bird"
        let expectedURL4: URL? = URL(string: "https://zh.wikiquote.org/wiki/Blue_Bird")!
        let expectedIcon4: NotificationsCenterIconType = .document
        let expectedDestinationText4 = "On web"
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
