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
    }
    
    func testFlowReply() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testFlowReplyText(detailViewModel: detailViewModel)
    }
    
    func testFlowTopicRenamed() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "3")
        
        try testFlowTopicRenamedText(detailViewModel: detailViewModel)
    }
    
    private func testPageReviewText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/18/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Alert", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "A reviewer suggested improvements to the page Bird. Tags: notability, blp sources.", "Invalid contentBody")
    }
    
    private func testFlowReplyText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/20/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Fred The Bird replied in \"Section Title\".", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text", "Invalid contentBody")
    }

    private func testFlowTopicRenamedText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From 47.234.198.142", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/30/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Notice", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "The topic \"Topic:Section Title\" was renamed to \"Section Title 2\".", "Invalid contentBody")
    }
}
