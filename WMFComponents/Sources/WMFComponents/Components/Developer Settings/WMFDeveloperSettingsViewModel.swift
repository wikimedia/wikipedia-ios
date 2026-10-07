import Foundation
import UIKit
import Combine
import WMFData

@objc public class WMFDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let sendAnalyticsToWMFLabs: String
    let bypassDonation: String
    let forceEmailAuth: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, sendAnalyticsToWMFLabs: String, bypassDonation: String, forceEmailAuth: String, done: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
        self.bypassDonation = bypassDonation
        self.forceEmailAuth = forceEmailAuth
    }
}

/// Read-only lines and actions the app provides for the Widgets section. WMFComponents cannot
/// see the widget cache (it lives in the WMF framework), so the app fills this in.
public struct WMFDeveloperSettingsWidgetDiagnostics {
    public let cacheSummaryLines: [String]
    public let lastFetchLines: [String]
    public let clearWidgetCacheAndReloadWidgets: () -> Void

    public init(cacheSummaryLines: [String], lastFetchLines: [String], clearWidgetCacheAndReloadWidgets: @escaping () -> Void) {
        self.cacheSummaryLines = cacheSummaryLines
        self.lastFetchLines = lastFetchLines
        self.clearWidgetCacheAndReloadWidgets = clearWidgetCacheAndReloadWidgets
    }
}

/// App-provided hooks for the Local Notifications section. The app builds the notification content (localized strings, app language), so it runs the refresh.
public struct WMFDeveloperSettingsLocalNotificationActions {
    public let runDailyTopReadRefreshNow: @MainActor () async -> Void

    public init(runDailyTopReadRefreshNow: @escaping @MainActor () async -> Void) {
        self.runDailyTopReadRefreshNow = runDailyTopReadRefreshNow
    }
}

/// A file ready to hand to the share sheet.
struct WMFDeveloperSettingsExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

@MainActor
@objc public class WMFDeveloperSettingsViewModel: NSObject, ObservableObject {

    let localizedStrings: WMFDeveloperSettingsLocalizedStrings
    let formViewModel: WMFFormViewModel

    /// Set by the app after init. Nil hides the Widgets section.
    @Published public var widgetDiagnostics: WMFDeveloperSettingsWidgetDiagnostics?

    /// Set by the app. Builds the 2026 Year in Review report again from the current data, and
    /// returns false when the report could not be built.
    public var regenerateYiR2026Report: (@MainActor () async throws -> Bool)?
    @Published public private(set) var isRegeneratingYiR2026Report = false
    @Published public var yiR2026ReportAlertMessage: String?

    /// Set by the app after init. Nil hides the "Run notification refresh now" button.
    @Published public var localNotificationActions: WMFDeveloperSettingsLocalNotificationActions?
    @Published var localNotificationLogSummaryLines: [String] = []

    @Published public var enableDailyTopReadNotifications: Bool = WMFDeveloperSettingsDataController.shared.enableDailyTopReadNotifications {
        didSet {
            WMFDeveloperSettingsDataController.shared.enableDailyTopReadNotifications = enableDailyTopReadNotifications
            guard !enableDailyTopReadNotifications else { return }
            Task {
                await WMFDailyTopReadNotificationDataController.shared.userDidDisable()
                await loadLocalNotificationLogSummary()
            }
        }
    }
    @Published var localNotificationLogExportFile: WMFDeveloperSettingsExportFile?

    private var subscribers: Set<AnyCancellable> = []

    @Published public var enableDeveloperMode: Bool = WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode {
        didSet {
            WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode = enableDeveloperMode
        }
    }

    @Published public var forceYiREntryPoint2026: Bool = WMFDeveloperSettingsDataController.shared.forceYiREntryPoint2026 {
        didSet {
            WMFDeveloperSettingsDataController.shared.forceYiREntryPoint2026 = forceYiREntryPoint2026
        }
    }

    @Published public var forceYiR2026Announcement: Bool = WMFDeveloperSettingsDataController.shared.forceYiR2026Announcement {
        didSet {
            WMFDeveloperSettingsDataController.shared.forceYiR2026Announcement = forceYiR2026Announcement
        }
    }

    @Published public var forceYiRUserDataState: WMFYearInReviewDataController.YiRUserDataState? = WMFDeveloperSettingsDataController.shared.forceYiRUserDataState {
        didSet {
            WMFDeveloperSettingsDataController.shared.forceYiRUserDataState = forceYiRUserDataState
        }
    }

    @Published public var forceFundraisingCampaignBanner: Bool = WMFDeveloperSettingsDataController.shared.forceFundraisingCampaignBanner {
        didSet {
            WMFDeveloperSettingsDataController.shared.forceFundraisingCampaignBanner = forceFundraisingCampaignBanner
        }
    }

    @Published public var useTestWikiDonateConfigs: Bool = WMFDeveloperSettingsDataController.shared.useTestWikiDonateConfigs {
        didSet {
            WMFDeveloperSettingsDataController.shared.useTestWikiDonateConfigs = useTestWikiDonateConfigs
        }
    }

    @Published public var useHardcodedPaymentMethods: Bool = WMFDeveloperSettingsDataController.shared.useHardcodedPaymentMethods {
        didSet {
            WMFDeveloperSettingsDataController.shared.useHardcodedPaymentMethods = useHardcodedPaymentMethods
        }
    }

    @Published public var forceDonationReminderExperimentAssignment: WMFDonationReminderDataController.ExperimentAssignment? = WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment {
        didSet {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = forceDonationReminderExperimentAssignment
        }
    }

    @Published public var bypassDonation: Bool = WMFDeveloperSettingsDataController.shared.bypassDonation {
        didSet {
            WMFDeveloperSettingsDataController.shared.bypassDonation = bypassDonation
        }
    }

    @Published public var bypassDonationReminderDailyLimit: Bool = WMFDeveloperSettingsDataController.shared.bypassDonationReminderDailyLimit {
        didSet {
            WMFDeveloperSettingsDataController.shared.bypassDonationReminderDailyLimit = bypassDonationReminderDailyLimit
        }
    }

    @Published public var overrideFundraisingCurrentDate: Bool = WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate != nil {
        didSet {
            WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate = overrideFundraisingCurrentDate ? fundraisingCurrentDate : nil
        }
    }

    @Published public var fundraisingCurrentDate: Date = WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate ?? WMFDonationReminderDataController.reminderEndDate {
        didSet {
            guard overrideFundraisingCurrentDate else { return }
            WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate = fundraisingCurrentDate
        }
    }

    @Published public var enableSemanticSearch: Bool = WMFDeveloperSettingsDataController.shared.enableSemanticSearch {
        didSet {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = enableSemanticSearch
        }
    }

    @Published public var forceSemanticSearchExperimentAssignment: WMFSemanticSearchDataController.ExperimentAssignment? = WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment {
        didSet {
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = forceSemanticSearchExperimentAssignment
        }
    }

    var fundraisingOverrideDateRange: ClosedRange<Date> {
        let lowerBound = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(-86_400)
        let upperBound = WMFDonationReminderDataController.wrapUpEndDate.addingTimeInterval(86_400)
        return lowerBound...upperBound
    }


    @objc public init(localizedStrings: WMFDeveloperSettingsLocalizedStrings) {
        self.localizedStrings = localizedStrings

        let doNotPostImageRecommendationsEditItem = WMFFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)
        let forceEmailAuth = WMFFormItemSelectViewModel(title: localizedStrings.forceEmailAuth, isSelected: WMFDeveloperSettingsDataController.shared.forceEmailAuth)
        let forceMaxArticleTabsTo5 = WMFFormItemSelectViewModel(title: "Force Max Article Tabs to 5", isSelected: WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5)
        let forceHcaptchaChallenge = WMFFormItemSelectViewModel(title: "Force hCaptcha Challenge", isSelected: WMFDeveloperSettingsDataController.shared.forceHCaptchaChallenge)
        let allowGestureZoomArticleWebview = WMFFormItemSelectViewModel(title: "Allow pinch to zoom when reading articles", isSelected: WMFDeveloperSettingsDataController.shared.allowGestureZoomArticleWebview)
        let enableHomePhase2 = WMFFormItemSelectViewModel(title: "Enable Home Phase 2", isSelected: WMFDeveloperSettingsDataController.shared.enableHomePhase2)

        formViewModel = WMFFormViewModel(sections: [
            WMFFormSectionSelectViewModel(items: [
                enableHomePhase2,
                doNotPostImageRecommendationsEditItem,
                sendAnalyticsToWMFLabsItem,
                forceEmailAuth,
                forceMaxArticleTabsTo5,
                forceHcaptchaChallenge,
                allowGestureZoomArticleWebview
            ], selectType: .multi)
        ])

        doNotPostImageRecommendationsEditItem.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit = isSelected }
            .store(in: &subscribers)

        sendAnalyticsToWMFLabsItem.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs = isSelected }
            .store(in: &subscribers)

        forceEmailAuth.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceEmailAuth = isSelected }
            .store(in: &subscribers)

        forceMaxArticleTabsTo5.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5 = isSelected }
            .store(in: &subscribers)

        forceHcaptchaChallenge.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceHCaptchaChallenge = isSelected }
            .store(in: &subscribers)

        allowGestureZoomArticleWebview.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.allowGestureZoomArticleWebview = isSelected }
            .store(in: &subscribers)

        enableHomePhase2.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableHomePhase2 = isSelected }
            .store(in: &subscribers)
    }

    public var appInstallID: String? {
        try? WMFDataEnvironment.current.crossProcessUserDefaultsStore?.load(key: WMFUserDefaultsKey.appInstallID.rawValue)
    }

    @MainActor
    public func copyAppInstallID() {
        guard let appInstallID else { return }
        UIPasteboard.general.string = appInstallID
        WMFToastPresenter.shared.show(WMFToastConfig(title: .init("App install ID copied")))
    }

    public func clearFundraisingCampaignPersistence() {
        WMFDeveloperSettingsDataController.shared.clearFundraisingCampaignPersistence()
        Task { @MainActor in
            WMFToastPresenter.shared.show(WMFToastConfig(title: .init("Fundraising state cleared. The campaign banner can show again.")))
        }
    }

    public func clearSemanticSearchExperimentAssignment() {
        let title: String
        do {
            try WMFSemanticSearchDataController.shared.clearExperimentAssignment()
            title = "Semantic search bucket cleared. The next eligible search re-rolls the assignment."
        } catch {
            title = "Could not clear the semantic search bucket: \(error)"
        }
        Task { @MainActor in
            WMFToastPresenter.shared.show(WMFToastConfig(title: .init(title)))
        }
    }

    @discardableResult
    public func tappedRegenerateYiR2026Report() -> Task<Void, Never>? {
        guard let regenerateYiR2026Report, !isRegeneratingYiR2026Report else { return nil }
        isRegeneratingYiR2026Report = true
        return Task { [weak self] in
            let message: String
            do {
                message = try await regenerateYiR2026Report()
                    ? "The Year in Review 2026 report was built again. Open Year in Review to see it."
                    : "The report was not built. Check the Year in Review setting in Settings, the 2026 config and the country of the device."
            } catch {
                message = "The report was not built: \(error.localizedDescription)"
            }
            self?.isRegeneratingYiR2026Report = false
            self?.yiR2026ReportAlertMessage = message
        }
    }

    public func clearWidgetCacheAndReloadWidgets() {
        widgetDiagnostics?.clearWidgetCacheAndReloadWidgets()
        WMFToastPresenter.shared.show(WMFToastConfig(title: .init("Widget cache cleared and timelines reloaded. Reopen this screen to see the new fetch.")))
    }

    public func resetSemanticSearchEntryPoint() {
        let title: String
        do {
            try WMFSemanticSearchDataController.shared.resetEntryPointState()
            title = "Semantic search entry point reset. It shows again with Try it now on the next search."
        } catch {
            title = "Could not reset the semantic search entry point: \(error)"
        }
        Task { @MainActor in
            WMFToastPresenter.shared.show(WMFToastConfig(title: .init(title)))
        }
    }

    // MARK: - Local Notifications

    func loadLocalNotificationLogSummary() async {
        let entries = await WMFLocalNotificationDataController.shared.loadLog()
        guard let last = entries.last else {
            localNotificationLogSummaryLines = ["No local notification log entries yet."]
            return
        }

        let scheduledCount = entries.filter { $0.event == .scheduled }.count
        let backgroundRuns = entries.filter { $0.event == .runStarted && $0.appState == "background" }.count
        localNotificationLogSummaryLines = [
            "\(entries.count) entries, \(backgroundRuns) background runs, \(scheduledCount) scheduled",
            "Latest: \(last.event.rawValue) at \(last.timestamp.formatted(date: .abbreviated, time: .standard))"
        ]
    }

    func exportLocalNotificationLog() {
        Task {
            do {
                let data = try await WMFLocalNotificationDataController.shared.exportLogData()
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("local-notifications-log.json")
                try data.write(to: url, options: .atomic)
                localNotificationLogExportFile = WMFDeveloperSettingsExportFile(url: url)
            } catch {
                WMFToastPresenter.shared.show(WMFToastConfig(title: .init("Could not export the log: \(error)")))
            }
        }
    }

    func resetLocalNotificationHandledDays() {
        Task {
            await WMFLocalNotificationDataController.shared.resetHandledDays()
            WMFToastPresenter.shared.show(WMFToastConfig(title: .init("Handled days reset. The next refresh can schedule again today.")))
        }
    }

    func runDailyTopReadRefreshNow() {
        guard let localNotificationActions else { return }
        guard enableDailyTopReadNotifications else {
            WMFToastPresenter.shared.show(WMFToastConfig(title: .init("Turn on Daily Top Read Notifications first.")))
            return
        }
        Task {
            await localNotificationActions.runDailyTopReadRefreshNow()
            await loadLocalNotificationLogSummary()
            let latest = await WMFLocalNotificationDataController.shared.loadLog().last?.event.rawValue ?? "none"
            WMFToastPresenter.shared.show(WMFToastConfig(title: .init("Refresh finished. Latest log event: \(latest)")))
        }
    }

    func clearLocalNotificationLog() {
        Task {
            await WMFLocalNotificationDataController.shared.clearLog()
            await loadLocalNotificationLogSummary()
            WMFToastPresenter.shared.show(WMFToastConfig(title: .init("Local notification log cleared.")))
        }
    }
}
