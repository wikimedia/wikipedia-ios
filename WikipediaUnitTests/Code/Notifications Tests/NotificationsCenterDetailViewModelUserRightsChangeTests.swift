import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelUserGroupRightsChangeTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-userRights"
        }
    }
    
    func testUserRightsChange() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testUserRightsChangeText(detailViewModel: detailViewModel)
    }
    
    private func testUserRightsChangeText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "5/13/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "User rights change", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your user rights were changed. You have been added to: Confirmed users.", "Invalid contentBody")
    }

}
