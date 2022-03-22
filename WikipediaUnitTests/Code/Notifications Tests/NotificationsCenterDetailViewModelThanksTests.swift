import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelThanksTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-thanks"
        }
    }
    
    func testThanksOnUserTalkEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testThanksOnUserTalkEditText(detailViewModel: detailViewModel)
    }
    
    func testThanksOnArticleEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testThanksOnArticleEditText(detailViewModel: detailViewModel)
    }
    
    private func testThanksOnUserTalkEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/19/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Thanks", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Fred The Bird thanked you for your edit on User talk:Fred The Bird.", "Invalid contentBody")
    }
    
    private func testThanksOnArticleEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/13/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Thanks", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Fred The Bird thanked you for your edit on Blue Bird.", "Invalid contentBody")
    }
}
