import XCTest
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFSavedViewModelTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private var delegate: MockDelegate!
    private var loggingDelegate: MockLoggingDelegate!

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
        delegate = MockDelegate()
        loggingDelegate = MockLoggingDelegate()
    }

    override func tearDown() async throws {
        await fixture.tearDown()
        try await super.tearDown()
    }

    private func article(_ title: String) -> WMFSavedArticle {
        WMFSavedArticle(id: "\(project.id)|\(title)", title: title, project: project, savedDate: Date(timeIntervalSince1970: 1_000_000), readingListNames: [])
    }

    private func list(_ name: String, isDefault: Bool = false) -> WMFReadingList {
        WMFReadingList(id: name, name: name, description: nil, isDefault: isDefault, createdDate: Date(timeIntervalSince1970: 1_000_000), articleCount: 0, articleIDs: [])
    }

    private func makeViewModel(articles: [WMFSavedArticle] = [], lists: [WMFReadingList] = []) async -> WMFSavedViewModel {
        delegate.savedArticles = articles
        delegate.readingLists = lists
        let dataController = WMFLegacyReadingListsDataController(delegate: delegate, userDefaultsStore: WMFMockKeyValueStore())
        let allArticlesViewModel = WMFSavedAllArticlesViewModel(dataController: dataController)
        let readingListsViewModel = WMFReadingListsViewModel(dataController: dataController)
        let viewModel = WMFSavedViewModel(allArticlesViewModel: allArticlesViewModel, readingListsViewModel: readingListsViewModel, progressViewModel: WMFSavedProgressViewModel())
        viewModel.loggingDelegate = loggingDelegate
        allArticlesViewModel.loadArticles()
        readingListsViewModel.loadReadingLists()
        await waitUntil { allArticlesViewModel.state != .undefined && readingListsViewModel.state != .loading }
        return viewModel
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<50 where !condition() {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    // MARK: - Discover announcement

    func testTheAnnouncementIsSharedByBothSegmentsAndHidesOnBoth() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        await fixture.resetWMFDataTestState()
        WMFDeveloperSettingsDataController.shared.enableDiscover = true
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
        let announcementViewModel = WMFDiscoverAnnouncementViewModel()
        let dataController = WMFLegacyReadingListsDataController(delegate: delegate, userDefaultsStore: WMFMockKeyValueStore())
        let allArticlesViewModel = WMFSavedAllArticlesViewModel(dataController: dataController)
        let readingListsViewModel = WMFReadingListsViewModel(dataController: dataController)
        let viewModel = WMFSavedViewModel(allArticlesViewModel: allArticlesViewModel, readingListsViewModel: readingListsViewModel, progressViewModel: WMFSavedProgressViewModel(), announcementViewModel: announcementViewModel)

        XCTAssertTrue(viewModel.announcementViewModel === announcementViewModel)
        XCTAssertTrue(allArticlesViewModel.isAnnouncementVisible)
        XCTAssertTrue(readingListsViewModel.isAnnouncementVisible)

        announcementViewModel.tapNoThanks()

        XCTAssertFalse(allArticlesViewModel.isAnnouncementVisible)
        XCTAssertFalse(readingListsViewModel.isAnnouncementVisible)
    }

    func testWithoutAnAnnouncementTheSegmentsShowNoCard() async {
        let viewModel = await makeViewModel()
        XCTAssertNil(viewModel.announcementViewModel)
        XCTAssertFalse(viewModel.allArticlesViewModel.isAnnouncementVisible)
        XCTAssertFalse(viewModel.readingListsViewModel.isAnnouncementVisible)
    }

    // MARK: - Segments

    func testFirstLoadShowsAllArticlesAndLogsIt() async {
        let viewModel = await makeViewModel()
        viewModel.viewDidLoad()
        XCTAssertEqual(viewModel.segment, .allArticles)
        XCTAssertEqual(loggingDelegate.shownSegments, [.allArticles])
        XCTAssertTrue(loggingDelegate.selectedSegments.isEmpty)
    }

    func testSelectingASegmentLogsBothEvents() async {
        let viewModel = await makeViewModel()
        viewModel.selectSegment(.readingLists)
        XCTAssertEqual(viewModel.segment, .readingLists)
        XCTAssertEqual(loggingDelegate.shownSegments, [.readingLists])
        XCTAssertEqual(loggingDelegate.selectedSegments, [.readingLists])
    }

    func testSelectingTheSameSegmentDoesNothing() async {
        let viewModel = await makeViewModel()
        viewModel.selectSegment(.allArticles)
        XCTAssertTrue(loggingDelegate.shownSegments.isEmpty)
    }

    func testSearchPromptFollowsTheSegment() async {
        let viewModel = await makeViewModel()
        XCTAssertEqual(viewModel.searchPrompt, WMFSavedViewModel.Segment.allArticles.searchPrompt)
        viewModel.selectSegment(.readingLists)
        XCTAssertEqual(viewModel.searchPrompt, WMFSavedViewModel.Segment.readingLists.searchPrompt)
    }

    // MARK: - Search

    func testSearchTextReachesOnlyTheActiveSegment() async {
        let viewModel = await makeViewModel()
        viewModel.searchText = "dog"
        XCTAssertEqual(viewModel.allArticlesViewModel.searchText, "dog")
        XCTAssertEqual(viewModel.readingListsViewModel.searchText, "")
    }

    func testSelectingASegmentDismissesSearchAndClearsText() async {
        let viewModel = await makeViewModel()
        viewModel.isSearchPresented = true
        viewModel.searchText = "dog"
        viewModel.selectSegment(.readingLists)
        XCTAssertFalse(viewModel.isSearchPresented)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.allArticlesViewModel.searchText, "")
        XCTAssertEqual(viewModel.readingListsViewModel.searchText, "")
    }

    func testEndingSearchClearsTextAndReloadsAllArticles() async {
        let viewModel = await makeViewModel(articles: [article("Dog")])
        let fetchesBefore = delegate.savedArticlesFetches
        viewModel.isSearchPresented = true
        viewModel.searchText = "dog"
        viewModel.isSearchPresented = false
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.allArticlesViewModel.searchText, "")
        await waitUntil { self.delegate.savedArticlesFetches > fetchesBefore }
        XCTAssertGreaterThan(delegate.savedArticlesFetches, fetchesBefore)
    }

    // MARK: - Editing

    func testEditingMirrorsTheActiveSegment() async {
        let viewModel = await makeViewModel(articles: [article("Dog")])
        XCTAssertFalse(viewModel.isEditing)
        viewModel.toggleEditing()
        XCTAssertTrue(viewModel.isEditing)
        XCTAssertTrue(viewModel.allArticlesViewModel.isEditing)
        XCTAssertEqual(loggingDelegate.editAllArticlesTaps, 1)
        viewModel.cancelEditing()
        XCTAssertFalse(viewModel.isEditing)
        XCTAssertFalse(viewModel.allArticlesViewModel.isEditing)
    }

    func testEditingReadingListsNeedsACustomList() async {
        let onlyDefault = await makeViewModel(lists: [list("Saved", isDefault: true)])
        onlyDefault.selectSegment(.readingLists)
        XCTAssertFalse(onlyDefault.canEdit)
        onlyDefault.toggleEditing()
        XCTAssertFalse(onlyDefault.isEditing)

        let withCustom = await makeViewModel(lists: [list("Saved", isDefault: true), list("Zoology")])
        withCustom.selectSegment(.readingLists)
        XCTAssertTrue(withCustom.canEdit)
        withCustom.toggleEditing()
        XCTAssertTrue(withCustom.isEditing)
        XCTAssertTrue(withCustom.readingListsViewModel.isEditing)
        XCTAssertEqual(loggingDelegate.editAllArticlesTaps, 0, "the reading lists segment logs its own edit tap")
    }

    func testSwitchingSegmentsShowsTheOtherSegmentsEditingState() async {
        let viewModel = await makeViewModel(articles: [article("Dog")], lists: [list("Zoology")])
        viewModel.toggleEditing()
        XCTAssertTrue(viewModel.isEditing)
        viewModel.selectSegment(.readingLists)
        XCTAssertFalse(viewModel.isEditing)
        viewModel.selectSegment(.allArticles)
        XCTAssertTrue(viewModel.isEditing)
    }

    // MARK: - Sort

    func testSortOrderIsRoutedToTheActiveSegment() async {
        let viewModel = await makeViewModel(articles: [article("Dog")], lists: [list("Saved", isDefault: true), list("Zoology")])
        XCTAssertEqual(viewModel.sortOrder, .byRecentlyAdded)

        viewModel.setSortOrder(.byTitle)
        XCTAssertEqual(viewModel.sortOrder, .byTitle)
        await waitUntil { self.delegate.sortOrders["Saved"] == .byTitle }
        XCTAssertEqual(delegate.sortOrders["Saved"], .byTitle, "All articles persists on the default list")

        viewModel.selectSegment(.readingLists)
        XCTAssertEqual(viewModel.sortOrder, .byTitle, "reading lists default to title")
        viewModel.setSortOrder(.byRecentlyAdded)
        XCTAssertEqual(viewModel.sortOrder, .byRecentlyAdded)
        XCTAssertEqual(viewModel.readingListsViewModel.sortOrder, .byRecentlyAdded)
        XCTAssertEqual(viewModel.allArticlesViewModel.sortOrder, .byTitle, "the other segment keeps its order")
    }

    // MARK: - Navigation bar

    func testNavigationBarStaysWhenReadingListsAreEmpty() async {
        let viewModel = await makeViewModel()
        XCTAssertTrue(viewModel.hidesNavigationBarOnScroll)
        viewModel.selectSegment(.readingLists)
        XCTAssertFalse(viewModel.hidesNavigationBarOnScroll)
        viewModel.selectSegment(.allArticles)
        XCTAssertTrue(viewModel.hidesNavigationBarOnScroll)

        let withLists = await makeViewModel(lists: [list("Zoology")])
        withLists.selectSegment(.readingLists)
        XCTAssertTrue(withLists.hidesNavigationBarOnScroll)
    }

    func testProfileBadgeComesFromTheProvider() async {
        let viewModel = await makeViewModel()
        viewModel.profileButtonNeedsBadgeProvider = { true }
        viewModel.viewWillAppear()
        XCTAssertTrue(viewModel.profileButtonNeedsBadge)
        viewModel.profileButtonNeedsBadgeProvider = { false }
        viewModel.refreshProfileButtonBadge()
        XCTAssertFalse(viewModel.profileButtonNeedsBadge)
    }

    func testButtonTapsLogAndNavigate() async {
        let viewModel = await makeViewModel()
        var profileTaps = 0
        var tabsTaps = 0
        viewModel.didTapProfile = { profileTaps += 1 }
        viewModel.didTapTabs = { tabsTaps += 1 }
        viewModel.profileButtonTapped()
        viewModel.tabsButtonTapped()
        XCTAssertEqual(profileTaps, 1)
        XCTAssertEqual(tabsTaps, 1)
        XCTAssertEqual(loggingDelegate.profileTaps, 1)
        XCTAssertEqual(loggingDelegate.tabsTaps, 1)
    }
}

private final class MockLoggingDelegate: WMFSavedLoggingDelegate {
    var appearances = 0
    var shownSegments: [WMFSavedViewModel.Segment] = []
    var selectedSegments: [WMFSavedViewModel.Segment] = []
    var editAllArticlesTaps = 0
    var profileTaps = 0
    var tabsTaps = 0

    func savedDidAppear() { appearances += 1 }
    func savedDidShowSegment(_ segment: WMFSavedViewModel.Segment) { shownSegments.append(segment) }
    func savedDidSelectSegment(_ segment: WMFSavedViewModel.Segment) { selectedSegments.append(segment) }
    func savedDidTapEditAllArticles() { editAllArticlesTaps += 1 }
    func savedDidTapProfile() { profileTaps += 1 }
    func savedDidTapTabs() { tabsTaps += 1 }
}

private final class MockDelegate: WMFLegacyReadingListsDataControllerDelegate {
    var savedArticles: [WMFSavedArticle] = []
    var readingLists: [WMFReadingList] = []
    var sortOrders: [String: WMFReadingListSortOrder] = [:]
    var savedArticlesFetches = 0

    func fetchSavedArticles() async throws -> [WMFSavedArticle] {
        savedArticlesFetches += 1
        return savedArticles
    }
    func fetchReadingLists() async throws -> [WMFReadingList] { readingLists }
    func fetchArticles(inReadingList readingListID: String) async throws -> [WMFSavedArticle] { [] }
    func defaultReadingListID() async throws -> String? { readingLists.first { $0.isDefault }?.id }
    func isDefaultReadingListEnabled() async -> Bool { true }
    func sortOrder(forReadingList readingListID: String) async throws -> WMFReadingListSortOrder? { sortOrders[readingListID] }
    func setSortOrder(_ sortOrder: WMFReadingListSortOrder, forReadingList readingListID: String) async throws { sortOrders[readingListID] = sortOrder }
    func createReadingList(name: String, description: String?) async throws -> WMFReadingList {
        WMFReadingList(id: name, name: name, description: description, isDefault: false, createdDate: Date(), articleCount: 0, articleIDs: [])
    }
    func updateReadingList(id readingListID: String, name: String?, description: String?) async throws {}
    func deleteReadingLists(ids readingListIDs: [String]) async throws {}
    func addArticles(ids articleIDs: [String], toReadingList readingListID: String) async throws {}
    func removeArticles(ids articleIDs: [String], fromReadingList readingListID: String) async throws {}
    func unsaveArticles(ids articleIDs: [String]) async throws {}
    func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void) { completion(true) }
}
