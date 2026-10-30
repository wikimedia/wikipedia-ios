import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFReadingListsViewModelTests: XCTestCase {

    private var delegate: MockDelegate!
    private var loggingDelegate: MockLoggingDelegate!

    override func setUp() async throws {
        delegate = MockDelegate()
        loggingDelegate = MockLoggingDelegate()
    }

    private func list(_ name: String, isDefault: Bool = false, articleCount: Int = 0) -> WMFReadingList {
        WMFReadingList(id: name, name: name, description: nil, isDefault: isDefault, createdDate: Date(timeIntervalSince1970: 1_000_000), articleCount: articleCount, articleIDs: [])
    }

    private func makeViewModel(lists: [WMFReadingList], filter: WMFReadingListsFilter = .all) async -> WMFReadingListsViewModel {
        delegate.readingLists = lists
        let dataController = WMFLegacyReadingListsDataController(delegate: delegate, userDefaultsStore: WMFMockKeyValueStore())
        let viewModel = WMFReadingListsViewModel(dataController: dataController, filter: filter)
        viewModel.loggingDelegate = loggingDelegate
        viewModel.loadReadingLists()
        await waitForState(viewModel)
        return viewModel
    }

    private func waitForState(_ viewModel: WMFReadingListsViewModel) async {
        for _ in 0..<50 where viewModel.state == .loading {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func waitForLog(count: Int) async {
        for _ in 0..<50 where delegate.log.count < count {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    // MARK: - State

    func testNoListsShowsTheEmptyState() async {
        let viewModel = await makeViewModel(lists: [])
        XCTAssertEqual(viewModel.state, .empty)
    }

    func testNoListsWhileTheFirstSyncIsPendingKeepsLoading() async {
        delegate.initialSyncPending = true
        let viewModel = await makeViewModel(lists: [])
        XCTAssertEqual(viewModel.state, .loading)

        delegate.initialSyncPending = false
        delegate.readingLists = [list("Zoology")]
        viewModel.loadReadingLists()
        await waitForState(viewModel)
        XCTAssertEqual(viewModel.state, .data)
    }

    func testListsShowTheData() async {
        let viewModel = await makeViewModel(lists: [list("Zoology")])
        XCTAssertEqual(viewModel.state, .data)
        XCTAssertEqual(viewModel.readingLists.map { $0.name }, ["Zoology"])
    }

    func testSearchWithNoMatchKeepsTheListNotTheEmptyState() async {
        let viewModel = await makeViewModel(lists: [list("Zoology")])
        viewModel.searchText = "cats"
        viewModel.loadReadingLists()
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.state, .data)
        XCTAssertTrue(viewModel.readingLists.isEmpty)
    }

    // MARK: - Editing and selection

    func testEditingNeedsACustomList() async {
        let onlyDefault = await makeViewModel(lists: [list("Saved", isDefault: true)])
        XCTAssertFalse(onlyDefault.canEdit)

        let withCustom = await makeViewModel(lists: [list("Saved", isDefault: true), list("Zoology")])
        XCTAssertTrue(withCustom.canEdit)
    }

    func testReloadKeepsTheRowOfAnUnchangedList() async {
        let viewModel = await makeViewModel(lists: [list("Zoology"), list("animals")])
        let zoologyRow = viewModel.rows.first { $0.id == "Zoology" }
        delegate.readingLists = [list("Zoology"), list("animals", articleCount: 1)]
        viewModel.loadReadingLists()
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(viewModel.rows.first { $0.id == "Zoology" } === zoologyRow)
        XCTAssertEqual(viewModel.rows.first { $0.id == "animals" }?.readingList.articleCount, 1)
    }

    func testEditingTogglesLogAndClearSelection() async {
        let viewModel = await makeViewModel(lists: [list("Zoology")])
        viewModel.toggleEditing()
        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(loggingDelegate.editTaps, 1)

        viewModel.toggleSelection(for: viewModel.readingLists[0])
        XCTAssertTrue(viewModel.hasSelection)

        viewModel.toggleEditing()
        XCTAssertFalse(viewModel.isEditing)
        XCTAssertFalse(viewModel.hasSelection)
    }

    func testTheDefaultListCannotBeSelected() async {
        let viewModel = await makeViewModel(lists: [list("Saved", isDefault: true), list("Zoology")])
        viewModel.toggleEditing()
        viewModel.toggleSelection(for: viewModel.readingLists[0])
        XCTAssertFalse(viewModel.hasSelection)
    }

    // MARK: - Deleting

    func testDeletingAnEmptyListNeedsNoConfirmation() async {
        let viewModel = await makeViewModel(lists: [list("Zoology")])
        viewModel.requestDeletion(of: viewModel.readingLists)
        XCTAssertNil(viewModel.pendingDeletion)
        await waitForLog(count: 1)
        XCTAssertEqual(delegate.log, ["delete Zoology"])
        XCTAssertEqual(loggingDelegate.deletedCounts, [1])
    }

    func testDeletingAListWithArticlesAsksFirst() async {
        let viewModel = await makeViewModel(lists: [list("Zoology", articleCount: 3)])
        viewModel.requestDeletion(of: viewModel.readingLists)
        XCTAssertEqual(viewModel.pendingDeletion?.map { $0.name }, ["Zoology"])
        XCTAssertTrue(delegate.log.isEmpty)

        viewModel.cancelPendingDeletion()
        XCTAssertNil(viewModel.pendingDeletion)
        XCTAssertTrue(delegate.log.isEmpty)

        viewModel.requestDeletion(of: viewModel.readingLists)
        viewModel.confirmPendingDeletion()
        await waitForLog(count: 1)
        XCTAssertEqual(delegate.log, ["delete Zoology"])
    }

    func testBatchDeleteSkipsTheDefaultListAndClosesEditing() async {
        let viewModel = await makeViewModel(lists: [list("Saved", isDefault: true), list("Zoology"), list("animals")])
        viewModel.toggleEditing()
        viewModel.toggleSelection(for: viewModel.readingLists[1])
        viewModel.toggleSelection(for: viewModel.readingLists[2])
        viewModel.deleteSelectedReadingLists()
        await waitForLog(count: 1)
        XCTAssertEqual(delegate.log, ["delete animals,Zoology"])
        XCTAssertEqual(loggingDelegate.deletedCounts, [2])
        XCTAssertFalse(viewModel.isEditing)
    }

    func testTheDefaultListIsNeverDeleted() async {
        let viewModel = await makeViewModel(lists: [list("Saved", isDefault: true, articleCount: 2)])
        viewModel.requestDeletion(of: viewModel.readingLists)
        XCTAssertNil(viewModel.pendingDeletion)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(delegate.log.isEmpty)
    }

    // MARK: - Sorting

    func testSortOrderIsStoredAndApplied() async {
        let viewModel = await makeViewModel(lists: [list("Zoology"), list("animals")])
        XCTAssertEqual(viewModel.sortOrder, .byTitle)
        XCTAssertEqual(viewModel.readingLists.map { $0.name }, ["animals", "Zoology"])

        viewModel.setSortOrder(.byRecentlyAdded)
        XCTAssertEqual(viewModel.sortOrder, .byRecentlyAdded)
    }
}

private final class MockLoggingDelegate: WMFReadingListsLoggingDelegate {
    var editTaps = 0
    var deletedCounts: [Int] = []
    var errors: [Error] = []

    func readingListsDidTapEdit() { editTaps += 1 }
    func readingListsDidDelete(count: Int) { deletedCounts.append(count) }
    func readingListsDidFailToDelete(error: Error) { errors.append(error) }
}

private final class MockDelegate: WMFLegacyReadingListsDataControllerDelegate {
    var readingLists: [WMFReadingList] = []
    var initialSyncPending = false
    var log: [String] = []

    func fetchSavedArticles() async throws -> [WMFSavedArticle] { [] }
    func fetchReadingLists() async throws -> [WMFReadingList] { readingLists }
    func fetchArticles(inReadingList readingListID: String) async throws -> [WMFSavedArticle] { [] }
    func defaultReadingListID() async throws -> String? { readingLists.first { $0.isDefault }?.id }
    func isDefaultReadingListEnabled() async -> Bool { true }
    func isInitialSyncPending() async -> Bool { initialSyncPending }
    func sortOrder(forReadingList readingListID: String) async throws -> WMFReadingListSortOrder? { nil }
    func setSortOrder(_ sortOrder: WMFReadingListSortOrder, forReadingList readingListID: String) async throws {}
    func createReadingList(name: String, description: String?) async throws -> WMFReadingList {
        WMFReadingList(id: name, name: name, description: description, isDefault: false, createdDate: Date(), articleCount: 0, articleIDs: [])
    }
    func updateReadingList(id readingListID: String, name: String?, description: String?) async throws {}
    func deleteReadingLists(ids readingListIDs: [String]) async throws { log.append("delete \(readingListIDs.joined(separator: ","))") }
    func addArticles(ids articleIDs: [String], toReadingList readingListID: String) async throws {}
    func removeArticles(ids articleIDs: [String], fromReadingList readingListID: String) async throws {}
    func unsaveArticles(ids articleIDs: [String]) async throws {}
    func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void) { completion(true) }
}
