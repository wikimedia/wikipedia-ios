import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelPageLinkTests: NotificationsCenterViewModelTests {
    
    override var dataFileName: String {
        get {
            return "notifications-pageLink"
        }
    }

    func testPageLink() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testPageLinkText(detailViewModel: detailViewModel)
    }
    
    private func testPageLinkText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/25/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Page link", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "A link was made from Black Cat to Blue Bird.", "Invalid contentBody")
    }

}
