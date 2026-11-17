import XCTest
import WMFData
import WMFTestKitchen
import WMFComponents
@testable import Wikipedia

@MainActor
final class DiscoverInstrumentationTests: XCTestCase {

    private var sender: RecordingEventSender!
    /// The instrument keeps a weak reference to the client, so the test keeps it alive.
    private var client: TestKitchenClient!
    private var instrumentation: DiscoverInstrumentation!
    private let dataController = WMFDiscoverDataController.shared

    override func setUp() async throws {
        try await super.setUp()
        try resetExposure()
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
        sender = RecordingEventSender()
        client = TestKitchenClient(clientDataCallback: EmptyClientData(), eventSender: sender)
        instrumentation = DiscoverInstrumentation(client: client, dataController: dataController)
    }

    override func tearDown() async throws {
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = nil
        try resetExposure()
        try WMFDataEnvironment.current.userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverSettings.rawValue)
        try await super.tearDown()
    }

    // MARK: - Exposure

    func testExperimentExposureHasNoInstrumentAndCarriesTheGroup() throws {
        instrumentation.logExperimentExposure()

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(sender.events.count, 1)
        XCTAssertEqual(event.action, "experiment_exposure")
        XCTAssertNil(event.instrumentName)
        XCTAssertNil(event.funnelName)
        XCTAssertEqual(event.experimentData?.enrolled, "ios-discover-test")
        XCTAssertEqual(event.experimentData?.assigned, "treatment")
        XCTAssertTrue(dataController.hasSentExposure)
    }

    func testTheControlGroupSendsTheExposureToo() throws {
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control

        instrumentation.logExperimentExposure()

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.action, "experiment_exposure")
        XCTAssertEqual(event.experimentData?.assigned, "control")
    }

    func testTheExposureGoesOutOnce() throws {
        instrumentation.logExperimentExposure()
        instrumentation.logExperimentExposure()

        XCTAssertEqual(sender.events.count, 1)
    }

    func testTheExposureNeedsAGroup() throws {
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = nil

        instrumentation.logExperimentExposure()

        XCTAssertTrue(sender.events.isEmpty)
        XCTAssertFalse(dataController.hasSentExposure)
    }

    // MARK: - Shared fields

    func testEveryEventUsesTheReadingListInstrumentAndTheExperiment() throws {
        instrumentation.logAnnouncementImpression()
        instrumentation.logSetupContinueTap()
        instrumentation.logSettingsRowTap()

        XCTAssertEqual(sender.events.count, 3)
        for event in sender.events {
            XCTAssertEqual(event.instrumentName, "apps-reading-list")
            XCTAssertNil(event.funnelName)
            XCTAssertEqual(event.experimentData?.enrolled, "ios-discover-test")
            XCTAssertEqual(event.experimentData?.assigned, "treatment")
        }
    }

    // MARK: - Announcement card

    func testAnnouncementCard() throws {
        instrumentation.logAnnouncementImpression()
        instrumentation.logAnnouncementGetStartedTap()
        instrumentation.logAnnouncementNoThanksTap()

        XCTAssertEqual(sender.events.map(\.action), ["impression", "click", "click"])
        XCTAssertEqual(sender.events.map(\.actionSource), ["discover_announce", "discover_announce", "discover_announce"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), [nil, nil, nil])
        XCTAssertEqual(sender.events.map(\.elementId), [nil, "get_started_button", "no_thanks_button"])
    }

    // MARK: - Entry card

    func testTheEntryCardNamesTheSegmentItSitsOn() throws {
        instrumentation.logEntryCardTap(segment: .readingLists)
        instrumentation.logEntryCardTap(segment: .allArticles)

        XCTAssertEqual(sender.events.map(\.action), ["click", "click"])
        XCTAssertEqual(sender.events.map(\.actionSource), ["reading_list", "reading_list"])
        XCTAssertEqual(sender.events.map(\.actionSubtype), ["reading_list", "all_articles"])
        XCTAssertEqual(sender.events.map(\.elementId), ["reading_list_discover", "reading_list_discover"])
    }

    // MARK: - Setup

    func testSetupScreen() throws {
        instrumentation.logSetupImpression()
        instrumentation.logSetupBackTap()
        instrumentation.logSetupSourceTap(.interests)
        instrumentation.logSetupSourceTap(.saved)
        instrumentation.logSetupSourceTap(.history)
        instrumentation.logSetupContinueTap()

        XCTAssertEqual(sender.events.map(\.action), ["impression", "click", "click", "click", "click", "click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["discover_customize"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["onboarding_launch"])
        XCTAssertEqual(sender.events.map(\.elementId), [nil, "back_button", "interests_select_button", "reading_list_select_button", "history_select_button", "continue_button"])
    }

    func testSourceTapsFromSettingsKeepTheOnboardingNames() throws {
        instrumentation.logSettingsSourceSelectTap(.interests)
        instrumentation.logSettingsSourceSelectTap(.saved)
        instrumentation.logSettingsSourceSelectTap(.history)

        XCTAssertEqual(Set(sender.events.map(\.action)), ["click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["settings"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["onboarding_launch"])
        XCTAssertEqual(sender.events.map(\.elementId), ["interests_select_button", "reading_list_select_button", "history_select_button"])
    }

    func testSourceChangeFromSettings() throws {
        instrumentation.logSetupAdjustTap()
        instrumentation.logSetupCancelAdjustTap()
        instrumentation.logSourceUndoTap()

        XCTAssertEqual(Set(sender.events.map(\.action)), ["click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["settings"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["discover_customize"])
        XCTAssertEqual(sender.events.map(\.elementId), ["adjust_button", "cancel_button", "undo_button"])
    }

    // MARK: - Interests

    func testInterestsFromTheOnboarding() throws {
        instrumentation.logInterestsImpression(entry: .onboarding)
        instrumentation.logInterestsBackTap(entry: .onboarding)
        instrumentation.logInterestsDeselectAllTap(entry: .onboarding)
        instrumentation.logInterestsTopicTap(entry: .onboarding)
        instrumentation.logInterestsArticleTap(entry: .onboarding)
        instrumentation.logInterestsDoneTap(entry: .onboarding, topicCount: 3, articleCount: 2)

        XCTAssertEqual(sender.events.map(\.action), ["impression", "click", "click", "click", "click", "click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["discover_customize"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["onboarding"])
        XCTAssertEqual(sender.events.map(\.elementId), [nil, "back_button", "deselect_all_button", "topic_select", "article_select", "done_button"])
        XCTAssertEqual(try context(of: sender.events[5]), ["topics_count": "3", "articles_count": "2"])
    }

    func testInterestsFromSettings() throws {
        instrumentation.logInterestsImpression(entry: .settings)
        instrumentation.logInterestsDoneTap(entry: .settings, topicCount: 0, articleCount: 7)

        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["settings"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["onboarding_launch"])
        XCTAssertEqual(sender.events.map(\.elementId), [nil, "done_button"])
        XCTAssertEqual(try context(of: sender.events[1]), ["topics_count": "0", "articles_count": "7"])
    }

    // MARK: - Discover list

    func testTheListImpressionCountsItsArticlesAndSaysWhetherDiscoverIsOn() throws {
        instrumentation.logListImpression(itemCount: 12)
        try turnDiscoverOn()
        instrumentation.logListImpression(itemCount: 5)

        XCTAssertEqual(Set(sender.events.map(\.action)), ["impression"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["reading_list"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["reading_list_discover"])
        XCTAssertEqual(try context(of: sender.events[0]), ["item_count": "12", "discover": "false"])
        XCTAssertEqual(try context(of: sender.events[1]), ["item_count": "5", "discover": "true"])
    }

    func testListButtons() throws {
        instrumentation.logListCustomizeTap()
        instrumentation.logListSaveTap()
        instrumentation.logListShareTap()
        instrumentation.logListAboutTap()

        XCTAssertEqual(Set(sender.events.map(\.action)), ["click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["reading_list"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["reading_list_discover"])
        XCTAssertEqual(sender.events.map(\.elementId), ["customize_discover", "reading_list_discover_save", "reading_list_share", "reading_list_about"])
    }

    // MARK: - Save list sheet

    func testSaveListSheet() throws {
        instrumentation.logSaveSheetImpression(itemCount: 4)
        instrumentation.logSaveSheetCancelTap()
        instrumentation.logSaveSheetSaveTap()

        XCTAssertEqual(sender.events.map(\.action), ["impression", "click", "click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["reading_list"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["reading_list_discover_customize"])
        XCTAssertEqual(sender.events.map(\.elementId), [nil, "cancel_button", "save_button"])
        XCTAssertEqual(try context(of: sender.events[0]), ["item_count": "4", "discover": "false"])
    }

    // MARK: - Settings

    func testTheSettingsRowHasNoSubtype() throws {
        instrumentation.logSettingsRowTap()

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.action, "click")
        XCTAssertEqual(event.actionSource, "settings")
        XCTAssertNil(event.actionSubtype)
        XCTAssertEqual(event.elementId, "reading_list_discover")
    }

    func testTheSwitchSendsEnableAndDisable() throws {
        instrumentation.logSettingsToggle(isOn: true)
        instrumentation.logSettingsToggle(isOn: false)
        instrumentation.logSettingsDisableConfirmTap()
        instrumentation.logSettingsDisableCancelTap()

        XCTAssertEqual(sender.events.map(\.action), ["enable", "disable", "click", "click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["settings"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["reading_list_discover"])
        XCTAssertEqual(sender.events.map(\.elementId), [nil, nil, "disable_confirm", "disable_cancel"])
    }

    func testSettingsPickers() throws {
        instrumentation.logSettingsArticleCountTap(articleCount: 10)
        instrumentation.logSettingsCadenceTap(cadence: .monthly)
        instrumentation.logSettingsInterestsTap()

        XCTAssertEqual(Set(sender.events.map(\.action)), ["click"])
        XCTAssertEqual(Set(sender.events.map(\.actionSource)), ["settings"])
        XCTAssertEqual(Set(sender.events.map(\.actionSubtype)), ["reading_list_discover"])
        XCTAssertEqual(sender.events.map(\.elementId), ["article_update_select", "update_frequency_select", "interest_select"])
        XCTAssertEqual(try context(of: sender.events[0]), ["article_count": "10"])
        XCTAssertEqual(try context(of: sender.events[1]), ["frequency": "monthly"])
        XCTAssertNil(sender.events[2].actionContext)
    }

    // MARK: - Helpers

    /// The test host has no experiment store, so the forced assignment is the only group. The
    /// exposure flag lives in user defaults and must start clean.
    private func resetExposure() throws {
        try WMFDataEnvironment.current.userDefaultsStore?.remove(key: WMFUserDefaultsKey.discoverExposureSent.rawValue)
    }

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
