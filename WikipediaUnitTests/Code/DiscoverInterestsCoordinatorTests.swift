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
    private var finishCount = 0

    private let englishProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    override func setUp() async throws {
        dataStore = await withCheckedContinuation { continuation in
            MWKDataStore.createTemporaryDataStore { dataStore in
                continuation.resume(returning: dataStore)
            }
        }
        let coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        interestsDataController = WMFDiscoverInterestsDataController(coreDataStore: coreDataStore, userDefaultsStore: InMemoryKeyValueStore())
        navigationController = UINavigationController(rootViewController: UIViewController())
        coordinator = DiscoverInterestsCoordinator(
            navigationController: navigationController,
            dataStore: dataStore,
            interestsDataController: interestsDataController
        )
        finishCount = 0
        coordinator.didFinish = { [weak self] in
            self?.finishCount += 1
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

    // MARK: - Done

    func testDoneWithInterestsReportsAfterTheInterestsAreCommitted() async throws {
        let store = makeStore(titles: [])
        store.addPage(title: "Cat", project: englishProject)
        let savedBeforeDone = try await interestsDataController.fetchInterests()
        XCTAssertTrue(savedBeforeDone.isEmpty, "a tap changes only the screen")

        coordinator.finish(store: store)
        await waitUntil { self.finishCount > 0 }

        XCTAssertEqual(finishCount, 1)
        let saved = try await interestsDataController.fetchInterests()
        XCTAssertEqual(saved.pages.map(\.title), ["Cat"])
    }

    func testDoneWithoutInterestsDoesNothing() async throws {
        coordinator.finish(store: makeStore(titles: []))
        await Task.yield()

        XCTAssertEqual(finishCount, 0)
        let saved = try await interestsDataController.fetchInterests()
        XCTAssertTrue(saved.isEmpty)
    }

    func testTwoTapsOnDoneReportOnce() async throws {
        let store = makeStore(titles: ["Cat"])

        coordinator.finish(store: store)
        coordinator.finish(store: store)
        await waitUntil { self.finishCount > 0 }
        await Task.yield()

        XCTAssertEqual(finishCount, 1)
        let saved = try await interestsDataController.fetchInterests()
        XCTAssertEqual(saved.pages.map(\.title), ["Cat"])
    }

    /// After the commit the screen closes, but the caller can still be at work: Get started saves
    /// the settings before it pushes the list. A tap in that window must not report again.
    func testATapAfterTheCommitDoesNothing() async throws {
        let store = makeStore(titles: ["Cat"])

        coordinator.finish(store: store)
        await waitUntil { self.finishCount > 0 }
        XCTAssertEqual(finishCount, 1)
        XCTAssertTrue(coordinator.isFinishing, "the coordinator stays finished, so a tap starts no second commit")

        coordinator.finish(store: store)
        await Task.yield()
        XCTAssertEqual(finishCount, 1)
    }

    /// Without a Core Data store the commit throws. The screen stays, and the next tap tries again.
    func testDoneKeepsTheScreenWhenTheCommitFails() async throws {
        try await fixture.withConfiguredEnvironment(configure: { WMFDataEnvironment.current.coreDataStore = nil }) {
            let failingDataController = WMFDiscoverInterestsDataController(coreDataStore: nil, userDefaultsStore: InMemoryKeyValueStore())
            let store = WMFDiscoverInterestsStore(interests: WMFDiscoverInterests(topics: [], pages: [WMFDiscoverInterests.Page(title: "Cat", project: englishProject)]), dataController: failingDataController)
            let savedBeforeDone = try? await failingDataController.fetchInterests()
            XCTAssertNil(savedBeforeDone, "the store has no Core Data")

            coordinator.finish(store: store)
            XCTAssertTrue(coordinator.isFinishing)
            await waitUntil { !self.coordinator.isFinishing }
            XCTAssertEqual(finishCount, 0)

            coordinator.finish(store: store)
            XCTAssertTrue(coordinator.isFinishing, "the next tap tries again")
            await waitUntil { !self.coordinator.isFinishing }
            XCTAssertEqual(finishCount, 0)
        }
    }
}
