import XCTest
import WMFData
import WMFTestKitchen
import WMFComponents
@testable import Wikipedia

@MainActor
final class SavedInstrumentationTests: XCTestCase {

    private var sender: RecordingEventSender!
    /// The instrument keeps a weak reference to the client, so the test keeps it alive.
    private var client: TestKitchenClient!
    private var instrumentation: SavedInstrumentation!

    override func setUp() async throws {
        try await super.setUp()
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control
        sender = RecordingEventSender()
        client = TestKitchenClient(clientDataCallback: EmptyClientData(), eventSender: sender)
        instrumentation = SavedInstrumentation(client: client, dataController: .shared)
    }

    override func tearDown() async throws {
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = nil
        try WMFDataEnvironment.current.userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverSettings.rawValue)
        try await super.tearDown()
    }

    func testTheTabTapHasNoSource() throws {
        instrumentation.logSavedTabTap()

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.action, "click")
        XCTAssertEqual(event.instrumentName, "apps-reading-list")
        XCTAssertNil(event.funnelName)
        XCTAssertNil(event.actionSource)
        XCTAssertNil(event.actionSubtype)
        XCTAssertEqual(event.elementId, "saved_nav_icon")
        XCTAssertEqual(event.experimentData?.enrolled, "ios-discover-test")
        XCTAssertEqual(event.experimentData?.assigned, "control")
    }

    func testEachSegmentCountsItsOwnRows() throws {
        instrumentation.logImpression(segment: .readingLists, listCount: 3, articleCount: 40)
        try turnDiscoverOn()
        instrumentation.logImpression(segment: .allArticles, listCount: 3, articleCount: 40)

        XCTAssertEqual(Set(sender.events.map(\.action)), ["impression"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["reading_list"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["reading_list", "all_articles"])
        XCTAssertEqual(try context(of: sender.events[0]), ["list_count": "3", "discover": "false"])
        XCTAssertEqual(try context(of: sender.events[1]), ["item_count": "40", "discover": "true"])
    }

    func testTapsOnTheSavedTab() throws {
        instrumentation.logReadingListTap()
        instrumentation.logCreateListTap()
        instrumentation.logSavedArticleTap()

        XCTAssertEqual(Set(sender.events.map(\.action)), ["click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["reading_list"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["reading_list", nil, "all_articles"])
        XCTAssertEqual(sender.events.map(\.elementId), ["reading_list_select", "create_list_button", "saved_article_select"])
    }

    func testTheEventsGoOutWithoutAGroup() throws {
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = nil

        instrumentation.logSavedTabTap()

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.elementId, "saved_nav_icon")
        XCTAssertNil(event.experimentData)
    }

    // MARK: - Helpers

    private func turnDiscoverOn() throws {
        let settings = WMFDiscoverSettings(isEnabled: true, articleCount: 5, cadence: .weekly, source: .interests)
        try XCTUnwrap(WMFDataEnvironment.current.userDefaultsStore).save(key: WMFUserDefaultsKey.discoverSettings.rawValue, value: settings)
    }

    private func context(of event: Event) throws -> [String: String] {
        let data = try XCTUnwrap(event.actionContext?.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
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
