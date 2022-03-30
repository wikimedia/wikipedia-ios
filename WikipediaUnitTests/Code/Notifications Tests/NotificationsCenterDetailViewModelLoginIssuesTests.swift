import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelLoginIssuesTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-loginIssues"
        }
    }
    
    func testLoginFailKnownDevice() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testLoginFailKnownDeviceText(detailViewModel: detailViewModel)
    }
    
    private func testLoginFailKnownDeviceText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Alert", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Multiple failed log in attempts", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "There have been 5 failed attempts to log in to your account since the last time you logged in. If it wasn\'t you, please make sure your account has a strong password.", "Invalid contentBody")
    }

}
