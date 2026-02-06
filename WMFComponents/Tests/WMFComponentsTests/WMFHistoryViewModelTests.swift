import XCTest
import SwiftUI
import Combine
@testable import WMFComponents
@testable import WMFData

// MARK: - Fake History Data Controller

/// A fake implementation of WMFHistoryDataControllerProtocol
class FakeHistoryDataController: WMFHistoryDataControllerProtocol {

    var sections: [HistorySection] = []

    /// helper arrays for testing
    var deletedItems: [HistoryItem] = []
    var savedItems: [HistoryItem] = []
    var unsavedItems: [HistoryItem] = []

    func fetchHistorySections() -> [HistorySection] {
        return sections
    }

    func deleteHistoryItem(_ item: HistoryItem) {
        deletedItems.append(item)
    }

    func saveHistoryItem(_ item: HistoryItem) {
        savedItems.append(item)
    }

    func unsaveHistoryItem(_ item: HistoryItem) {
        unsavedItems.append(item)
    }
}

// MARK: - WMFHistoryViewModel Tests

final class WMFHistoryViewModelTests: XCTestCase {

    var cancellables = Set<AnyCancellable>()

    lazy var localizedStrings = WMFHistoryViewModel.LocalizedStrings(
        emptyViewTitle: "No History to show",
        emptyViewSubtitle: "No articles viewed.",
        todayTitle: "Today",
        yesterdayTitle: "Yesterday",
        openArticleActionTitle: "Read Now",
        saveForLaterActionTitle: "Save for Later",
        unsaveActionTitle: "Unsave",
        shareActionTitle: "Share",
        deleteSwipeActionLabel: "Delete",
        historyHeaderTitle: "History"
    )

    func createViewModel(with controller: WMFHistoryDataControllerProtocol) -> WMFHistoryViewModel {
        return WMFHistoryViewModel(
            emptyViewImage: nil,
            localizedStrings: localizedStrings,
            historyDataController: controller,
            topPadding: 0
        )
    }

    // MARK: - Test loadHistory

    func testLoadHistoryPopulatesSections() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let item1 = HistoryItem(id: "1",
                                url: URL(string: "https://example.com/1")!,
                                titleHtml: "Article 1",
                                description: nil,
                                shortDescription: nil,
                                imageURLString: nil,
                                isSaved: false,
                                snippet: nil,
                                variant: nil)
        let item2 = HistoryItem(id: "2",
                                url: URL(string: "https://example.com/2")!,
                                titleHtml: "Article 2",
                                description: nil,
                                shortDescription: nil,
                                imageURLString: nil,
                                isSaved: false,
                                snippet: nil,
                                variant: nil)
        let item3 = HistoryItem(id: "3",
                                url: URL(string: "https://example.com/3")!,
                                titleHtml: "Article 3",
                                description: nil,
                                shortDescription: nil,
                                imageURLString: nil,
                                isSaved: false,
                                snippet: nil,
                                variant: nil)

        let sectionToday = HistorySection(dateWithoutTime: today, items: [item1, item2])
        let sectionYesterday = HistorySection(dateWithoutTime: yesterday, items: [item3])

        let fakeController = FakeHistoryDataController()
        fakeController.sections = [sectionToday, sectionYesterday]

        let viewModel = createViewModel(with: fakeController)

        let expectation = XCTestExpectation(description: "Wait for loadHistory to update sections")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.sections.count, 2, "There should be 2 sections loaded.")

            if let todaySection = viewModel.sections.first(where: { Calendar.current.isDate($0.dateWithoutTime, inSameDayAs: today) }) {
                XCTAssertEqual(todaySection.items.count, 2, "Today's section should have 2 items.")
            } else {
                XCTFail("Today's section not found.")
            }

            if let yesterdaySection = viewModel.sections.first(where: { Calendar.current.isDate($0.dateWithoutTime, inSameDayAs: yesterday) }) {
                XCTAssertEqual(yesterdaySection.items.count, 1, "Yesterday's section should have 1 item.")
            } else {
                XCTFail("Yesterday's section not found.")
            }
            XCTAssertFalse(viewModel.isEmpty, "ViewModel should not be empty when sections have items.")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Test delete functionality

    func testDeleteItemInViewModel() {
        let today = Calendar.current.startOfDay(for: Date())
        let item = HistoryItem(id: "1",
                               url: URL(string: "https://example.com/1")!,
                               titleHtml: "Article 1",
                               description: nil,
                               shortDescription: nil,
                               imageURLString: nil,
                               isSaved: false,
                               snippet: nil,
                               variant: nil)
        let section = HistorySection(dateWithoutTime: today, items: [item])

        let fakeController = FakeHistoryDataController()
        fakeController.sections = [section]

        let viewModel = createViewModel(with: fakeController)

        let loadExpectation = XCTestExpectation(description: "Wait for history to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)

        XCTAssertEqual(viewModel.sections.count, 1, "There should be one section initially.")
        guard let firstSection = viewModel.sections.first else {
            XCTFail("Section should exist")
            return
        }
        XCTAssertEqual(firstSection.items.count, 1, "Section should initially have 1 item.")

        let historyItem = firstSection.items[0]
        viewModel.delete(section: firstSection, item: historyItem)

        XCTAssertEqual(fakeController.deletedItems.count, 1, "deleteHistoryItem should be called once.")
        XCTAssertEqual(fakeController.deletedItems.first?.id, historyItem.id, "Deleted item's id should match.")

        XCTAssertEqual(firstSection.items.count, 0, "Section should have 0 items after deletion.")

        let deletionExpectation = XCTestExpectation(description: "Wait for section removal")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.sections.count, 0, "ViewModel sections should be empty after deleting the last item.")
            deletionExpectation.fulfill()
        }
        wait(for: [deletionExpectation], timeout: 1.0)
    }

    // MARK: - Test save/unsave functionality

    func testSaveOrUnsave() {

        let today = Calendar.current.startOfDay(for: Date())
        let savedItem = HistoryItem(
            id: "1",
            url: URL(string: "https://example.com/1")!,
            titleHtml: "Article 1",
            description: nil,
            shortDescription: nil,
            imageURLString: nil,
            isSaved: true,
            snippet: nil,
            variant: nil
        )
        let unsavedItem = HistoryItem(
            id: "2",
            url: URL(string: "https://example.com/2")!,
            titleHtml: "Article 2",
            description: nil,
            shortDescription: nil,
            imageURLString: nil,
            isSaved: false,
            snippet: nil,
            variant: nil
        )
        let section = HistorySection(dateWithoutTime: today, items: [savedItem, unsavedItem])

        let fakeController = FakeHistoryDataController()
        fakeController.sections = [section]

        let viewModel = createViewModel(with: fakeController)

        viewModel.loadHistory()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1)) // wait for section to load

        guard let loadedSection = viewModel.sections.first,
              loadedSection.items.count == 2
        else {
            XCTFail("HistorySection didn’t load correctly")
            return
        }
        let firstItem  = section.items[0]  // true
        let secondItem = section.items[1]  // false

        viewModel.saveOrUnsave(item: firstItem,  in: loadedSection)
        viewModel.saveOrUnsave(item: secondItem, in: loadedSection)

        RunLoop.main.run(until: Date().addingTimeInterval(0.1)) // wait for async save/unsave

        XCTAssertEqual(
            fakeController.unsavedItems.map(\.id),
            [ firstItem.id ],
            "unsaveHistoryItem should have been called for the originally‑saved item"
        )
        XCTAssertEqual(
            fakeController.savedItems.map(\.id),
            [ secondItem.id ],
            "saveHistoryItem should have been called for the originally‑unsaved item"
        )
    }


    // MARK: - Test onTap action

    func testOnTapAction() {
        let today = Calendar.current.startOfDay(for: Date())
        let item = HistoryItem(id: "1",
                               url: URL(string: "https://example.com/1")!,
                               titleHtml: "Article 1",
                               description: nil,
                               shortDescription: nil,
                               imageURLString: nil,
                               isSaved: false,
                               snippet: nil,
                               variant: nil)
        let section = HistorySection(dateWithoutTime: today, items: [item])
        let fakeController = FakeHistoryDataController()
        fakeController.sections = [section]

        var tappedItem: HistoryItem?
        let viewModel = WMFHistoryViewModel(
            emptyViewImage: nil,
            localizedStrings: localizedStrings,
            historyDataController: fakeController,
            topPadding: 0
        )

        viewModel.onTapArticle = { item in
            tappedItem = item
        }

        let loadExpectation = XCTestExpectation(description: "Wait for history to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)

        guard let loadedSection = viewModel.sections.first,
              let historyItem = loadedSection.items.first else {
            XCTFail("Item should be loaded")
            return
        }
        viewModel.onTap(historyItem)

        XCTAssertEqual(tappedItem?.id, historyItem.id, "onTap action should be called with the correct item.")
    }

    // MARK: - Test header text formatting

    func testHeaderTextForSection() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let anotherDay = Calendar.current.date(byAdding: .day, value: -3, to: today)!

        let sectionToday = HistorySection(dateWithoutTime: today, items: [])
        let sectionYesterday = HistorySection(dateWithoutTime: yesterday, items: [])
        let sectionOther = HistorySection(dateWithoutTime: anotherDay, items: [])

        let fakeController = FakeHistoryDataController()
        let viewModel = createViewModel(with: fakeController)

        let headerToday = viewModel.headerTextForSection(sectionToday)
        let headerYesterday = viewModel.headerTextForSection(sectionYesterday)
        let headerOther = viewModel.headerTextForSection(sectionOther)

        XCTAssertEqual(headerToday, localizedStrings.todayTitle, "Header for today should match localized today title.")
        XCTAssertEqual(headerYesterday, localizedStrings.yesterdayTitle, "Header for yesterday should match localized yesterday title.")

        let expectedOther = DateFormatter.wmfWeekdayMonthDayDateFormatter.string(from: anotherDay)
        XCTAssertEqual(headerOther, expectedOther, "Header for other days should be a formatted date string.")
    }
}
