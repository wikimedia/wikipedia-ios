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
}
