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

@MainActor
@objc public class WMFDeveloperSettingsViewModel: NSObject, ObservableObject {

    let localizedStrings: WMFDeveloperSettingsLocalizedStrings
    let formViewModel: WMFFormViewModel

    /// Set by the app after init. Nil hides the Widgets section.
    @Published public var widgetDiagnostics: WMFDeveloperSettingsWidgetDiagnostics?

    private var subscribers: Set<AnyCancellable> = []

    @Published public var enableDeveloperMode: Bool = WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode {
        didSet {
            WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode = enableDeveloperMode
        }
    }

    @Published public var showGamesV2: Bool = WMFDeveloperSettingsDataController.shared.showGamesV2 {
        didSet {
            WMFDeveloperSettingsDataController.shared.showGamesV2 = showGamesV2
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

        // Year in Review owns the forced data state, so the two data-state items read and write it
        // through WMFYearInReviewDataController rather than developer settings. It has no shared
        // instance and its init throws, so one is held for the lifetime of the sinks below.
        let yirDataController = try? WMFYearInReviewDataController()

        let enableHomePhase2 = WMFFormItemSelectViewModel(title: "Enable Home Phase 2", isSelected: WMFDeveloperSettingsDataController.shared.enableHomePhase2)
        let doNotPostImageRecommendationsEditItem = WMFFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)
        let forceEmailAuth = WMFFormItemSelectViewModel(title: localizedStrings.forceEmailAuth, isSelected: WMFDeveloperSettingsDataController.shared.forceEmailAuth)
        let forceMaxArticleTabsTo5 = WMFFormItemSelectViewModel(title: "Force Max Article Tabs to 5", isSelected: WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5)
        let forceHcaptchaChallenge = WMFFormItemSelectViewModel(title: "Force hCaptcha Challenge", isSelected: WMFDeveloperSettingsDataController.shared.forceHCaptchaChallenge)
        let allowGestureZoomArticleWebview = WMFFormItemSelectViewModel(title: "Allow pinch to zoom when reading articles", isSelected: WMFDeveloperSettingsDataController.shared.allowGestureZoomArticleWebview)

        let showYiR2025 = WMFFormItemSelectViewModel(title: "Show Year in Review 2025", isSelected: WMFDeveloperSettingsDataController.shared.showYiR2025)
        let forceYiR2026 = WMFFormItemSelectViewModel(title: "Force Year in Review 2026", isSelected: WMFDeveloperSettingsDataController.shared.forceYiR2026)
        let forceYiR2026Announcement = WMFFormItemSelectViewModel(title: "Force Year in Review 2026 Announcement", isSelected: WMFDeveloperSettingsDataController.shared.forceYiR2026Announcement)
        let forceYiRDataRichUser = WMFFormItemSelectViewModel(title: "Force Year in Review data-rich user", isSelected: yirDataController?.forceYiRUserDataState == .dataRich)
        let forceYiRLowDataUser = WMFFormItemSelectViewModel(title: "Force Year in Review low-data user", isSelected: yirDataController?.forceYiRUserDataState == .lowData)

        formViewModel = WMFFormViewModel(sections: [
            WMFFormSectionSelectViewModel(items: [
                enableHomePhase2,
                doNotPostImageRecommendationsEditItem,
                sendAnalyticsToWMFLabsItem,
                forceEmailAuth,
                forceMaxArticleTabsTo5,
                forceHcaptchaChallenge,
                allowGestureZoomArticleWebview,
                showYiR2025,
                forceYiR2026,
                forceYiR2026Announcement,
                forceYiRDataRichUser,
                forceYiRLowDataUser
            ], selectType: .multi)
        ])

        enableHomePhase2.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableHomePhase2 = isSelected }
            .store(in: &subscribers)

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

        showYiR2025.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.showYiR2025 = isSelected }
            .store(in: &subscribers)

        // While on, 2026 Year in Review overrides every gate: the remote config and its active
        // window, the Year in Review settings toggle and suppressed countries.
        forceYiR2026.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceYiR2026 = isSelected }
            .store(in: &subscribers)

        // While on, the announcement ignores every gate: the remote config and its active window,
        // the Year in Review settings toggle, suppressed countries and the "already seen" state. It
        // therefore presents on every eligible app open until it is turned back off.
        forceYiR2026Announcement.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceYiR2026Announcement = isSelected }
            .store(in: &subscribers)

        // The two Year in Review data-state items are mutually exclusive. Selecting one clears the
        // other, and the guard on the clear path keeps that programmatic deselection from wiping the
        // state that was just written.
        forceYiRDataRichUser.$isSelected
            .sink { isSelected in
                if isSelected {
                    yirDataController?.forceYiRUserDataState = .dataRich
                    forceYiRLowDataUser.isSelected = false
                } else if yirDataController?.forceYiRUserDataState == .dataRich {
                    yirDataController?.forceYiRUserDataState = nil
                }
            }
            .store(in: &subscribers)

        forceYiRLowDataUser.$isSelected
            .sink { isSelected in
                if isSelected {
                    yirDataController?.forceYiRUserDataState = .lowData
                    forceYiRDataRichUser.isSelected = false
                } else if yirDataController?.forceYiRUserDataState == .lowData {
                    yirDataController?.forceYiRUserDataState = nil
                }
            }
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

    public func clearGamesPersistence() {
        Task {
            try? await WMFDeveloperSettingsDataController.shared.clearGamesPersistence()
        }
    }
}
