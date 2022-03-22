
import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelMentionTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-mentions"
        }
    }
    
    func testMentionInUserTalk() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testMentionInUserTalkText(detailViewModel: detailViewModel)
    }
    
    func testMentionInUserTalkEditSummary() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testMentionInUserTalkEditSummaryText(detailViewModel: detailViewModel)
    }
    
    func testMentionInArticleTalk() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "3")
        
        try testMentionInArticleTalkText(detailViewModel: detailViewModel)
    }
    
    func testMentionInArticleTalkEditSummary() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "4")
        
        try testMentionInArticleTalkEditSummaryText(detailViewModel: detailViewModel)
    }
    
    func testMentionFailureAnonymous() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "5")
        
        try testMentionFailureAnonymousText(detailViewModel: detailViewModel)
    }
    
    func testMentionFailureNotFound() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "6")
        
        try testMentionFailureNotFoundText(detailViewModel: detailViewModel)
    }
    
    func testMentionSuccess() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "7")
        
        try testMentionSuccessText(detailViewModel: detailViewModel)
    }
    
    func testMentionSuccessWikidata() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "8")
        
        try testMentionSuccessWikidataText(detailViewModel: detailViewModel)
    }
    
    func testMentionInArticleTalkZhWikiquote() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "9")
        
        try testMentionInArticleTalkZhWikiquoteText(detailViewModel: detailViewModel)
    }
    
    private func testMentionInUserTalkText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text mention in talk page User:Jack The Cat", "Invalid contentBody")
    }
    
    private func testMentionInUserTalkEditSummaryText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Mention in edit summary", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Edit Summary Text: User:Jack The Cat", "Invalid contentBody")
    }
    
    private func testMentionInArticleTalkText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/14/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Jack The Cat Reply text mention in talk page.", "Invalid contentBody")
    }
    
    private func testMentionInArticleTalkEditSummaryText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/6/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Mention in edit summary", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Edit Summary Text User:Jack The Cat", "Invalid contentBody")
    }
    
    private func testMentionFailureAnonymousText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Failed mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of 47.188.91.144 was not sent because the user is anonymous.", "Invalid contentBody")
    }
    
    private func testMentionFailureNotFoundText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/6/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Failed mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of Fredirufjdjd was not sent because the user was not found.", "Invalid contentBody")
    }
    
    private func testMentionSuccessText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Successful mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of Jack The Cat was sent.", "Invalid contentBody")
    }
    
    private func testMentionSuccessWikidataText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Wikidata", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Successful mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of Jack The Cat was sent.", "Invalid contentBody")
    }
    
    private func testMentionInArticleTalkZhWikiquoteText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Simplified Chinese Wikiquote", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/14/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Jack The Cat Reply text mention in talk page.", "Invalid contentBody")
    }
    
}
