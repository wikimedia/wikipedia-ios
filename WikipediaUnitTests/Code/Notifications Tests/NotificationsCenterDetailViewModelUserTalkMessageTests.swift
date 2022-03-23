import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelUserTalkMessageTests: NotificationsCenterViewModelTests {
    
    override var dataFileName: String {
        get {
            return "notifications-userTalkMessages"
        }
    }
    
    func testUserTalkPageGenericMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testUserTalkPageGenericMessageText(detailViewModel: detailViewModel)
        try testUserTalkPageGenericMessageActions(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageGenericAnonymousMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testUserTalkPageGenericAnonymousMessageText(detailViewModel: detailViewModel)
        try testUserTalkPageGenericAnonymousMessageActions(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageSpecificMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "3")
        
        try testUserTalkPageSpecificMessageText(detailViewModel: detailViewModel)
        try testUserTalkPageSpecificMessageActions(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageSpecificAnonymousMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "4")
        
        try testUserTalkPageSpecificAnonymousMessageText(detailViewModel: detailViewModel)
        try testUserTalkPageSpecificAnonymousMessageActions(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageSpecificTruncatedMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "5")
        
        try testUserTalkPageSpecificTruncatedMessageText(detailViewModel: detailViewModel)
        try testUserTalkPageSpecificTruncatedMessageActions(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageMediaWikiMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "6")
        
        try testUserTalkPageMediaWikiMessageText(detailViewModel: detailViewModel)
        try testUserTalkPageMediaWikiMessageActions(detailViewModel: detailViewModel)
    }
    
    private func testUserTalkPageGenericMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "4/11/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Talk page message", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Message on your talk page", "Invalid contentBody")
    }
    
    private func testUserTalkPageGenericMessageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to your talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedPrimaryIcon = NotificationsCenterIconType.document
        let expectedPrimaryDestination = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestination, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        let expectedIcon0 = NotificationsCenterIconType.person
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=892051241&title=User_talk%253AFred_The_Bird")!
        let expectedIcon1 = NotificationsCenterIconType.diff
        let expectedDestinationText1 = "In app"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1])
    }
    
    private func testUserTalkPageGenericAnonymousMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From 47.184.10.84", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "5/30/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Talk page message", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Message on your talk page", "Invalid contentBody")
    }
    
    private func testUserTalkPageGenericAnonymousMessageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to your talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedPrimaryIcon = NotificationsCenterIconType.document
        let expectedPrimaryDestination = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestination, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:47.184.10.84")!
        let expectedIcon0 = NotificationsCenterIconType.person
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=899561783&title=User_talk%253AFred_The_Bird")!
        let expectedIcon1 = NotificationsCenterIconType.diff
        let expectedDestinationText1 = "In app"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1])
    }
    
    private func testUserTalkPageSpecificMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "4/11/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Hello", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text", "Invalid contentBody")
    }
    
    private func testUserTalkPageSpecificMessageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to your talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Hello")!
        let expectedPrimaryIcon = NotificationsCenterIconType.document
        let expectedPrimaryDestination = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestination, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        let expectedIcon0 = NotificationsCenterIconType.person
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=892043155&title=User_talk%253AFred_The_Bird")!
        let expectedIcon1 = NotificationsCenterIconType.diff
        let expectedDestinationText1 = "In app"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1])
    }
    
    private func testUserTalkPageSpecificAnonymousMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From 47.184.10.84", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "6/11/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text", "Invalid contentBody")
    }
    
    private func testUserTalkPageSpecificAnonymousMessageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to your talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedPrimaryIcon = NotificationsCenterIconType.document
        let expectedPrimaryDestination = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestination, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:47.184.10.84")!
        let expectedIcon0 = NotificationsCenterIconType.person
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=901389754&title=User_talk%253AFred_The_Bird")!
        let expectedIcon1 = NotificationsCenterIconType.diff
        let expectedDestinationText1 = "In app"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1])
    }
    
    private func testUserTalkPageSpecificTruncatedMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/9/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Adipiscing elit ut aliq...", "Invalid contentBody")
    }
    
    private func testUserTalkPageSpecificTruncatedMessageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to your talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Jack_The_Cat#Section_Title")!
        let expectedPrimaryIcon = NotificationsCenterIconType.document
        let expectedPrimaryDestination = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestination, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0 = NotificationsCenterIconType.person
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1076152880&title=User_talk%253AJack_The_Cat")!
        let expectedIcon1 = NotificationsCenterIconType.diff
        let expectedDestinationText1 = "In app"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1])
    }
    
    private func testUserTalkPageMediaWikiMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From MediaWiki message delivery", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "10/7/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Talk page message", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Message on your talk page", "Invalid contentBody")
    }
    
    private func testUserTalkPageMediaWikiMessageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to your talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedPrimaryIcon = NotificationsCenterIconType.document
        let expectedPrimaryDestination = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestination, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:MediaWiki_message_delivery")!
        let expectedIcon0 = NotificationsCenterIconType.person
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=920081372&title=User_talk%253AFred_The_Bird")!
        let expectedIcon1 = NotificationsCenterIconType.diff
        let expectedDestinationText1 = "In app"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1])
    }
}
