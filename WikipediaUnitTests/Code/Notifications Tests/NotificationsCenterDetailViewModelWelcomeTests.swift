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
        try testWelcomeActions(detailViewModel: detailViewModel)
    }
    
    private func testWelcomeText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Welcome message", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "12/19/18", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Welcome!", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Welcome to Wikipedia, Jack The Cat! We\'re glad you\'re here.", "Invalid contentBody")
    }
    
    private func testWelcomeActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to Help:Getting started"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Help:Getting_started")!
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, actionToTest: detailViewModel.primaryAction!)
    }

}
