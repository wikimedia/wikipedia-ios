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
        try testPageLinkActions(detailViewModel: detailViewModel)
    }
    
    private func testPageLinkText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/25/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Page link", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "A link was made from Black Cat to Blue Bird.", "Invalid contentBody")
    }
    
    private func testPageLinkActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to Black Cat"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Black_Cat?")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        let expectedIcon0: NotificationsCenterIconType = .person
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to Blue Bird"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, actionToTest: detailViewModel.secondaryActions[1])
        
        let expectedText2 = "Go to diff"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=937467985&title=Blue_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .diff
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, actionToTest: detailViewModel.secondaryActions[2])
    }

}
