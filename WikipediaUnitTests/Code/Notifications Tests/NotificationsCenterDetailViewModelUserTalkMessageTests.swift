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
    }
    
    func testUserTalkPageGenericAnonymousMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testUserTalkPageGenericAnonymousMessageText(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageSpecificMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "3")
        
        try testUserTalkPageSpecificMessageText(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageSpecificAnonymousMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "4")
        
        try testUserTalkPageSpecificAnonymousMessageText(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageSpecificTruncatedMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "5")
        
        try testUserTalkPageSpecificTruncatedMessageText(detailViewModel: detailViewModel)
    }
    
    func testUserTalkPageMediaWikiMessage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "6")
        
        try testUserTalkPageMediaWikiMessageText(detailViewModel: detailViewModel)
    }
    
    private func testUserTalkPageGenericMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "4/11/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Talk page message", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Message on your talk page", "Invalid contentBody")
    }
    
    private func testUserTalkPageGenericAnonymousMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From 47.184.10.84", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "5/30/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Talk page message", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Message on your talk page", "Invalid contentBody")
    }
    
    private func testUserTalkPageSpecificMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "4/11/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Hello", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text", "Invalid contentBody")
    }
    
    private func testUserTalkPageSpecificAnonymousMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From 47.184.10.84", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "6/11/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text", "Invalid contentBody")
    }
    
    private func testUserTalkPageSpecificTruncatedMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/9/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Adipiscing elit ut aliq...", "Invalid contentBody")
    }
    
    private func testUserTalkPageMediaWikiMessageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From MediaWiki message delivery", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "10/7/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Talk page message", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Message on your talk page", "Invalid contentBody")
    }
}
