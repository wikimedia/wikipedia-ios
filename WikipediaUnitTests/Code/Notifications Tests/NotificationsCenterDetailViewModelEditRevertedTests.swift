import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelEditRevertedTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-editReverted"
        }
    }
    
    func testEditRevertedOnUserTalkEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testEditRevertedOnUserTalkEditTextasdf(detailViewModel: detailViewModel)
    }
    
    func testEditRevertedOnArticleEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testEditRevertedOnArticleEditText(detailViewModel: detailViewModel)
    }
    
    private func testEditRevertedOnUserTalkEditTextasdf(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/19/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Edit reverted", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your edit was reverted", "Invalid contentBody")
    }
    
    private func testEditRevertedOnArticleEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "9/2/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Edit reverted", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your edit was reverted", "Invalid contentBody")
    }

}
