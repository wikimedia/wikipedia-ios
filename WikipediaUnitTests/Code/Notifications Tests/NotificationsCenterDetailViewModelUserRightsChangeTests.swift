import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelUserGroupRightsChangeTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-userRights"
    }
    
    func testUserRightsChange() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testUserRightsChangeText(detailViewModel: detailViewModel)
        try testUserRightsChangeImage(detailViewModel: detailViewModel)
        try testUserRightsChangeActions(detailViewModel: detailViewModel)
    }
    
    private func testUserRightsChangeText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Jack The Cat", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "5/13/20", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "User rights change", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your user rights were changed. You have been added to: Confirmed users.", "Invalid contentBody")
    }
    
    private func testUserRightsChangeImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-user-rights", "Invalid headerImageName")
    }
    
    private func testUserRightsChangeActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Special:ListGroupRights"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:ListGroupRights?")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "On web"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .listGroupRights
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Special:ListGroupRights#confirmed"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:ListGroupRights?#confirmed")!
        let expectedIcon0: NotificationsCenterIconType = .document
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .listGroupRights
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Jack The Cat's user page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        let expectedIcon1: NotificationsCenterIconType = .person
        let expectedDestinationText1 = "On web"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
    }

}
