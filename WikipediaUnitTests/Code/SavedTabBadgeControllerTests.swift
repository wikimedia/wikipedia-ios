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
    private var exposures = 0

    override func setUp() async throws {
        ProgressContainer.shared.articleFetcherProgress = nil
        tabBarItem = UITabBarItem(title: "Saved", image: nil, tag: 0)
        discover = DiscoverStub()
        exposures = 0
    }

    override func tearDown() async throws {
        controller = nil
        ProgressContainer.shared.articleFetcherProgress = nil
    }

    private func makeController(tabBar: UITabBar? = nil, userInterfaceIdiom: UIUserInterfaceIdiom = .phone) -> SavedTabBadgeController {
        SavedTabBadgeController(tabBarItem: tabBarItem, tabBar: tabBar, theme: .light, userInterfaceIdiom: userInterfaceIdiom, discoverDataController: discover, logDiscoverExperimentExposure: { [unowned self] in self.exposures += 1 })
    }

    private func makeTabBar() -> UITabBar {
        let tabBar = UITabBar()
        tabBar.items = [tabBarItem]
        return tabBar
    }

    private func badgeBackgroundColor(of tabBar: UITabBar) -> UIColor? {
        tabBar.standardAppearance.stackedLayoutAppearance.normal.badgeBackgroundColor
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
        XCTAssertEqual(exposures, 0, "an off feature sends no exposure")
    }

    func testTheDotShowsUntilTheCardIsAnswered() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController()
        XCTAssertEqual(controller.badge, .discover)
        XCTAssertEqual(tabBarItem.badgeValue, "")
        XCTAssertEqual(discover.assignments, 1)
        XCTAssertEqual(exposures, 1, "the exposure goes out with the bucket")

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
        XCTAssertEqual(tabBarItem.badgeValue, "")

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
        XCTAssertEqual(tabBarItem.badgeValue, "")
    }

    func testTheDotIsRedOnlyWhileItIsTheOnlyBadge() {
        XCTAssertEqual(SavedTabBadgeController.badgeStyle(for: .discover, hasOtherBadges: false), .alert)
        XCTAssertEqual(SavedTabBadgeController.badgeStyle(for: .discover, hasOtherBadges: true), .theme)
        XCTAssertEqual(SavedTabBadgeController.badgeStyle(for: .syncInProgress, hasOtherBadges: false), .theme)
        XCTAssertEqual(SavedTabBadgeController.badgeStyle(for: .none, hasOtherBadges: false), .theme)
    }

    func testAnotherBadgeTurnsTheDotToTheThemeColor() {
        let theme = Theme.light
        let tabBar = makeTabBar()
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController(tabBar: tabBar)
        XCTAssertEqual(controller.badgeStyle, .alert)
        XCTAssertEqual(badgeBackgroundColor(of: tabBar), theme.colors.destructive)

        controller.setHasOtherBadges(true)
        XCTAssertEqual(controller.badgeStyle, .theme)
        XCTAssertEqual(badgeBackgroundColor(of: tabBar), theme.colors.accent)
        XCTAssertEqual(tabBarItem.badgeValue, "", "the dot stays, in the theme color")

        controller.setHasOtherBadges(false)
        XCTAssertEqual(controller.badgeStyle, .alert)
        XCTAssertEqual(badgeBackgroundColor(of: tabBar), theme.colors.destructive)
    }

    func testTheStarUsesTheThemeColor() {
        let theme = Theme.light
        let tabBar = makeTabBar()
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController(tabBar: tabBar)

        controller.setSyncInProgress(true)
        XCTAssertEqual(controller.badgeStyle, .theme)
        XCTAssertEqual(badgeBackgroundColor(of: tabBar), theme.colors.accent)

        controller.setSyncInProgress(false)
        XCTAssertEqual(controller.badgeStyle, .alert)
        XCTAssertEqual(badgeBackgroundColor(of: tabBar), theme.colors.destructive)
    }

    func testTheThemeKeepsTheDotColor() {
        let tabBar = makeTabBar()
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController(tabBar: tabBar)

        tabBar.standardAppearance = UITabBarAppearance.appearanceForTheme(.dark)
        controller.apply(theme: .dark)
        XCTAssertEqual(badgeBackgroundColor(of: tabBar), Theme.dark.colors.destructive)
        XCTAssertEqual(tabBarItem.badgeValue, "")
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
