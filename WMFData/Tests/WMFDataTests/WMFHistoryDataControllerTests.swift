import XCTest
@testable import WMFData

final class WMFHistoryDataControllerTests: XCTestCase {

    func testFetchHistorySectionsGroupingAndSorting() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let records = [
            HistoryRecord(id: "1", titleHtml: "Article 1", description: nil, imageURL: nil, viewedDate: today),
            HistoryRecord(id: "2", titleHtml: "Article 2", description: nil, imageURL: nil, viewedDate: today),
            HistoryRecord(id: "3", titleHtml: "Article 3", description: nil, imageURL: nil, viewedDate: yesterday)
        ]
        
        let dataController = WMFHistoryDataController(
            recordsProvider: { records },
            deleteRecordAction: { _ in },
            deleteAllRecordsAction: { }
        )
        
        let sections = dataController.fetchHistorySections()
        
        XCTAssertEqual(sections.count, 2, "There should be two sections for two different days.")
        
        XCTAssertEqual(sections[0].dateWithoutTime, today, "First section should be today's date.")
        XCTAssertEqual(sections[0].items.count, 2, "Today section should contain 2 items.")
        
        XCTAssertEqual(sections[1].dateWithoutTime, yesterday, "Second section should be yesterday's date.")
        XCTAssertEqual(sections[1].items.count, 1, "Yesterday section should contain 1 item.")
    }
    
    func testDeleteHistoryItem() {
        // Capture the deleted IDs.
        var deletedIDs = [String]()
        
        let dataController = WMFHistoryDataController(
            recordsProvider: { [] },
            deleteRecordAction: { id in
                deletedIDs.append(id)
            },
            deleteAllRecordsAction: { }
        )
        
        dataController.deleteHistoryItem(withID: "111")
        XCTAssertEqual(deletedIDs, ["111"], "The deleteRecordAction closure should be called with 'testID'.")
    }
    
    func testDeleteAllHistory() {
        var deleteAllCalled = false
        
        let dataController = WMFHistoryDataController(
            recordsProvider: { [] },
            deleteRecordAction: { _ in },
            deleteAllRecordsAction: {
                deleteAllCalled = true
            }
        )
        
        dataController.deleteAllHistory()
        XCTAssertTrue(deleteAllCalled, "The deleteAllRecordsAction closure should be executed.")
    }
}
