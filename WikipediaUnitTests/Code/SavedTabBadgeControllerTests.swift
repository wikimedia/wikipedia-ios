import XCTest
@testable import Wikipedia
import WMF
import WMFComponents

@MainActor
final class SavedTabBadgeControllerTests: XCTestCase {

    private var tabBarItem: UITabBarItem!
    private var discover: DiscoverStub!
    private var controller: SavedTabBadgeController!

    override func setUp() async throws {
        ProgressContainer.shared.articleFetcherProgress = nil
        tabBarItem = UITabBarItem(title: "Saved", image: nil, tag: 0)
        discover = DiscoverStub()
    }

    override func tearDown() async throws {
        controller = nil
        ProgressContainer.shared.articleFetcherProgress = nil
    }

    private func makeController(userInterfaceIdiom: UIUserInterfaceIdiom = .phone) -> SavedTabBadgeController {
        SavedTabBadgeController(tabBarItem: tabBarItem, tabBar: nil, theme: .light, userInterfaceIdiom: userInterfaceIdiom, discoverDataController: discover)
    }

    private func wait(seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    func testTheStarWinsOverTheDiscoverDot() {
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: false, showsDiscoverAnnouncement: false), .none)
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: false, showsDiscoverAnnouncement: true), .discoverAnnouncement)
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: true, showsDiscoverAnnouncement: false), .syncInProgress)
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: true, showsDiscoverAnnouncement: true), .syncInProgress)
    }

    func testNoBadgeWhileDiscoverIsOff() {
        controller = makeController()
        XCTAssertEqual(controller.badge, .none)
        XCTAssertNil(tabBarItem.badgeValue)
        XCTAssertEqual(discover.assignments, 0, "an off feature does not roll the experiment")
    }

    func testTheDotShowsUntilTheCardIsAnswered() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController()
        XCTAssertEqual(controller.badge, .discoverAnnouncement)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{25CF}")
        XCTAssertEqual(discover.assignments, 1)

        discover.shouldShowAnnouncement = false
        controller.refreshDiscoverAnnouncement()

        XCTAssertEqual(controller.badge, .none)
        XCTAssertNil(tabBarItem.badgeValue)
    }

    func testTheStarReplacesTheDotAndTheDotComesBack() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController()
        XCTAssertEqual(controller.badge, .discoverAnnouncement)

        controller.setSyncInProgress(true)
        XCTAssertEqual(controller.badge, .syncInProgress)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{2605}")

        controller.setSyncInProgress(false)
        XCTAssertEqual(controller.badge, .discoverAnnouncement)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{25CF}")
    }

    func testTheDotIsABlankGlyphOnTheIPad() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController(userInterfaceIdiom: .pad)
        XCTAssertEqual(controller.badge, .discoverAnnouncement)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{2800}")
    }

    func testTheStarFollowsTheDownloadProgress() async {
        controller = makeController()
        let progress = Progress.discreteProgress(totalUnitCount: -1)
        ProgressContainer.shared.articleFetcherProgress = progress
        progress.totalUnitCount = 2
        progress.completedUnitCount = 0

        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertEqual(controller.badge, .syncInProgress)

        progress.completedUnitCount = 2
        await wait(seconds: 0.1)
        XCTAssertEqual(controller.badge, .none)
    }

    private final class DiscoverStub: SavedTabDiscoverAnnouncementProviding {
        var isEnabled = false
        var shouldShowAnnouncement = false
        var assignments = 0

        func assignExperimentBucketIfNeeded() throws {
            assignments += 1
        }
    }
}
