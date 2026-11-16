import Foundation
import WMFComponents
import WMFData
import WMFTestKitchen
import CocoaLumberjackSwift

/// Sends the events of the Discover feature to the `apps-reading-list` instrument: the exposure,
/// the announcement card, the setup screens, the Discover list and its settings. Every event
/// carries the experiment fields, so the dashboards split them by group.
@MainActor
final class DiscoverInstrumentation {

    /// Where the interests screen opened from. The two routes send the same events under
    /// different names.
    enum InterestsEntry {
        /// From the setup after Get started.
        case onboarding
        /// From the Discover settings, also when the switch opens the screen.
        case settings

        fileprivate var actionSource: String {
            switch self {
            case .onboarding: return "discover_customize"
            case .settings: return DiscoverInstrumentation.settingsActionSource
            }
        }

        fileprivate var actionSubtype: String {
            switch self {
            case .onboarding: return "onboarding"
            case .settings: return "onboarding_launch"
            }
        }
    }

    static let shared = DiscoverInstrumentation()

    nonisolated static let instrumentName = SavedInstrumentation.instrumentName

    nonisolated private static let readingListActionSource = "reading_list"
    nonisolated private static let announcementActionSource = "discover_announce"
    nonisolated private static let setupActionSource = "discover_customize"
    nonisolated private static let settingsActionSource = "settings"

    nonisolated private static let discoverListActionSubtype = "reading_list_discover"
    nonisolated private static let saveSheetActionSubtype = "reading_list_discover_customize"
    nonisolated private static let setupActionSubtype = "onboarding_launch"
    nonisolated private static let settingsSetupActionSubtype = "discover_customize"

    private let client: TestKitchenClient
    private let instrument: InstrumentImpl
    private let dataController: WMFDiscoverDataController

    init(client: TestKitchenClient = TestKitchenAdapter.shared.client, dataController: WMFDiscoverDataController = .shared) {
        self.client = client
        self.instrument = client.getInstrument(name: Self.instrumentName)
        self.dataController = dataController
    }

    // MARK: - Experiment

    /// The reader got a group. Sent once per install, in both groups, when the bucket is assigned,
    /// so the dashboards compare how many readers of each group open the Saved tab.
    func logExperimentExposure() {
        guard dataController.shouldSendExposure, let experimentData = dataController.experimentData else { return }
        client.submitExperimentExposure(experimentData: experimentData)
        do {
            try dataController.markExposureSent()
        } catch {
            DDLogError("Recording the Discover exposure failed: \(error)")
        }
    }

    // MARK: - Announcement card

    func logAnnouncementImpression() {
        submit(action: "impression", actionSource: Self.announcementActionSource)
    }

    func logAnnouncementGetStartedTap() {
        submit(actionSource: Self.announcementActionSource, elementId: "get_started_button")
    }

    func logAnnouncementNoThanksTap() {
        submit(actionSource: Self.announcementActionSource, elementId: "no_thanks_button")
    }

    // MARK: - Entry card

    /// The reader opened the Discover list from its card on the Saved tab.
    func logEntryCardTap(segment: WMFSavedViewModel.Segment) {
        submit(actionSource: Self.readingListActionSource, actionSubtype: segment.readingListActionSubtype, elementId: Self.discoverListActionSubtype)
    }

    // MARK: - Setup

    func logSetupImpression() {
        submit(action: "impression", actionSource: Self.setupActionSource, actionSubtype: Self.setupActionSubtype)
    }

    func logSetupBackTap() {
        submit(actionSource: Self.setupActionSource, actionSubtype: Self.setupActionSubtype, elementId: "back_button")
    }

    func logSetupSourceTap(_ source: WMFDiscoverSource) {
        submit(actionSource: Self.setupActionSource, actionSubtype: Self.setupActionSubtype, elementId: source.setupElementId)
    }

    func logSetupContinueTap() {
        submit(actionSource: Self.setupActionSource, actionSubtype: Self.setupActionSubtype, elementId: "continue_button")
    }

    /// A source tapped on the source screen opened from Settings. The alert follows when the source is new.
    func logSettingsSourceSelectTap(_ source: WMFDiscoverSource) {
        submit(actionSource: Self.settingsActionSource, actionSubtype: Self.setupActionSubtype, elementId: source.setupElementId)
    }

    /// The reader confirmed a new source in the alert of the source screen opened from Settings.
    func logSetupAdjustTap() {
        submit(actionSource: Self.settingsActionSource, actionSubtype: Self.settingsSetupActionSubtype, elementId: "adjust_button")
    }

    func logSetupCancelAdjustTap() {
        submit(actionSource: Self.settingsActionSource, actionSubtype: Self.settingsSetupActionSubtype, elementId: "cancel_button")
    }

    /// The reader tapped Undo on the toast that follows a source change.
    func logSourceUndoTap() {
        submit(actionSource: Self.settingsActionSource, actionSubtype: Self.settingsSetupActionSubtype, elementId: "undo_button")
    }

    // MARK: - Interests

    func logInterestsImpression(entry: InterestsEntry) {
        submit(action: "impression", actionSource: entry.actionSource, actionSubtype: entry.actionSubtype)
    }

    func logInterestsBackTap(entry: InterestsEntry) {
        submit(actionSource: entry.actionSource, actionSubtype: entry.actionSubtype, elementId: "back_button")
    }

    func logInterestsDeselectAllTap(entry: InterestsEntry) {
        submit(actionSource: entry.actionSource, actionSubtype: entry.actionSubtype, elementId: "deselect_all_button")
    }

    func logInterestsTopicTap(entry: InterestsEntry) {
        submit(actionSource: entry.actionSource, actionSubtype: entry.actionSubtype, elementId: "topic_select")
    }

    func logInterestsArticleTap(entry: InterestsEntry) {
        submit(actionSource: entry.actionSource, actionSubtype: entry.actionSubtype, elementId: "article_select")
    }

    /// The counts are the totals the reader leaves with, not only the picks of this visit.
    func logInterestsDoneTap(entry: InterestsEntry, topicCount: Int, articleCount: Int) {
        submit(actionSource: entry.actionSource, actionSubtype: entry.actionSubtype, elementId: "done_button", actionContext: ["topics_count": topicCount, "articles_count": articleCount])
    }

    // MARK: - Discover list

    func logListImpression(itemCount: Int) {
        submit(action: "impression", actionSource: Self.readingListActionSource, actionSubtype: Self.discoverListActionSubtype, actionContext: listContext(itemCount: itemCount))
    }

    /// Customize, on the first-open toast and in the More menu.
    func logListCustomizeTap() {
        submit(actionSource: Self.readingListActionSource, actionSubtype: Self.discoverListActionSubtype, elementId: "customize_discover")
    }

    func logListSaveTap() {
        submit(actionSource: Self.readingListActionSource, actionSubtype: Self.discoverListActionSubtype, elementId: "reading_list_discover_save")
    }

    func logListShareTap() {
        submit(actionSource: Self.readingListActionSource, actionSubtype: Self.discoverListActionSubtype, elementId: "reading_list_share")
    }

    func logListAboutTap() {
        submit(actionSource: Self.readingListActionSource, actionSubtype: Self.discoverListActionSubtype, elementId: "reading_list_about")
    }

    // MARK: - Save list sheet

    func logSaveSheetImpression(itemCount: Int) {
        submit(action: "impression", actionSource: Self.readingListActionSource, actionSubtype: Self.saveSheetActionSubtype, actionContext: listContext(itemCount: itemCount))
    }

    /// Cancel, the X and a swipe down all send this: none of them saves.
    func logSaveSheetCancelTap() {
        submit(actionSource: Self.readingListActionSource, actionSubtype: Self.saveSheetActionSubtype, elementId: "cancel_button")
    }

    func logSaveSheetSaveTap() {
        submit(actionSource: Self.readingListActionSource, actionSubtype: Self.saveSheetActionSubtype, elementId: "save_button")
    }

    // MARK: - Settings

    /// The reader opened the Discover settings from the Settings screen.
    func logSettingsRowTap() {
        submit(actionSource: Self.settingsActionSource, elementId: Self.discoverListActionSubtype)
    }

    func logSettingsToggle(isOn: Bool) {
        submit(action: isOn ? "enable" : "disable", actionSource: Self.settingsActionSource, actionSubtype: Self.discoverListActionSubtype)
    }

    func logSettingsDisableConfirmTap() {
        submitSettingsTap(elementId: "disable_confirm")
    }

    func logSettingsDisableCancelTap() {
        submitSettingsTap(elementId: "disable_cancel")
    }

    func logSettingsArticleCountTap(articleCount: Int) {
        submitSettingsTap(elementId: "article_update_select", actionContext: ["article_count": articleCount])
    }

    func logSettingsCadenceTap(cadence: WMFDiscoverCadence) {
        submitSettingsTap(elementId: "update_frequency_select", actionContext: ["frequency": cadence.rawValue])
    }

    func logSettingsInterestsTap() {
        submitSettingsTap(elementId: "interest_select")
    }

    // MARK: - Private

    private func listContext(itemCount: Int) -> [String: Any] {
        ["item_count": itemCount, "discover": dataController.isListTurnedOn]
    }

    private func submitSettingsTap(elementId: String, actionContext: [String: Any] = [:]) {
        submit(actionSource: Self.settingsActionSource, actionSubtype: Self.discoverListActionSubtype, elementId: elementId, actionContext: actionContext)
    }

    private func submit(action: String = "click", actionSource: String, actionSubtype: String? = nil, elementId: String? = nil, actionContext: [String: Any] = [:]) {
        instrument.submitInteraction(
            action: action,
            actionSource: actionSource,
            actionSubtype: actionSubtype,
            elementId: elementId,
            actionContext: actionContext.isEmpty ? nil : actionContext,
            experimentData: dataController.experimentData
        )
    }
}

private extension WMFDiscoverSource {

    /// The option on the setup screen, in the names of the spec.
    var setupElementId: String {
        switch self {
        case .interests: return "interests_select_button"
        case .saved: return "reading_list_select_button"
        case .history: return "history_select_button"
        }
    }
}
