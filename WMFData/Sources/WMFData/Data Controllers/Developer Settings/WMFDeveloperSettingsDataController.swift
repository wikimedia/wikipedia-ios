import Foundation

public protocol WMFDeveloperSettingsDataControlling: AnyObject {
    func loadFeatureConfig() -> WMFFeatureConfigResponse?
    var forceMaxArticleTabsTo5: Bool { get }
    var showYiR2025: Bool { get }
    var forceYiR2026: Bool { get }
    var forceYiR2026Announcement: Bool { get }
    var enableYiRLoginExperimentControl: Bool { get }
    var enableYiRLoginExperimentB: Bool { get }
}

@objc public final class WMFDeveloperSettingsDataController: NSObject, WMFDeveloperSettingsDataControlling {

    @objc public static let shared = WMFDeveloperSettingsDataController()

    private let service: WMFService?
    private var sharedCacheStore: WMFKeyValueStore?
    private var featureConfig: WMFFeatureConfigResponse?
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.developerSettings.rawValue
    
    private let cacheFeatureConfigFileName = "AppsFeatureConfig"

    public init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
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
    
    public var developerSettingsEnableDeveloperMode: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsEnableDeveloperMode.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsEnableDeveloperMode.rawValue, value: newValue) }
    }

    public var doNotPostImageRecommendationsEdit: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue, value: newValue) }
    }

    @objc public var sendAnalyticsToWMFLabs: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue, value: newValue) }
    }

    public var bypassDonation: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.bypassDonation.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.bypassDonation.rawValue, value: newValue) }
    }

    public var forceEmailAuth: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.forceEmailAuth.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.forceEmailAuth.rawValue, value: newValue) }
    }

    public var forceMaxArticleTabsTo5: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceMaxArticleTabsTo5.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceMaxArticleTabsTo5.rawValue, value: newValue) }
    }

    /// Debugging convenience: forces the 2025 Year in Review config active outside its date window.
    /// Kept so last year's feature can still be exercised; it has no effect on the 2026 config.
    public var showYiR2025: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowYiR2025.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowYiR2025.rawValue, value: newValue) }
    }
    
    // 2026 YIR
    /// Debugging convenience: while on, 2026 Year in Review overrides every gate. The config counts
    /// as active outside its date window, and the entry point presents even with no 2026 config
    /// published, ignoring the opt-out toggle and the suppressed-country list. Replaces the separate
    /// entry point and date window flags, so nothing below it is respected.
    /// Takes effect the next time the entry point is evaluated; relaunch to refresh the Activity tab badge.
    public var forceYiR2026: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceYiR2026.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceYiR2026.rawValue, value: newValue) }
    }

    /// Debugging convenience: while on, the 2026 Year in Review announcement ignores every gate —
    /// the remote config, its active window, the opt-out toggle, suppressed countries and the
    /// once-per-user state — so it presents before a 2026 config exists remotely and can be
    /// retriggered without reinstalling. Named `force` for the same reason as `forceYiR2026`:
    /// nothing below it is respected.
    public var forceYiR2026Announcement: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceYiR2026Announcement.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceYiR2026Announcement.rawValue, value: newValue) }
    }

    /// Gates home feed work that ships after the initial Home tab experiment: the reworked community
    /// feed (replacing the embedded legacy Explore feed) and its settings. Only has an effect when
    /// `enableHomeTab` is also true.
    @objc public var enableHomePhase2: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsEnableHomePhase2.rawValue)) ?? false }
        set {
            let oldValue = enableHomePhase2
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsEnableHomePhase2.rawValue, value: newValue)
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

    /// Debugging convenience: when true (and the home tab is enabled), the new app onboarding
    /// presents on every launch, ignoring the persisted "did show onboarding" flag.

    public var enableYiRLoginExperimentControl: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentControl.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentControl.rawValue, value: newValue) }
    }

    public var enableYiRLoginExperimentB: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentB.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentB.rawValue, value: newValue) }
    }

    /// Debugging convenience: when true, the fundraising campaign banner ignores country,
    /// date window, prompt state (maybe later / hidden), opt-out, and donation history gates,
    /// so it presents on every article view as long as any campaign config exists remotely.
    public var forceFundraisingCampaignBanner: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceFundraisingCampaignBanner.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceFundraisingCampaignBanner.rawValue, value: newValue) }
    }

    /// Debugging convenience: fetches the donate and fundraising campaign configs from Test Wiki
    /// instead of Donate wiki, so unpublished campaigns can be tested without the Staging scheme.
    public var useTestWikiDonateConfigs: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsUseTestWikiDonateConfigs.rawValue)) ?? false }
        set {
            let oldValue = useTestWikiDonateConfigs
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsUseTestWikiDonateConfigs.rawValue, value: newValue)
            if oldValue != newValue {
                refetchDonateConfigs()
            }
        }
    }

    /// Debugging convenience: skips the getPaymentMethods API call and uses a hardcoded
    /// Apple Pay response, so the native donate form works when the payments API rate limits the device.
    public var useHardcodedPaymentMethods: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsUseHardcodedPaymentMethods.rawValue)) ?? false }
        set {
            let oldValue = useHardcodedPaymentMethods
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsUseHardcodedPaymentMethods.rawValue, value: newValue)
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

    public var forceHCaptchaChallenge: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue, value: newValue) }
    }

    public var allowGestureZoomArticleWebview: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.allowGestureZoomArticleWebview.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.allowGestureZoomArticleWebview.rawValue, value: newValue) }
    }

    public var showGamesV2: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowGamesV2.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowGamesV2.rawValue, value: newValue) }
    }

    public func clearGamesPersistence() async throws {
        let gamesDataController = WMFGamesDataController()
        try await gamesDataController.clearAllSessions()
        gamesDataController.resetAnnouncementSeen()
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
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsBypassDonationReminderDailyLimit.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsBypassDonationReminderDailyLimit.rawValue, value: newValue) }
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
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsEnableSemanticSearch.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsEnableSemanticSearch.rawValue, value: newValue) }
    }

    /// Debugging convenience: overrides the persisted semantic search experiment bucket at read
    /// time without re-rolling it, and bypasses the target language gate. Nil means no override.
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

    // MARK: - Reading Challenge Forced States

    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: "group.org.wikimedia.wikipedia") }

    private func loadSharedStore(_ key: WMFUserDefaultsKey) -> Any? {
        sharedDefaults?.value(forKey: key.rawValue)
    }

    private func saveSharedStore(_ key: WMFUserDefaultsKey, _ value: Any?) {
        sharedDefaults?.set(value, forKey: key.rawValue)
        sharedDefaults?.synchronize()
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

    @objc public func fetchFeatureConfig(completion: @escaping (Error?) -> Void) {
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
