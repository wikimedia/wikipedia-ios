import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelGenericTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-generic"
    }
    
    func testPageReview() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testPageReviewText(detailViewModel: detailViewModel)
        try testPageReviewImage(detailViewModel: detailViewModel)
        try testPageReviewActions(detailViewModel: detailViewModel)
    }
    
    func testFlowReply() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testFlowReplyText(detailViewModel: detailViewModel)
        try testFlowReplyImage(detailViewModel: detailViewModel)
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
    
    private func testPageReviewImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-login-notify", "Invalid headerImageName")
    }
    
    private func testPageReviewActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "View page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Black_Bird?markasread=181035797&markasreadwiki=enwiki")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .link
        let expectedPrimaryDestinationText = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: .linkNonspecific)
        
        let expectedText0 = "Fred The Bird"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .link
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: .linkNonspecific)
        
        let expectedText1 = "Thank"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:Thanks/937441471")!
        let expectedIcon1: NotificationsCenterIconType = .link
        let expectedDestinationText1 = "On web"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: .linkNonspecific)
    }
    
    private func testFlowReplyText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/20/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Fred The Bird replied in \"Section Title\".", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text", "Invalid contentBody")
    }
    
    private func testFlowReplyImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-default", "Invalid headerImageName")
    }
    
    private func testFlowReplyActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 1, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "View post"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/w/index.php?title=Topic:Wcd3birxz0ixz4di&topic_showPostId=wd321irw4jqrwsyf&fromnotif=1&markasread=75530&markasreadwiki=testwiki#flow-post-wd321irw4jqrwsyf")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .link
        let expectedPrimaryDestinationText = "On web"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: .linkNonspecific)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
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
        let expectedPrimaryIcon: NotificationsCenterIconType = .link
        let expectedPrimaryDestinationText = "On web"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: .linkNonspecific)
        
        let expectedText0 = "47.234.198.142's user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:47.234.198.142")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
    }
}
