import XCTest
import WMFData
import WMFTestKitchen
import WMFComponents
@testable import Wikipedia

@MainActor
final class SavedCoordinatorTests: XCTestCase {

    private var dataStore: MWKDataStore!
    private var sender: RecordingEventSender!
    /// The instrument keeps a weak reference to the client, so the test keeps it alive.
    private var client: TestKitchenClient!
    private var coordinator: SavedCoordinator!
    /// The coordinator holds its view model weakly, so the test keeps the screen alive.
    private var screen: WMFSavedHostingController?

    override func setUp() async throws {
        try await super.setUp()
        dataStore = await withCheckedContinuation { continuation in
            MWKDataStore.createTemporaryDataStore { dataStore in
                continuation.resume(returning: dataStore)
            }
        }
        try resetDiscoverState()
        WMFDeveloperSettingsDataController.shared.enableDiscover = true
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
        sender = RecordingEventSender()
        client = TestKitchenClient(clientDataCallback: EmptyClientData(), eventSender: sender)
        coordinator = SavedCoordinator(
            theme: .light,
            dataStore: dataStore,
            savedInstrumentation: SavedInstrumentation(client: client, dataController: .shared),
            discoverInstrumentation: DiscoverInstrumentation(client: client, dataController: .shared)
        )
    }

    override func tearDown() async throws {
        screen = nil
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = nil
        try resetDiscoverState()
        dataStore.removeFolderAtBasePath()
        try await super.tearDown()
    }

    private func resetDiscoverState() throws {
        let store = try XCTUnwrap(WMFDataEnvironment.current.userDefaultsStore)
        for key in [WMFUserDefaultsKey.developerSettingsEnableDiscover, .discoverOnboardingAnnouncementDismissed, .discoverSettings, .discoverExposureSent] {
            try store.remove(key: key.rawValue)
        }
    }

    private var announcementImpressions: Int {
        sender.events.filter { $0.action == "impression" && $0.actionSource == "discover_announce" }.count
    }

    private var savedImpressions: Int {
        sender.events.filter { $0.action == "impression" && $0.actionSource == "reading_list" }.count
    }

    func testTheAnnouncementCountsAnImpressionEachTimeTheScreenDoes() {
        screen = coordinator.makeSavedViewController()

        coordinator.savedDidAppear()
        coordinator.savedDidSelectSegment(.readingLists)
        coordinator.savedDidAppear()

        XCTAssertEqual(savedImpressions, 3)
        XCTAssertEqual(announcementImpressions, 3)
    }

    func testADismissedAnnouncementHasNoImpression() throws {
        try WMFDiscoverDataController.shared.markAnnouncementDismissed()
        screen = coordinator.makeSavedViewController()

        coordinator.savedDidAppear()
        coordinator.savedDidSelectSegment(.readingLists)

        XCTAssertEqual(savedImpressions, 2)
        XCTAssertEqual(announcementImpressions, 0)
    }
}

private final class RecordingEventSender: EventSender {
    var events: [Event] = []

    func sendEvents(_ events: [Event]) {
        self.events.append(contentsOf: events)
    }
}

private struct EmptyClientData: ClientDataCallback {
    func getAgentData() -> AgentData? { nil }
    func getMediawikiData() -> MediawikiData? { nil }
    func getPerformerData() -> PerformerData? { nil }
}
