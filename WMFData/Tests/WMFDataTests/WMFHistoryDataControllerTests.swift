import XCTest
@testable import WMFData

final class WMFHistoryDataControllerTests: XCTestCase {

    var dataController: WMFHistoryDataController!
    var records: [HistoryRecord] = []
    var deletedItemID: String?
    var savedItemID: String?
    var unsavedItemID: String?

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        records = []
        deletedItemID = nil
        savedItemID = nil
        unsavedItemID = nil

        dataController = WMFHistoryDataController(recordsProvider: { [weak self] in self?.records ?? [] })

        dataController.deleteRecordAction = { [weak self] item in
            self?.deletedItemID = item.id
        }
        dataController.saveRecordAction = { [weak self] item in
            self?.savedItemID = item.id
        }
        dataController.unsaveRecordAction = { [weak self] item in
            self?.unsavedItemID = item.id
        }
    }

    override func tearDown() {
        dataController = nil
        records = []
        deletedItemID = nil
        savedItemID = nil
        unsavedItemID = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testFetchHistorySectionsGroupingAndSorting() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

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

        let sections = dataController.fetchHistorySections()
        XCTAssertEqual(sections.count, 2, "There should be two sections for two different days.")

        XCTAssertEqual(sections[0].dateWithoutTime, today, "First section should be today's date.")
        XCTAssertEqual(sections[0].items.count, 2, "Today section should contain 2 items.")

        XCTAssertEqual(sections[1].dateWithoutTime, yesterday, "Second section should be yesterday's date.")
        XCTAssertEqual(sections[1].items.count, 1, "Yesterday section should contain 1 item.")
    }

    // Not testing core data operations, just the if the functions were correctly called

    func testDeleteHistoryItem() {
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
        

        dataController.deleteHistoryItem(dummyHistoryItem)
        XCTAssertEqual(deletedItemID, dummyHistoryItem.id, "The deleteRecordAction closure should be called with the correct item ID.")
    }

    func testSaveHistoryItem() {
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

        dataController.saveHistoryItem(dummyHistoryItem)
        XCTAssertEqual(savedItemID, dummyHistoryItem.id, "The saveRecordAction closure should be called with the correct item ID.")
    }

    func testUnsaveHistoryItem() {
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

        dataController.unsaveHistoryItem(dummyHistoryItem)
        XCTAssertEqual(unsavedItemID, dummyHistoryItem.id, "The unsaveRecordAction closure should be called with the correct item ID.")
    }
}
