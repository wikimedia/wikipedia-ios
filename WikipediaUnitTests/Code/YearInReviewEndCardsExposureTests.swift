import XCTest
import WMFData
import WMFTestKitchen
@testable import Wikipedia

/// The coordinator sends the exposure of the end screen cards experiment (T441006) on the end
/// screen impression, also when the funnel is stopped, as on Android.
@MainActor
final class YearInReviewEndCardsExposureTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private var dataStore: MWKDataStore!
    private var exposures: [ExperimentData] = []

    override func setUp() async throws {
        try await super.setUp()
        dataStore = await withCheckedContinuation { continuation in
            MWKDataStore.createTemporaryDataStore { dataStore in
                continuation.resume(returning: dataStore)
            }
        }
        exposures = []
    }

    override func tearDown() async throws {
        dataStore.removeFolderAtBasePath()
        try await super.tearDown()
    }

    /// English has the game. The bucket store is empty, and the exposure flag in the host's user
    /// defaults is cleared before and after, so the reader has no bucket and no exposure yet.
    private func withGroupBReader(_ operation: (YearInReviewCoordinator) async throws -> Void) async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
            WMFDataEnvironment.current.sharedCacheStore = InMemoryKeyValueStore()
        }) {
            let dataController = WMFYearInReviewEndCardsDataController.shared
            try await dataController.clearAssignment()
            try await dataController.setDeveloperSettingsForcedAssignment(.groupB)
            let coordinator = YearInReviewCoordinator(
                navigationController: UINavigationController(),
                theme: .light,
                dataStore: dataStore,
                dataController: try WMFYearInReviewDataController(coreDataStore: try await fixture.makeTemporaryCoreDataStore()),
                submitExperimentExposure: { [weak self] in self?.exposures.append($0) }
            )
            YearInReviewInstrument.shared.stopFunnel()
            do {
                try await operation(coordinator)
            } catch {
                try await dataController.setDeveloperSettingsForcedAssignment(nil)
                throw error
            }
            // Off also clears the bucket and the exposure flag.
            try await dataController.setDeveloperSettingsForcedAssignment(nil)
        }
    }

    /// Waits for the exposure task, with a time limit so that a bug does not hang the suite.
    private func waitForExposures(count: Int) async {
        let deadline = Date().addingTimeInterval(2)
        while exposures.count < count, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    func testTheEndScreenImpressionSendsTheExposureWhileTheFunnelIsStopped() async throws {
        try await withGroupBReader { coordinator in
            coordinator.logYearInReviewSlideDidAppear(slideLoggingID: YearInReviewInstrument.endPage)
            await waitForExposures(count: 1)

            XCTAssertEqual(exposures.count, 1)
            XCTAssertEqual(exposures.first?.enrolled, WMFYearInReviewEndCardsDataController.experimentName)
            XCTAssertEqual(exposures.first?.assigned, "treatment")
        }
    }

    func testTheExposureGoesOutOnce() async throws {
        try await withGroupBReader { coordinator in
            coordinator.logYearInReviewSlideDidAppear(slideLoggingID: YearInReviewInstrument.endPage)
            await waitForExposures(count: 1)
            coordinator.logYearInReviewSlideDidAppear(slideLoggingID: YearInReviewInstrument.endPage)
            await waitForExposures(count: 2)

            XCTAssertEqual(exposures.count, 1)
        }
    }

    /// The slides open only after this returns, so the first slide impression of the first open
    /// already carries the group. Nothing waits here: the value must be there at once.
    func testTheGroupIsReadyForTheFirstSlideImpression() async throws {
        try await withGroupBReader { _ in
            let cards = await YearInReviewCoordinator.assignEndCardsExperiment()

            XCTAssertEqual(YearInReviewInstrument.shared.currentExperimentData?.assigned, "treatment")
            XCTAssertTrue(cards.showsGamesCard)
            XCTAssertTrue(cards.showsInterestsCard)
        }
    }

    func testASlideImpressionSendsNoExposure() async throws {
        try await withGroupBReader { coordinator in
            coordinator.logYearInReviewSlideDidAppear(slideLoggingID: "read_count")
            await waitForExposures(count: 1)

            XCTAssertTrue(exposures.isEmpty)
        }
    }
}
