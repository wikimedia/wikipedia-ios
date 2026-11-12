import XCTest
import WMFDataMocks
@testable import WMFComponents
@testable import WMFData

/// Covers the state the persistent Home header depends on. The header, and with it the segmented
/// control, lives outside the selected-feed conditional, so what used to be per-branch layout is now
/// a measurement Community reserves space against and a binding a drag writes to repeatedly.
@MainActor
final class WMFHomeHeaderTests: XCTestCase {

    private func makeViewModel() -> WMFHomeViewModel {
        WMFHomeViewModel(dataController: WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore()))
    }

    // MARK: - Community top inset

    func testCommunityReservesTheMeasuredHeaderBottom() {
        let inset = WMFHomeHeaderMetrics.communityTopInset(measuredHeaderBottom: 160, headerTopInset: 111)
        XCTAssertEqual(inset, 160)
    }

    /// The measurement is zero until the first layout pass lands it. Community must not start its
    /// resting content at the top of the screen in the meantime.
    func testCommunityFallsBackToTheHeaderTopInsetBeforeTheMeasurementLands() {
        let inset = WMFHomeHeaderMetrics.communityTopInset(measuredHeaderBottom: 0, headerTopInset: 111)
        XCTAssertEqual(inset, 111)
    }

    /// A stale or short measurement still cannot pull content up under the header's own offset.
    func testCommunityNeverReservesLessThanTheHeaderTopInset() {
        let inset = WMFHomeHeaderMetrics.communityTopInset(measuredHeaderBottom: 40, headerTopInset: 111)
        XCTAssertEqual(inset, 111)
    }

    // MARK: - Tab change plumbing

    func testChangingTabNotifiesOnce() {
        let vm = makeViewModel()
        vm.selectedTab = .community

        var observed: [WMFHomeViewModel.Tab] = []
        vm.didChangeTab = { observed.append($0) }

        vm.selectedTab = .forYou
        XCTAssertEqual(observed, [.forYou])
    }

    /// The segmented control writes the selection continuously while a finger drags across it, so a
    /// write that does not change the tab must stay silent rather than re-running the tab-change work.
    func testWritingTheSameTabDoesNotNotify() {
        let vm = makeViewModel()
        vm.selectedTab = .forYou

        var callCount = 0
        vm.didChangeTab = { _ in callCount += 1 }

        vm.selectedTab = .forYou
        vm.selectedTab = .forYou
        XCTAssertEqual(callCount, 0)

        vm.selectedTab = .community
        XCTAssertEqual(callCount, 1)
    }

    /// The one piece of header content that is conditional. It has to keep tracking the tab now that
    /// the header itself no longer changes with it.
    func testLanguagePickerVisibilityStillFollowsTheSelectedTab() {
        let vm = makeViewModel()
        vm.makeEmbeddedCommunityViewController = { UIViewController() }

        vm.selectedTab = .community
        XCTAssertFalse(vm.shouldShowLanguagePicker)

        vm.selectedTab = .forYou
        XCTAssertTrue(vm.shouldShowLanguagePicker)
    }
}
