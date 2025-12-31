import XCTest
@testable import WMFData

final class WMFHistoryDataControllerTests: XCTestCase {

    var dataController: WMFHistoryDataController!
    var records: [HistoryRecord] = []
    
    // Use an actor to safely capture these values
    actor TestState {
        var deletedItemID: String?
        var savedItemID: String?
        var unsavedItemID: String?
        
        func setDeletedItemID(_ id: String) {
            deletedItemID = id
        }
        
        func setSavedItemID(_ id: String) {
            savedItemID = id
        }
        
        func setUnsavedItemID(_ id: String) {
            unsavedItemID = id
        }
    }
    
    var testState: TestState!
    
    var today: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }
    
    var yesterday: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -1, to: today)!
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        records = [
            HistoryRecord(
                id: 1,
                title: "Article 1",
                descriptionOrSnippet: nil,
                shortDescription: nil,
                articleURL: URL(string: "https://example.com/1"),
                imageURL: nil,
                viewedDate: today,
                isSaved: false,
                snippet: nil,
                variant: nil
            ),
            HistoryRecord(
                id: 2,
                title: "Article 2",
                descriptionOrSnippet: nil,
                shortDescription: nil,
                articleURL: URL(string: "https://example.com/2"),
                imageURL: nil,
                viewedDate: today,
                isSaved: false,
                snippet: nil,
                variant: nil
            ),
            HistoryRecord(
                id: 3,
                title: "Article 3",
                descriptionOrSnippet: nil,
                shortDescription: nil,
                articleURL: URL(string: "https://example.com/3"),
                imageURL: nil,
                viewedDate: yesterday,
                isSaved: false,
                snippet: nil,
                variant: nil
            )
        ]
        
        testState = TestState()

        let testRecords = records
        dataController = WMFHistoryDataController(recordsProvider: { testRecords })

        let state = testState!
        
        await dataController.setActions(
            deleteAction: { item in
                Task {
                    await state.setDeletedItemID(item.id)
                }
            },
            saveAction: { item in
                Task {
                    await state.setSavedItemID(item.id)
                }
            },
            unsaveAction: { item in
                Task {
                    await state.setUnsavedItemID(item.id)
                }
            }
        )
    }

    override func tearDown() {
        dataController = nil
        records = []
        testState = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testFetchHistorySectionsGroupingAndSorting() async {
        

        let sections = await dataController.fetchHistorySections()
        XCTAssertEqual(sections.count, 2, "There should be two sections for two different days.")

        XCTAssertEqual(sections[0].dateWithoutTime, today, "First section should be today's date.")
        XCTAssertEqual(sections[0].items.count, 2, "Today section should contain 2 items.")

        XCTAssertEqual(sections[1].dateWithoutTime, yesterday, "Second section should be yesterday's date.")
        XCTAssertEqual(sections[1].items.count, 1, "Yesterday section should contain 1 item.")
    }

    // Not testing core data operations, just the if the functions were correctly called

    func testDeleteHistoryItem() async {
        let dummyHistoryItem = HistoryItem(
            id: "111",
            url: URL(string: "https://example.com/111")!,
            titleHtml: "Test Article",
            description: nil,
            shortDescription: nil,
            imageURLString: nil,
            isSaved: false,
            snippet: nil,
            variant: nil
        )
        
        await dataController.deleteHistoryItem(dummyHistoryItem)
        
        // Give the Task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let deletedID = await testState.deletedItemID
        XCTAssertEqual(deletedID, dummyHistoryItem.id, "The deleteRecordAction closure should be called with the correct item ID.")
    }

    func testSaveHistoryItem() async {
        let dummyHistoryItem = HistoryItem(
            id: "222",
            url: URL(string: "https://example.com/222")!,
            titleHtml: "Test Save Article",
            description: nil,
            shortDescription: nil,
            imageURLString: nil,
            isSaved: false,
            snippet: nil,
            variant: nil
        )

        await dataController.saveHistoryItem(dummyHistoryItem)
        
        // Give the Task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let savedID = await testState.savedItemID
        XCTAssertEqual(savedID, dummyHistoryItem.id, "The saveRecordAction closure should be called with the correct item ID.")
    }

    func testUnsaveHistoryItem() async {
        let dummyHistoryItem = HistoryItem(
            id: "333",
            url: URL(string: "https://example.com/333")!,
            titleHtml: "Test Unsave Article",
            description: nil,
            shortDescription: nil,
            imageURLString: nil,
            isSaved: true,
            snippet: nil,
            variant: nil
        )

        await dataController.unsaveHistoryItem(dummyHistoryItem)
        
        // Give the Task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let unsavedID = await testState.unsavedItemID
        XCTAssertEqual(unsavedID, dummyHistoryItem.id, "The unsaveRecordAction closure should be called with the correct item ID.")
    }
}
