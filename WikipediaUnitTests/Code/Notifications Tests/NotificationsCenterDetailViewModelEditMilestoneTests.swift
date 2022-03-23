@testable import Wikipedia

import XCTest

class NotificationsCenterDetailViewModelEditMilestoneTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-editMilestone"
        }
    }
    
    func testEditMilestoneOneOnUserPage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testEditMilestoneOneOnUserPageText(detailViewModel: detailViewModel)
        try testEditMilestoneOneOnUserPageActions(detailViewModel: detailViewModel)
    }
    
    func testEditMilestoneTenOnArticle() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testEditMilestoneTenOnArticleText(detailViewModel: detailViewModel)
        try testEditMilestoneTenOnArticleActions(detailViewModel: detailViewModel)
    }
    
    func testEditMilestoneHundredOnUserTalkPage() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "3")
        
        try testEditMilestoneHundredOnUserTalkPageText(detailViewModel: detailViewModel)
        try testEditMilestoneHundredOnUserTalkPageActions(detailViewModel: detailViewModel)
    }
    
    private func testEditMilestoneOneOnUserPageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Editing milestone", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "4/2/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Editing milestone", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "You just made your first edit; thank you, and welcome!", "Invalid contentBody")
    }
    
    private func testEditMilestoneOneOnUserPageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to User:Fred The Bird"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "On web"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!)
    }
    
    private func testEditMilestoneTenOnArticleText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Editing milestone", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "4/16/19", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Editing milestone", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "You just made your tenth edit; thank you, and please keep going!", "Invalid contentBody")
    }
    
    private func testEditMilestoneTenOnArticleActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to article"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Blue_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!)
    }
    
    private func testEditMilestoneHundredOnUserTalkPageText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Editing milestone", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Editing milestone", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "You just made your hundredth edit; thank you very much!", "Invalid contentBody")
    }
    
    private func testEditMilestoneHundredOnUserTalkPageActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Go to talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!)
    }

}
