import XCTest

@testable import WMFComponents
@testable import WMFData

final class WMFHistoryViewModelTests: XCTestCase {

    func testLoadHistory() {
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

        let viewModel = WMFHistoryViewModel(historyDataController: dataController)

        let expectation = XCTestExpectation(description: "Wait for view model loadHistory")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.sections.count, 2, "There should be 2 sections loaded in the view model.")
            XCTAssertEqual(viewModel.sections[0].dateWithoutTime, today, "First section should be today's date.")
            XCTAssertEqual(viewModel.sections[0].items.count, 2, "Today's section should have 2 items.")
            XCTAssertEqual(viewModel.sections[1].dateWithoutTime, yesterday, "Second section should be yesterday's date.")
            XCTAssertEqual(viewModel.sections[1].items.count, 1, "Yesterday's section should have 1 item.")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteItemInViewModel() {
        let today = Calendar.current.startOfDay(for: Date())
        let records = [
            HistoryRecord(id: "1", titleHtml: "Article 1", description: nil, imageURL: nil, viewedDate: today),
            HistoryRecord(id: "2", titleHtml: "Article 2", description: nil, imageURL: nil, viewedDate: today)
        ]

        var deletedIDs = [String]()

        let dataController = WMFHistoryDataController(
            recordsProvider: { records },
            deleteRecordAction: { id in
                deletedIDs.append(id)
            },
            deleteAllRecordsAction: { }
        )

        let viewModel = WMFHistoryViewModel(historyDataController: dataController)

        let loadExpectation = XCTestExpectation(description: "Wait for view model to load history")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)

        XCTAssertEqual(viewModel.sections.count, 1, "There should be one section.")
        let section = viewModel.sections[0]
        XCTAssertEqual(section.items.count, 2, "The section should initially contain 2 items.")

        let firstItem = section.items[0]
        viewModel.delete(section: section, item: firstItem)

        XCTAssertEqual(deletedIDs, [firstItem.id], "deleteRecordAction should be called with the first item's id.")
        XCTAssertEqual(section.items.count, 1, "After deletion, the section should contain 1 item.")

        let deletionExpectation = XCTestExpectation(description: "Wait for section removal after deleting last item")
        let remainingItem = section.items[0]
        viewModel.delete(section: section, item: remainingItem)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            deletionExpectation.fulfill()
        }
        wait(for: [deletionExpectation], timeout: 1.0)

        XCTAssertEqual(viewModel.sections.count, 0, "The view model should have no sections after all items are deleted.")
    }

    func testDeleteAllInViewModel() {
        let today = Calendar.current.startOfDay(for: Date())
        let records = [
            HistoryRecord(id: "1", titleHtml: "Article 1", description: nil, imageURL: nil, viewedDate: today),
            HistoryRecord(id: "2", titleHtml: "Article 2", description: nil, imageURL: nil, viewedDate: today)
        ]

        var deleteAllCalled = false
        let dataController = WMFHistoryDataController(
            recordsProvider: { records },
            deleteRecordAction: { _ in },
            deleteAllRecordsAction: {
                deleteAllCalled = true
            }
        )

        let viewModel = WMFHistoryViewModel(historyDataController: dataController)

        let loadExpectation = XCTestExpectation(description: "Wait for view model to load history")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)

        XCTAssertEqual(viewModel.sections.count, 1, "Initially, there should be one section.")
        viewModel.deleteAll()

        let deletionExpectation = XCTestExpectation(description: "Wait for deleteAll to update view model")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            deletionExpectation.fulfill()
        }
        wait(for: [deletionExpectation], timeout: 1.0)

        XCTAssertTrue(deleteAllCalled, "The deleteAllRecordsAction closure should have been called.")
        XCTAssertEqual(viewModel.sections.count, 0, "After deleteAll, the view model should have no sections.")
    }
}
