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
        tabBarItem = UITabBarItem(title: "Saved", image: UIImage(systemName: "bookmark"), tag: 0)
        discover = DiscoverStub()
    }

    override func tearDown() async throws {
        controller = nil
        ProgressContainer.shared.articleFetcherProgress = nil
    }

    private func makeController() -> SavedTabBadgeController {
        SavedTabBadgeController(tabBarItem: tabBarItem, tabBar: nil, theme: .light, discoverDataController: discover)
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
        XCTAssertTrue(tabBarItem.selectedImage === tabBarItem.image, "no dot, so the selected state reuses the plain icon")
        XCTAssertEqual(discover.assignments, 0, "an off feature does not roll the experiment")
    }

    func testTheDotShowsUntilTheCardIsAnswered() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        let plainIcon = tabBarItem.image
        controller = makeController()
        XCTAssertEqual(controller.badge, .discoverAnnouncement)
        XCTAssertNil(tabBarItem.badgeValue, "the dot lives in the icon, not in the UIKit badge")
        XCTAssertEqual(tabBarItem.image?.renderingMode, .alwaysOriginal)
        XCTAssertEqual(tabBarItem.selectedImage?.renderingMode, .alwaysOriginal)
        XCTAssertFalse(tabBarItem.selectedImage === tabBarItem.image, "the selected state gets its own tint")
        XCTAssertEqual(discover.assignments, 1)

        discover.shouldShowAnnouncement = false
        controller.refreshDiscoverAnnouncement()

        XCTAssertEqual(controller.badge, .none)
        XCTAssertNil(tabBarItem.badgeValue)
        XCTAssertTrue(tabBarItem.image === plainIcon)
        XCTAssertTrue(tabBarItem.selectedImage === plainIcon)
    }

    func testTheStarReplacesTheDotAndTheDotComesBack() {
        discover.isEnabled = true
        discover.shouldShowAnnouncement = true
        controller = makeController()
        XCTAssertEqual(controller.badge, .discoverAnnouncement)

        controller.setSyncInProgress(true)
        XCTAssertEqual(controller.badge, .syncInProgress)
        XCTAssertEqual(tabBarItem.badgeValue, "\u{2605}")
        XCTAssertTrue(tabBarItem.selectedImage === tabBarItem.image, "the star uses the UIKit badge, so the icon is plain again")

        controller.setSyncInProgress(false)
        XCTAssertEqual(controller.badge, .discoverAnnouncement)
        XCTAssertNil(tabBarItem.badgeValue)
        XCTAssertFalse(tabBarItem.selectedImage === tabBarItem.image)
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

    func testTheDottedIconGrowsByTheInsetOnEverySide() throws {
        let icon = try XCTUnwrap(UIImage(systemName: "bookmark"))
        let dotted = SavedTabBadgeController.dottedIcon(icon, iconColor: .black, dotColor: .red)
        XCTAssertEqual(dotted.renderingMode, .alwaysOriginal)
        XCTAssertEqual(dotted.size.width, icon.size.width + 8, accuracy: 0.01)
        XCTAssertEqual(dotted.size.height, icon.size.height + 8, accuracy: 0.01)
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
