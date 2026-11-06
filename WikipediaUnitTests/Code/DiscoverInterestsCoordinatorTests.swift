import XCTest
@testable import Wikipedia
import WMF
import WMFComponents
import WMFData

@MainActor
final class DiscoverInterestsCoordinatorTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private var dataStore: MWKDataStore!
    private var interestsDataController: WMFDiscoverInterestsDataController!
    private var navigationController: UINavigationController!
    private var coordinator: DiscoverInterestsCoordinator!
    private var chosenSources: [WMFDiscoverSource] = []

    private let englishProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    override func setUp() async throws {
        dataStore = await withCheckedContinuation { continuation in
            MWKDataStore.createTemporaryDataStore { dataStore in
                continuation.resume(returning: dataStore)
            }
        }
        let store = InMemoryKeyValueStore()
        let coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        interestsDataController = WMFDiscoverInterestsDataController(coreDataStore: coreDataStore, userDefaultsStore: store)
        let readingListDataController = WMFDiscoverReadingListDataController(
            coreDataStore: coreDataStore,
            userDefaultsStore: store,
            relatedPagesDataController: WMFRelatedPagesDataController(basicService: nil),
            interestsDataController: interestsDataController
        )
        navigationController = UINavigationController(rootViewController: UIViewController())
        coordinator = DiscoverInterestsCoordinator(
            navigationController: navigationController,
            dataStore: dataStore,
            readingListDataController: readingListDataController,
            interestsDataController: interestsDataController
        )
        chosenSources = []
        coordinator.didChooseSource = { [weak self] source in
            self?.chosenSources.append(source)
        }
    }

    override func tearDown() async throws {
        dataStore.removeFolderAtBasePath()
    }

    private func makeStore(titles: [String]) -> WMFDiscoverInterestsStore {
        let pages = titles.map { WMFDiscoverInterests.Page(title: $0, project: englishProject) }
        return WMFDiscoverInterestsStore(interests: WMFDiscoverInterests(topics: [], pages: pages), dataController: interestsDataController)
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !condition() && Date() < deadline {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Back

    func testBackWithInterestsReportsInterestsAfterTheInterestsAreCommitted() async throws {
        let store = makeStore(titles: [])
        store.addPage(title: "Cat", project: englishProject)
        let savedBeforeBack = try await interestsDataController.fetchInterests()
        XCTAssertTrue(savedBeforeBack.isEmpty, "a tap changes only the screen")

        let shouldPop = coordinator.handleBack(store: store)
        await waitUntil { !self.chosenSources.isEmpty }

        XCTAssertFalse(shouldPop)
        XCTAssertEqual(chosenSources, [.interests])
        let saved = try await interestsDataController.fetchInterests()
        XCTAssertEqual(saved.pages.map(\.title), ["Cat"])
    }

    func testBackWithoutInterestsReportsNothing() async throws {
        let shouldPop = coordinator.handleBack(store: makeStore(titles: []))
        await Task.yield()

        XCTAssertFalse(shouldPop)
        XCTAssertTrue(chosenSources.isEmpty)
    }

    func testUseReadingHistoryReportsHistory() async throws {
        coordinator.chooseSource(.history, store: makeStore(titles: []))
        await waitUntil { !self.chosenSources.isEmpty }

        XCTAssertEqual(chosenSources, [.history])
    }

    // MARK: - Alert

    func testAlertWithSavedArticlesAndReadingHistoryOffersBoth() {
        let alert = coordinator.makeSelectInterestsAlert(alternativeSources: [.saved, .history], store: makeStore(titles: []))

        XCTAssertEqual(alert.title, DiscoverInterestsCoordinator.alertTitle)
        XCTAssertEqual(alert.message, DiscoverInterestsCoordinator.alertMessageWithSavedAndHistory)
        XCTAssertEqual(alert.actions.map(\.title), [
            DiscoverInterestsCoordinator.alertSelectInterests,
            DiscoverInterestsCoordinator.alertUseSavedArticles,
            DiscoverInterestsCoordinator.alertUseReadingHistory
        ])
    }

    func testAlertWithOnlySavedArticlesOffersSavedArticles() {
        let alert = coordinator.makeSelectInterestsAlert(alternativeSources: [.saved], store: makeStore(titles: []))

        XCTAssertEqual(alert.message, DiscoverInterestsCoordinator.alertMessageWithSaved)
        XCTAssertEqual(alert.actions.map(\.title), [DiscoverInterestsCoordinator.alertSelectInterests, DiscoverInterestsCoordinator.alertUseSavedArticles])
    }

    func testAlertWithOnlyReadingHistoryOffersReadingHistory() {
        let alert = coordinator.makeSelectInterestsAlert(alternativeSources: [.history], store: makeStore(titles: []))

        XCTAssertEqual(alert.message, DiscoverInterestsCoordinator.alertMessageWithHistory)
        XCTAssertEqual(alert.actions.map(\.title), [DiscoverInterestsCoordinator.alertSelectInterests, DiscoverInterestsCoordinator.alertUseReadingHistory])
    }

    func testAlertWithoutOtherSourcesOnlyAsksToSelectInterests() {
        let alert = coordinator.makeSelectInterestsAlert(alternativeSources: [], store: makeStore(titles: []))

        XCTAssertEqual(alert.title, DiscoverInterestsCoordinator.alertTitle)
        XCTAssertEqual(alert.message, DiscoverInterestsCoordinator.alertMessageWithoutSources)
        XCTAssertEqual(alert.actions.map(\.title), [DiscoverInterestsCoordinator.alertSelectInterests])
    }

    func testSavedArticlesFromTheAlertReportsSaved() async throws {
        let alert = coordinator.makeSelectInterestsAlert(alternativeSources: [.saved], store: makeStore(titles: []))
        XCTAssertEqual(alert.actions.count, 2)

        coordinator.chooseSource(.saved, store: makeStore(titles: []))
        await waitUntil { !self.chosenSources.isEmpty }

        XCTAssertEqual(chosenSources, [.saved])
    }
}
