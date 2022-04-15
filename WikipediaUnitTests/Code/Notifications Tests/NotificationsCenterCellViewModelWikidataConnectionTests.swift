import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelWikidataConnectionTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-wikidataConnection"
        }
    }
    
    func testWikidataConnection() throws {
        
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testWikidataConnectionText(cellViewModel: cellViewModel)
        try testWikidataConnectionIcons(cellViewModel: cellViewModel)
        try testWikidataConnectionActions(cellViewModel: cellViewModel)
    }
    
    private func testWikidataConnectionText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Wikidata connection made", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Fred The Bird", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "The page Blue Bird was connected to the Wikidata item Q83380765, where data relevant to the topic can be collected.")
        XCTAssertEqual(cellViewModel.footerText, "Blue Bird")
        XCTAssertEqual(cellViewModel.dateText, "1/25/20", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testWikidataConnectionIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .documentFill, "Invalid footerIconType")
    }
    
    private func testWikidataConnectionActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        let expectedIcon0: NotificationsCenterIconType? = nil
        let expectedDestinationText0: String? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Fred The Bird\'s user page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .person
        let expectedDestinationText1 = "On web"
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Blue Bird"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "In app"
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Wikidata item"
        let expectedURL3: URL? = URL(string: "https://www.wikidata.org/wiki/Special:EntityPage/Q83380765")!
        let expectedIcon3: NotificationsCenterIconType = .wikidata
        let expectedDestinationText3 = "On web"
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, expectedIcon: expectedIcon3, expectedDestinationText: expectedDestinationText3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        let expectedIcon4: NotificationsCenterIconType? = nil
        let expectedDestinationText4: String? = nil
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, expectedIcon: expectedIcon4, expectedDestinationText: expectedDestinationText4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true)
        
    }

}
