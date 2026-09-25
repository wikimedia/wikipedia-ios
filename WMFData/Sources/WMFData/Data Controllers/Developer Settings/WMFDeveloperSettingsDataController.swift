import Foundation

public protocol WMFDeveloperSettingsDataControlling: AnyObject {
    func loadFeatureConfig() -> WMFFeatureConfigResponse?
    var forceMaxArticleTabsTo5: Bool { get }
    var forceYiREntryPoint2026: Bool { get }
    var forceYiRUserDataState: WMFYearInReviewDataController.YiRUserDataState? { get }
    var forceYiR2026Announcement: Bool { get }
}

// @unchecked Sendable: must stay an NSObject subclass for Obj-C callers, so it
// cannot be an actor. All mutable state lives in WMFLockIsolated boxes below;
// everything else is immutable or delegates to the (Sendable) environment stores.
@objc public final class WMFDeveloperSettingsDataController: NSObject, WMFDeveloperSettingsDataControlling, @unchecked Sendable {

    @objc public static let shared = WMFDeveloperSettingsDataController()

    private let service: WMFService?
    private let _sharedCacheStore: WMFLockIsolated<WMFKeyValueStore?>
    private var sharedCacheStore: WMFKeyValueStore? {
        get { _sharedCacheStore.value }
        set { _sharedCacheStore.value = newValue }
    }
    private let _featureConfig = WMFLockIsolated<WMFFeatureConfigResponse?>(nil)
    private var featureConfig: WMFFeatureConfigResponse? {
        get { _featureConfig.value }
        set { _featureConfig.value = newValue }
    }
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.developerSettings.rawValue

    private let cacheFeatureConfigFileName = "AppsFeatureConfig"

    public init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self.service = service
        self._sharedCacheStore = WMFLockIsolated(sharedCacheStore)
        super.init()
        NotificationCenter.default.addObserver(forName: WMFNSNotification.coreDataStoreSetup, object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }
            self.handleSharedCacheStoreSetup()
        }
    }

    private func handleSharedCacheStoreSetup() {
        if sharedCacheStore == nil {
            self.sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
        }
    }

    // MARK: - Local Settings

    private var userDefaultsStore: WMFKeyValueStore? { WMFDataEnvironment.current.userDefaultsStore }

    /// Shared read and write for the plain on/off settings below. Each one lives in user defaults
    /// and is off when nothing has been stored yet.
    private func loadFlag(_ key: WMFUserDefaultsKey) -> Bool {
        (try? userDefaultsStore?.load(key: key.rawValue)) ?? false
    }

    private func saveFlag(_ key: WMFUserDefaultsKey, _ value: Bool) {
        try? userDefaultsStore?.save(key: key.rawValue, value: value)
    }

    public var developerSettingsEnableDeveloperMode: Bool {
        get { loadFlag(.developerSettingsEnableDeveloperMode) }
        set { saveFlag(.developerSettingsEnableDeveloperMode, newValue) }
    }

    public var doNotPostImageRecommendationsEdit: Bool {
        get { loadFlag(.developerSettingsDoNotPostImageRecommendationsEdit) }
        set { saveFlag(.developerSettingsDoNotPostImageRecommendationsEdit, newValue) }
    }

    @objc public var sendAnalyticsToWMFLabs: Bool {
        get { loadFlag(.developerSettingsSendAnalyticsToWMFLabs) }
        set { saveFlag(.developerSettingsSendAnalyticsToWMFLabs, newValue) }
    }

    public var bypassDonation: Bool {
        get { loadFlag(.bypassDonation) }
        set { saveFlag(.bypassDonation, newValue) }
    }

    public var forceEmailAuth: Bool {
        get { loadFlag(.forceEmailAuth) }
        set { saveFlag(.forceEmailAuth, newValue) }
    }

    public var forceMaxArticleTabsTo5: Bool {
        get { loadFlag(.developerSettingsForceMaxArticleTabsTo5) }
        set { saveFlag(.developerSettingsForceMaxArticleTabsTo5, newValue) }
    }

    public var forceHCaptchaChallenge: Bool {
        get { loadFlag(.forceHCaptchaChallenge) }
        set { saveFlag(.forceHCaptchaChallenge, newValue) }
    }

    public var allowGestureZoomArticleWebview: Bool {
        get { loadFlag(.allowGestureZoomArticleWebview) }
        set { saveFlag(.allowGestureZoomArticleWebview, newValue) }
    }

    // MARK: - Year in Review

    /// Debugging convenience: while on, 2026 Year in Review overrides every gate. The config counts
    /// as active outside its date window, and the entry point presents even with no 2026 config
    /// published, ignoring the opt-out toggle and the suppressed-country list. Replaces the separate
    /// entry point and date window flags, so nothing below it is respected.
    public var forceYiREntryPoint2026: Bool {
        get { loadFlag(.developerSettingsForceYiREntryPoint2026) }
        set {
            let oldValue = forceYiREntryPoint2026
            saveFlag(.developerSettingsForceYiREntryPoint2026, newValue)
            if oldValue != newValue {
                NotificationCenter.default.post(name: WMFNSNotification.yearInReviewActivityTabBadgeNeedsUpdate, object: nil)
            }
        }
    }

    /// Debugging convenience: which Year in Review experience to force, regardless of how much
    /// personalized data the account has. Nil means no override. Has an effect only when
    /// `forceYiREntryPoint2026` is also true.
    public var forceYiRUserDataState: WMFYearInReviewDataController.YiRUserDataState? {
        get {
            guard let rawValue: String = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceYiRUserDataState.rawValue) else {
                return nil
            }
            return WMFYearInReviewDataController.YiRUserDataState(rawValue: rawValue)
        }
        set {
            if let newValue {
                try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceYiRUserDataState.rawValue, value: newValue.rawValue)
            } else {
                try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.developerSettingsForceYiRUserDataState.rawValue)
            }
        }
    }

    /// Debugging convenience: while on, the 2026 Year in Review announcement ignores every gate —
    /// the remote config, its active window, the opt-out toggle, suppressed countries and the
    /// once-per-user state — so it presents before a 2026 config exists remotely and can be
    /// retriggered without reinstalling. Named `force` for the same reason as
    /// `forceYiREntryPoint2026`:
    /// nothing below it is respected.
    public var forceYiR2026Announcement: Bool {
        get { loadFlag(.developerSettingsForceYiR2026Announcement) }
        set { saveFlag(.developerSettingsForceYiR2026Announcement, newValue) }
    }

    // MARK: - Home

    /// Gates home feed work that ships after the initial Home tab experiment: the reworked community
    /// feed (replacing the embedded legacy Explore feed) and its settings. Only has an effect when
    /// `enableHomeTab` is also true.
    @objc public var enableHomePhase2: Bool {
        get { loadFlag(.developerSettingsEnableHomePhase2) }
        set {
            let oldValue = enableHomePhase2
            saveFlag(.developerSettingsEnableHomePhase2, newValue)
            if oldValue != newValue {
                NotificationCenter.default.post(name: WMFNSNotification.enableHomePhase2DidChange, object: nil)
            }
        }
    }

    /// True while the legacy Explore feed backs the Home tab's Community segment (home tab on, phase 2
    /// off). In this mode the feed is presented as the "Community feed" throughout the UI.
    public var isCommunityFeedMode: Bool {
        WMFHomeDataController.shared.persistedHomeTabAssignment() == .groupB && !enableHomePhase2
    }

    // MARK: - Fundraising

    /// Debugging convenience: when true, the fundraising campaign banner ignores country,
    /// date window, prompt state (maybe later / hidden), opt-out, and donation history gates,
    /// so it presents on every article view as long as any campaign config exists remotely.
    public var forceFundraisingCampaignBanner: Bool {
        get { loadFlag(.developerSettingsForceFundraisingCampaignBanner) }
        set { saveFlag(.developerSettingsForceFundraisingCampaignBanner, newValue) }
    }

    /// Debugging convenience: fetches the donate and fundraising campaign configs from Test Wiki
    /// instead of Donate wiki, so unpublished campaigns can be tested without the Staging scheme.
    public var useTestWikiDonateConfigs: Bool {
        get { loadFlag(.developerSettingsUseTestWikiDonateConfigs) }
        set {
            let oldValue = useTestWikiDonateConfigs
            saveFlag(.developerSettingsUseTestWikiDonateConfigs, newValue)
            if oldValue != newValue {
                refetchDonateConfigs()
            }
        }
    }

    /// Debugging convenience: skips the getPaymentMethods API call and uses a hardcoded
    /// Apple Pay response, so the native donate form works when the payments API rate limits the device.
    public var useHardcodedPaymentMethods: Bool {
        get { loadFlag(.developerSettingsUseHardcodedPaymentMethods) }
        set {
            let oldValue = useHardcodedPaymentMethods
            saveFlag(.developerSettingsUseHardcodedPaymentMethods, newValue)
            if oldValue != newValue {
                refetchDonateConfigs()
            }
        }
    }

    public var hardcodedPaymentMethodsOverride: WMFPaymentMethods? {
        guard useHardcodedPaymentMethods,
              let fileURL = Bundle.module.url(forResource: "donate-hardcoded-payment-methods", withExtension: "json"),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONDecoder().decode(WMFPaymentMethods.self, from: data)
    }

    private func refetchDonateConfigs() {
        WMFDonateDataController.shared.clearConfigCache()
        WMFFundraisingCampaignDataController.shared.clearConfigCache()
        guard let countryCode = Locale.current.region?.identifier else {
            return
        }
        WMFFundraisingCampaignDataController.shared.fetchConfig(countryCode: countryCode, currentDate: Date())
    }

    public var donateConfigsServiceEnvironment: WMFServiceEnvironment {
        useTestWikiDonateConfigs ? .staging : WMFDataEnvironment.current.serviceEnvironment
    }

    /// Resets everything that can suppress the fundraising campaign banner: the "maybe later" /
    /// permanently hidden prompt state, the local donation history, the saved donation reminder, the persisted donation
    /// reminder experiment bucket, and the wrap-up card seen state.
    public func clearFundraisingCampaignPersistence() {
        WMFFundraisingCampaignDataController.shared.clearPromptState()
        WMFDonateDataController.shared.deleteLocalDonationHistory()
        WMFDonationReminderDataController.shared.clearReminder()
        WMFDonationReminderDataController.shared.clearExperimentAssignment()
        WMFDonationReminderDataController.shared.clearWrapUpCardSeen()
    }

    /// Debugging convenience: overrides the persisted donation reminder experiment bucket at read
    /// time without re-rolling it. Nil means no override.
    public var forceDonationReminderExperimentAssignment: WMFDonationReminderDataController.ExperimentAssignment? {
        get {
            guard let rawValue: String = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceDonationReminderExperimentAssignment.rawValue) else {
                return nil
            }
            return WMFDonationReminderDataController.ExperimentAssignment(rawValue: rawValue)
        }
        set {
            if let newValue {
                try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceDonationReminderExperimentAssignment.rawValue, value: newValue.rawValue)
            } else {
                try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.developerSettingsForceDonationReminderExperimentAssignment.rawValue)
            }
        }
    }

    /// Debugging convenience: skips the follow-up reminder's once-per-day limit so we can see
    /// repeat impressions without changing the device date.
    public var bypassDonationReminderDailyLimit: Bool {
        get { loadFlag(.developerSettingsBypassDonationReminderDailyLimit) }
        set { saveFlag(.developerSettingsBypassDonationReminderDailyLimit, newValue) }
    }

    /// Debugging convenience: overrides the date that the fundraising features treat as today, so we
    /// can test the campaign and reminder date windows.
    public var fundraisingOverriddenCurrentDate: Date? {
        get { try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsFundraisingOverriddenCurrentDate.rawValue) }
        set {
            if let newValue {
                try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsFundraisingOverriddenCurrentDate.rawValue, value: newValue)
            } else {
                try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.developerSettingsFundraisingOverriddenCurrentDate.rawValue)
            }
        }
    }

    public var fundraisingCurrentDate: Date {
        fundraisingOverriddenCurrentDate ?? Date()
    }

    // MARK: - Semantic Search

    public var enableSemanticSearch: Bool {
        get { loadFlag(.developerSettingsEnableSemanticSearch) }
        set { saveFlag(.developerSettingsEnableSemanticSearch, newValue) }
    }

    /// Debugging convenience: overrides the persisted semantic search experiment bucket at read
    /// time without re-rolling it. The target language gate still applies. Nil means no override.
    public var forceSemanticSearchExperimentAssignment: WMFSemanticSearchDataController.ExperimentAssignment? {
        get {
            guard let rawValue: String = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceSemanticSearchExperimentAssignment.rawValue) else {
                return nil
            }
            return WMFSemanticSearchDataController.ExperimentAssignment(rawValue: rawValue)
        }
        set {
            if let newValue {
                try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceSemanticSearchExperimentAssignment.rawValue, value: newValue.rawValue)
            } else {
                try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.developerSettingsForceSemanticSearchExperimentAssignment.rawValue)
            }
        }
    }

    // MARK: - Remote Feature Flags

    /// Comes from `iosv1.visualEditorEnabled` in the remote feature config. A missing key or a
    /// missing config keeps the legacy source editor flow.
    public var isVisualEditorEnabled: Bool {
        loadFeatureConfig()?.ios.visualEditorEnabled ?? false
    }

    // MARK: - Remote Settings

    public func loadFeatureConfig() -> WMFFeatureConfigResponse? {
        guard featureConfig == nil else { return featureConfig }
        let featureConfig: WMFFeatureConfigResponse? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheFeatureConfigFileName)
        guard let featureConfigCachedDate = featureConfig?.cachedDate else { return nil }
        let fourHours = TimeInterval(60 * 60 * 4)
        guard (-featureConfigCachedDate.timeIntervalSinceNow) < fourHours else { return nil }
        self.featureConfig = featureConfig
        return featureConfig
    }

    @objc public func fetchFeatureConfig(completion: @escaping @Sendable (Error?) -> Void) {
        guard let service else {
            completion(WMFDataControllerError.basicServiceUnavailable)
            return
        }
        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage,
              let featureConfigURL = URL.featureConfigURL(project: WMFProject.wikipedia(primaryAppLanguage)) else {
            completion(WMFDataControllerError.failureCreatingRequestURL)
            return
        }
        let featureConfigRequest = WMFBasicServiceRequest(url: featureConfigURL, method: .GET, acceptType: .json)
        service.performDecodableGET(request: featureConfigRequest) { [weak self] (result: Result<WMFFeatureConfigResponse, Error>) in
            guard let self else { return }
            switch result {
            case .success(let response):
                self.featureConfig = response
                self.featureConfig?.cachedDate = Date()
                do {
                    try self.sharedCacheStore?.save(key: self.cacheDirectoryName, self.cacheFeatureConfigFileName, value: featureConfig)
                } catch {
                    print(error)
                }
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    @_spi(Testing) public func reset() {
        featureConfig = nil
        sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
    }
}
