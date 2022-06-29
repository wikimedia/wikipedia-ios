import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelLoginIssuesTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-loginIssues"
    }
    
    func testLoginFailKnownDevice() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testLoginFailKnownDeviceText(detailViewModel: detailViewModel)
        try testLoginFailKnownDeviceImage(detailViewModel: detailViewModel)
        try testLoginFailKnownDeviceActions(detailViewModel: detailViewModel)
    }
    
    private func testLoginFailKnownDeviceText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Alert", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Multiple failed log in attempts", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "There have been 5 failed attempts to log in to your account since the last time you logged in. If it wasn\'t you, please make sure your account has a strong password.", "Invalid contentBody")
    }
    
    private func testLoginFailKnownDeviceImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-login-notify", "Invalid headerImageName")
    }
    
    private func testLoginFailKnownDeviceActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 1, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Change password"
        let expectedPrimaryURL: URL? = URL(string: "https://mediawiki.org/wiki/Special:ChangeCredentials")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .lock
        let expectedPrimaryDestinationText = "On web"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: .changePassword)
        
        let expectedText0 = "Login notifications"
        let expectedURL0: URL? = URL(string: "https://www.mediawiki.org/wiki/Help:Login_notifications")!
        let expectedIcon0: NotificationsCenterIconType = .document
        let expectedDestinationText0 = "On web"
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: .login)
    }

}
