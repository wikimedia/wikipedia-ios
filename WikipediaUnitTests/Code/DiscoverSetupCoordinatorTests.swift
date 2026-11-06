import XCTest
@testable import Wikipedia
import WMF
import WMFComponents
import WMFData

@MainActor
final class DiscoverSetupCoordinatorTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private var dataStore: MWKDataStore!
    private var announcementDismisser: AnnouncementDismisserStub!
    private var readingListDataController: WMFDiscoverReadingListDataController!
    private var navigationController: UINavigationController!
    private var coordinator: DiscoverSetupCoordinator!

    override func setUp() async throws {
        dataStore = await withCheckedContinuation { continuation in
            MWKDataStore.createTemporaryDataStore { dataStore in
                continuation.resume(returning: dataStore)
            }
        }
        let store = InMemoryKeyValueStore()
        announcementDismisser = AnnouncementDismisserStub()
        let coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        let interestsDataController = WMFDiscoverInterestsDataController(coreDataStore: coreDataStore, userDefaultsStore: store)
        readingListDataController = WMFDiscoverReadingListDataController(
            coreDataStore: coreDataStore,
            userDefaultsStore: store,
            relatedPagesDataController: WMFRelatedPagesDataController(basicService: nil),
            interestsDataController: interestsDataController
        )
        navigationController = UINavigationController(rootViewController: UIViewController())
        coordinator = DiscoverSetupCoordinator(
            navigationController: navigationController,
            dataStore: dataStore,
            theme: .light,
            readingListDataController: readingListDataController,
            discoverDataController: announcementDismisser,
            interestsDataController: interestsDataController
        )
    }

    override func tearDown() async throws {
        dataStore.removeFolderAtBasePath()
    }

    private func waitUntil(_ condition: @MainActor () async -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while await !condition() && Date() < deadline {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Turning Discover on

    func testInterestsTurnDiscoverOnAndOpenTheList() async throws {
        coordinator.turnOnDiscover(source: .interests)
        await waitUntil { await self.readingListDataController.settings.isEnabled }

        let settings = await readingListDataController.settings
        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.source, .interests)
        XCTAssertEqual(announcementDismisser.dismissals, 1)
        XCTAssertTrue(navigationController.topViewController is WMFDiscoverReadingListHostingController)
    }

    func testReadingHistoryFromTheAlertTurnsDiscoverOnWithHistoryAsTheSource() async throws {
        coordinator.turnOnDiscover(source: .history)
        await waitUntil { await self.readingListDataController.settings.isEnabled }

        let settings = await readingListDataController.settings
        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.source, .history)
        XCTAssertEqual(announcementDismisser.dismissals, 1)
    }

    func testTheListTakesThePlaceOfTheSetupScreen() async throws {
        coordinator.start()
        await waitUntil { self.navigationController.topViewController is WMFDiscoverSetupHostingController }

        coordinator.turnOnDiscover(source: .saved)
        await waitUntil { self.navigationController.topViewController is WMFDiscoverReadingListHostingController }

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertFalse(navigationController.viewControllers.contains { $0 is WMFDiscoverSetupHostingController })
    }
}

/// Counts the announcement dismissals instead of writing to the live user defaults.
@MainActor
private final class AnnouncementDismisserStub: DiscoverAnnouncementDismissing {
    var dismissals = 0

    func markAnnouncementDismissed() throws {
        dismissals += 1
    }
}
