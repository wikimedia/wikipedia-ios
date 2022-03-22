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
        
        try testEditRevertedOnUserTalkEditText(detailViewModel: detailViewModel)
        try testEditRevertedOnUserTalkEditActions(detailViewModel: detailViewModel)
    }
    
    func testEditRevertedOnArticleEdit() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testEditRevertedOnArticleEditText(detailViewModel: detailViewModel)
        try testEditRevertedOnArticleEditActions(detailViewModel: detailViewModel)
    }
    
    private func testEditRevertedOnUserTalkEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/19/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Edit reverted", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your edit was reverted", "Invalid contentBody")
    }
    
    private func testEditRevertedOnUserTalkEditActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to diff"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1034388502&title=User_talk%253AFred_The_Bird")!
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to talk page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: detailViewModel.secondaryActions[1])
        
        let expectedText2 = "Go to talk page"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: detailViewModel.secondaryActions[2])
    }
    
    private func testEditRevertedOnArticleEditText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "9/2/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Edit reverted", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your edit was reverted", "Invalid contentBody")
    }
    
    private func testEditRevertedOnArticleEditActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to diff"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=480410&title=Blue_Bird")!
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, actionToTest: detailViewModel.primaryAction!)
        
        let expectedText0 = "Go to user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: detailViewModel.secondaryActions[0])
        
        let expectedText1 = "Go to talk page"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/Talk:Blue_Bird")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: detailViewModel.secondaryActions[1])
        
        let expectedText2 = "Go to article"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/Blue_Bird")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: detailViewModel.secondaryActions[2])
    }

}
