import XCTest
@testable import Wikipedia
import WMF
import WMFComponents
import WMFData

@MainActor
final class DiscoverSettingsCoordinatorTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private var dataStore: MWKDataStore!
    private var store: InMemoryKeyValueStore!
    private var dataController: WMFDiscoverReadingListDataController!

    override func setUp() async throws {
        dataStore = await withCheckedContinuation { continuation in
            MWKDataStore.createTemporaryDataStore { dataStore in
                continuation.resume(returning: dataStore)
            }
        }
        store = InMemoryKeyValueStore()
        dataController = WMFDiscoverReadingListDataController(
            coreDataStore: try await fixture.makeTemporaryCoreDataStore(),
            userDefaultsStore: store,
            relatedPagesDataController: WMFRelatedPagesDataController(basicService: nil)
        )
    }

    override func tearDown() async throws {
        dataStore.removeFolderAtBasePath()
    }

    private func makeCoordinator(navigationController: UINavigationController, origin: DiscoverSettingsCoordinator.Origin = .settings) -> DiscoverSettingsCoordinator {
        DiscoverSettingsCoordinator(navigationController: navigationController, dataStore: dataStore, theme: .light, origin: origin, readingListDataController: dataController)
    }

    private func saveSettings(source: WMFDiscoverSource, articleCount: Int) async throws -> WMFDiscoverSettings {
        let settings = WMFDiscoverSettings(isEnabled: true, articleCount: articleCount, cadence: .weekly, source: source)
        try await dataController.saveSettings(settings)
        return settings
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !condition() && Date() < deadline {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    func testUndoRefreshesTheSettingsScreenOnTop() async throws {
        let settings = try await saveSettings(source: .saved, articleCount: 5)
        let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController)
        let navigationController = UINavigationController(rootViewController: WMFDiscoverSettingsHostingController(viewModel: viewModel))
        _ = try await saveSettings(source: .history, articleCount: 5)

        DiscoverSettingsCoordinator.refreshScreen(onTopOf: navigationController, dataController: dataController)
        await waitUntil { viewModel.settings.source == .history }

        XCTAssertEqual(viewModel.settings.source, .history)
    }

    func testUndoReloadsTheDiscoverListOnTop() async throws {
        _ = try await saveSettings(source: .saved, articleCount: 5)
        let viewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)
        let navigationController = UINavigationController(rootViewController: WMFDiscoverReadingListHostingController(viewModel: viewModel))
        viewModel.load()
        await waitUntil { viewModel.state != .loading }
        _ = try await saveSettings(source: .saved, articleCount: 7)

        DiscoverSettingsCoordinator.refreshScreen(onTopOf: navigationController, dataController: dataController)
        await waitUntil { viewModel.settings.articleCount == 7 }

        XCTAssertEqual(viewModel.settings.articleCount, 7)
    }

    /// Undo after Back lands on Settings. No screen there shows the list, so the coordinator makes it.
    func testUndoOnSettingsMakesTheListWhenItIsOutOfDate() async throws {
        _ = try await saveSettings(source: .interests, articleCount: 5)
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let runPosts = expectListStatePosts(count: 2)

        DiscoverSettingsCoordinator.refreshScreen(onTopOf: navigationController, dataController: dataController)

        await fulfillment(of: [runPosts], timeout: 5)
    }

    // MARK: - Discover turned off

    /// From Customize the Discover list is under the settings. Off, the list goes away, so Back
    /// lands on the Saved tab.
    func testTurnOffFromTheDiscoverListRemovesTheListUnderneath() async throws {
        let settings = try await saveSettings(source: .saved, articleCount: 5)
        let savedController = UIViewController()
        let listViewModel = WMFDiscoverReadingListViewModel(username: nil, dataController: dataController)
        let navigationController = UINavigationController(rootViewController: savedController)
        navigationController.pushViewController(WMFDiscoverReadingListHostingController(viewModel: listViewModel), animated: false)
        let coordinator = makeCoordinator(navigationController: navigationController, origin: .discoverReadingList)
        let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController)
        coordinator.showSettings(viewModel: viewModel)
        await waitUntil { navigationController.viewControllers.count == 3 }

        viewModel.didTurnOff?()

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertTrue(navigationController.viewControllers.first === savedController)
        XCTAssertTrue(navigationController.topViewController is WMFDiscoverSettingsHostingController)
    }

    func testTurnOffFromSettingsKeepsTheStack() async throws {
        let settings = try await saveSettings(source: .saved, articleCount: 5)
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(UIViewController(), animated: false)
        let coordinator = makeCoordinator(navigationController: navigationController)
        let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController)
        coordinator.showSettings(viewModel: viewModel)
        await waitUntil { navigationController.viewControllers.count == 3 }

        viewModel.didTurnOff?()

        XCTAssertEqual(navigationController.viewControllers.count, 3)
    }

    // MARK: - Back from the Discover settings

    func testBackFromTheDiscoverSettingsMakesTheList() async throws {
        let settings = try await saveSettings(source: .interests, articleCount: 5)
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)
        let viewModel = WMFDiscoverSettingsViewModel(settings: settings, dataController: dataController)
        coordinator.showSettings(viewModel: viewModel)
        let runPosts = expectListStatePosts(count: 2)

        viewModel.leave()

        await fulfillment(of: [runPosts], timeout: 5)
    }

    /// A run posts the list state when it starts and when it ends, so two posts mean one run.
    private func expectListStatePosts(count: Int) -> XCTestExpectation {
        let runPosts = expectation(forNotification: WMFNSNotification.discoverListStateDidChange, object: nil)
        runPosts.expectedFulfillmentCount = count
        return runPosts
    }

    // MARK: - Done on the interests screen

    func testDoneWithInterestsOnlyPopsTheScreen() async throws {
        _ = try await saveSettings(source: .interests, articleCount: 5)
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(UIViewController(), animated: false)
        let coordinator = makeCoordinator(navigationController: navigationController)

        coordinator.leaveInterests()
        await Task.yield()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        let settings = await dataController.settings
        XCTAssertEqual(settings.source, .interests)
    }

    func testDoneWithInterestsAlsoClosesTheSourceScreenUnderneath() async throws {
        _ = try await saveSettings(source: .saved, articleCount: 5)
        let sourceViewModel = WMFDiscoverSetupViewModel(availableSources: [.interests, .saved, .history], currentSource: .saved, presentation: .settings, readingListDataController: dataController)
        let sourceController = WMFDiscoverSetupHostingController(viewModel: sourceViewModel)
        let rootController = UIViewController()
        let navigationController = UINavigationController(rootViewController: rootController)
        navigationController.pushViewController(sourceController, animated: false)
        navigationController.pushViewController(UIViewController(), animated: false)
        let coordinator = makeCoordinator(navigationController: navigationController)

        coordinator.leaveInterests()
        await waitUntil { navigationController.viewControllers.count == 1 }
        await waitUntilAsync { await self.dataController.settings.source == .interests }

        XCTAssertTrue(navigationController.topViewController === rootController)
        let settings = await dataController.settings
        XCTAssertEqual(settings.source, .interests)
        XCTAssertEqual(settings.articleCount, 5, "only the source changes")
    }

    func testAdjustToSavedArticlesClosesTheSourceScreen() async throws {
        _ = try await saveSettings(source: .interests, articleCount: 5)
        let sourceViewModel = WMFDiscoverSetupViewModel(availableSources: [.interests, .saved, .history], currentSource: .interests, presentation: .settings, readingListDataController: dataController)
        let rootController = UIViewController()
        let navigationController = UINavigationController(rootViewController: rootController)
        let coordinator = makeCoordinator(navigationController: navigationController)
        coordinator.showSource(viewModel: sourceViewModel)
        await waitUntil { navigationController.viewControllers.count == 2 }

        sourceViewModel.select(.saved)
        sourceViewModel.confirmAdjust()
        await waitUntil { navigationController.viewControllers.count == 1 }

        XCTAssertTrue(navigationController.topViewController === rootController)
        XCTAssertEqual(sourceViewModel.selectedSource, .saved)
        let settings = await dataController.settings
        XCTAssertEqual(settings.source, .saved)
        XCTAssertEqual(settings.articleCount, 5, "only the source changes")
    }

    private func waitUntilAsync(_ condition: @MainActor () async -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while await !condition() && Date() < deadline {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

