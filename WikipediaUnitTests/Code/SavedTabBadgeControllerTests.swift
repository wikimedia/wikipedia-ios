import XCTest
@testable import Wikipedia
import WMF
import WMFComponents
import WMFData

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
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: false, showsDiscoverDot: false), .none)
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: false, showsDiscoverDot: true), .discover)
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: true, showsDiscoverDot: false), .syncInProgress)
        XCTAssertEqual(SavedTabBadgeController.badge(isSyncInProgress: true, showsDiscoverDot: true), .syncInProgress)
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
        XCTAssertEqual(controller.badge, .discover)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{25CF}")
        XCTAssertEqual(discover.assignments, 1)

        discover.shouldShowAnnouncement = false
        controller.refreshDiscover()

        XCTAssertEqual(controller.badge, .none)
        XCTAssertNil(tabBarItem.badgeValue)
    }

    func testAnUnseenListShowsTheDotAfterTheCardIsAnswered() {
        discover.isEnabled = true
        discover.shouldShowUnseenListBadge = true
        controller = makeController()
        XCTAssertEqual(controller.badge, .discover)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{25CF}")

        discover.shouldShowUnseenListBadge = false
        controller.refreshDiscover()

        XCTAssertEqual(controller.badge, .none)
        XCTAssertNil(tabBarItem.badgeValue)
    }

    func testAListStateChangeRefreshesTheDot() async {
        discover.isEnabled = true
        controller = makeController()
        XCTAssertEqual(controller.badge, .none)

        discover.shouldShowUnseenListBadge = true
        NotificationCenter.default.post(name: WMFNSNotification.discoverListStateDidChange, object: nil)
        await wait(seconds: 0.1)

        XCTAssertEqual(controller.badge, .discover)
    }

    func testTheStarReplacesTheDotAndTheDotComesBack() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController()
        XCTAssertEqual(controller.badge, .discover)

        controller.setSyncInProgress(true)
        XCTAssertEqual(controller.badge, .syncInProgress)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{2605}")

        controller.setSyncInProgress(false)
        XCTAssertEqual(controller.badge, .discover)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{25CF}")
    }

    func testTheDotIsABlankGlyphOnTheIPad() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController(userInterfaceIdiom: .pad)
        XCTAssertEqual(controller.badge, .discover)
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

    private final class DiscoverStub: SavedTabDiscoverProviding {
        var isEnabled = false
        var shouldShowAnnouncement = false
        var shouldShowUnseenListBadge = false
        var assignments = 0

        func assignExperimentBucketIfNeeded() throws {
            assignments += 1
        }
    }
}
