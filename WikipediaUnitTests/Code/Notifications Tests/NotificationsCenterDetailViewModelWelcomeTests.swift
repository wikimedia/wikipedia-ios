import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelWelcomeTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-welcome"
    }
    
    func testWelcome() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testWelcomeText(detailViewModel: detailViewModel)
        try testWelcomeImage(detailViewModel: detailViewModel)
        try testWelcomeActions(detailViewModel: detailViewModel)
    }
    
    private func testWelcomeText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Welcome message", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "12/19/18", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Welcome!", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Welcome to Wikipedia, Jack The Cat! We\'re glad you\'re here.", "Invalid contentBody")
    }
    
    private func testWelcomeImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-milestone", "Invalid headerImageName")
    }
    
    private func testWelcomeActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Help:Getting started"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Help:Getting_started")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "On web"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: .gettingStarted)
    }

}
