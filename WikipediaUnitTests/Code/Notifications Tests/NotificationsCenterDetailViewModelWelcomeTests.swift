import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelWelcomeTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-welcome"
        }
    }
    
    func testWelcome() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testWelcomeText(detailViewModel: detailViewModel)
    }
    
    private func testWelcomeText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Welcome message", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "12/19/18", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Welcome!", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Welcome to Wikipedia, Jack The Cat! We\'re glad you\'re here.", "Invalid contentBody")
    }

}
