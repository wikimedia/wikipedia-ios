import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelGenericTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-generic"
        }
    }
    
    func testPageReview() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testPageReviewText(detailViewModel: detailViewModel)
        try testPageReviewActions(detailViewModel: detailViewModel)
    }
    
    func testFlowReply() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testFlowReplyText(detailViewModel: detailViewModel)
        try testFlowReplyActions(detailViewModel: detailViewModel)
    }
    
    func testFlowTopicRenamed() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "3")
        
        try testFlowTopicRenamedText(detailViewModel: detailViewModel)
        try testFlowTopicRenamedActions(detailViewModel: detailViewModel)
    }
    
    private func testPageReviewText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/20/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Alert", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "A reviewer suggested improvements to the page Bird. Tags: notability, blp sources.", "Invalid contentBody")
    }
    
    private func testPageReviewActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "View page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Black_Bird?markasread=181035797&markasreadwiki=enwiki")!
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Fred The Bird"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Thank"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:Thanks/937441471")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: detailViewModel.secondaryActions[1])
    }
    
    private func testFlowReplyText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/20/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Fred The Bird replied in \"Section Title\".", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text", "Invalid contentBody")
    }
    
    private func testFlowReplyActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 1, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "View post"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/w/index.php?title=Topic:Wcd3birxz0ixz4di&topic_showPostId=wd321irw4jqrwsyf&fromnotif=1&markasread=75530&markasreadwiki=testwiki#flow-post-wd321irw4jqrwsyf")!
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: detailViewModel.secondaryActions[0])
    }

    private func testFlowTopicRenamedText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From 47.234.198.142", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/30/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Notice", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "The topic \"Topic:Section Title\" was renamed to \"Section Title 2\".", "Invalid contentBody")
    }
    
    private func testFlowTopicRenamedActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 1, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "View topic"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/wiki/Topic:Section_Title?markasread=88298&markasreadwiki=testwiki")!
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:47.234.198.142")!
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: detailViewModel.secondaryActions[0])
    }
}
