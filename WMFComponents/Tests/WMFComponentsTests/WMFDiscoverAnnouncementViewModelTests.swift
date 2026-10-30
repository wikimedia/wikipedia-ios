import XCTest
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFDiscoverAnnouncementViewModelTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private var loggingDelegate: MockLoggingDelegate!

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        await fixture.resetWMFDataTestState()
        WMFDeveloperSettingsDataController.shared.enableDiscover = true
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
        loggingDelegate = MockLoggingDelegate()
    }

    override func tearDown() async throws {
        await fixture.tearDown()
        try await super.tearDown()
    }

    private func makeViewModel() -> WMFDiscoverAnnouncementViewModel {
        let viewModel = WMFDiscoverAnnouncementViewModel()
        viewModel.loggingDelegate = loggingDelegate
        return viewModel
    }

    func testTheCardShowsForGroupBUntilItIsAnswered() {
        XCTAssertTrue(makeViewModel().isVisible)

        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control
        XCTAssertFalse(makeViewModel().isVisible)

        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
        WMFDeveloperSettingsDataController.shared.enableDiscover = false
        XCTAssertFalse(makeViewModel().isVisible)
    }

    func testGetStartedKeepsTheCardAndCallsBack() {
        let viewModel = makeViewModel()
        var getStartedTaps = 0
        var dismissals = 0
        viewModel.didTapGetStarted = { getStartedTaps += 1 }
        viewModel.didDismiss = { dismissals += 1 }

        viewModel.tapGetStarted()

        XCTAssertTrue(viewModel.isVisible, "the card stays until Discover is on, like on Android")
        XCTAssertEqual(getStartedTaps, 1)
        XCTAssertEqual(dismissals, 0)
        XCTAssertFalse(WMFDiscoverDataController.shared.hasDismissedAnnouncement)
        XCTAssertEqual(loggingDelegate.getStartedTaps, 1)
    }

    func testTheCardGoesAwayOnceDiscoverIsOn() throws {
        let viewModel = makeViewModel()
        viewModel.tapGetStarted()

        try WMFDiscoverDataController.shared.markAnnouncementDismissed()
        viewModel.refresh()

        XCTAssertFalse(viewModel.isVisible)
        XCTAssertFalse(makeViewModel().isVisible, "a new instance reads the persisted state")
    }

    func testNoThanksHidesTheCardForGoodAndCallsBack() {
        let viewModel = makeViewModel()
        var noThanksTaps = 0
        viewModel.didTapNoThanks = { noThanksTaps += 1 }

        viewModel.tapNoThanks()

        XCTAssertFalse(viewModel.isVisible)
        XCTAssertEqual(noThanksTaps, 1)
        XCTAssertTrue(WMFDiscoverDataController.shared.hasDismissedAnnouncement)
        XCTAssertEqual(loggingDelegate.noThanksTaps, 1)
    }

    func testTheImpressionIsLoggedOncePerInstance() {
        let viewModel = makeViewModel()
        viewModel.viewDidAppear()
        viewModel.viewDidAppear()
        XCTAssertEqual(loggingDelegate.impressions, 1)

        let hidden = makeViewModel()
        WMFDeveloperSettingsDataController.shared.enableDiscover = false
        hidden.refresh()
        hidden.viewDidAppear()
        XCTAssertEqual(loggingDelegate.impressions, 1, "a hidden card is not an impression")
    }

    func testRefreshFollowsTheDeveloperSettings() {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.isVisible)

        WMFDeveloperSettingsDataController.shared.enableDiscover = false
        viewModel.refresh()
        XCTAssertFalse(viewModel.isVisible)

        WMFDeveloperSettingsDataController.shared.enableDiscover = true
        viewModel.refresh()
        XCTAssertTrue(viewModel.isVisible)
    }

    private final class MockLoggingDelegate: WMFDiscoverAnnouncementLoggingDelegate {
        var impressions = 0
        var getStartedTaps = 0
        var noThanksTaps = 0

        func discoverAnnouncementDidAppear() { impressions += 1 }
        func discoverAnnouncementDidTapGetStarted() { getStartedTaps += 1 }
        func discoverAnnouncementDidTapNoThanks() { noThanksTaps += 1 }
    }
}
