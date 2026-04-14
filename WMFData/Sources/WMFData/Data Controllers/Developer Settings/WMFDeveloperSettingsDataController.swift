import Foundation

public protocol WMFDeveloperSettingsDataControlling: AnyObject {
    func loadFeatureConfig() -> WMFFeatureConfigResponse?
    var enableMoreDynamicTabsV2GroupC: Bool { get }
    var forceMaxArticleTabsTo5: Bool { get }
    var showYiRV3: Bool { get }
    var enableYiRLoginExperimentControl: Bool { get }
    var enableYiRLoginExperimentB: Bool { get }
    var devForceReadingChallengeEnabled: Bool { get set }
    var devForceReadingChallengeStreakCount: Int { get set }
    var devForceReadingChallengeCompletedFullStreak: Bool { get set }
    var devForceReadingChallengeCompletedIncompleteStreak: Bool { get set }
    var devForceReadingChallengeCompletedNoStreak: Bool { get set }
    var devForceReadingChallengeNotLiveYet: Bool { get set }
    var devForceReadingChallengeNotEnrolled: Bool { get set }
    var devForceReadingChallengeEnrolledNotStarted: Bool { get set }
    var devForceReadingChallengeStreakOngoingRead: Bool { get set }
    var devForceReadingChallengeStreakOngoingNotYetRead: Bool { get set }
    var forcedReadingChallengeState: ReadingChallengeState? { get }
    func transitionToEnrolledStateIfForced()
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

    public var enableMoreDynamicTabsV2GroupC: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsV2GroupC.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsV2GroupC.rawValue, value: newValue) }
    }

    public var showYiRV3: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowYiRV3.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowYiRV3.rawValue, value: newValue) }
    }

    public var enableYiRLoginExperimentControl: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentControl.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentControl.rawValue, value: newValue) }
    }

    public var enableYiRLoginExperimentB: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentB.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentB.rawValue, value: newValue) }
    }

    public var forceHCaptchaChallenge: Bool {
        get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue)) ?? false }
        set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue, value: newValue) }
    }

    // MARK: - Reading Challenge Forced States

    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: "group.org.wikimedia.wikipedia") }

    private func load(_ key: WMFUserDefaultsKey) -> Bool {
        sharedDefaults?.bool(forKey: key.rawValue) ?? false
    }

    private func save(_ key: WMFUserDefaultsKey, _ value: Bool) {
        sharedDefaults?.set(value, forKey: key.rawValue)
    }

    private func saveAndReloadWidget(_ key: WMFUserDefaultsKey, _ value: Bool) {
        save(key, value)
        NotificationCenter.default.post(name: WMFNSNotification.readingChallengeWidgetReload, object: nil)
    }

    private func clearAllForcedReadingChallengeStates() {
        let keys: [WMFUserDefaultsKey] = [
            .devForceReadingChallengeCompletedFullStreak,
            .devForceReadingChallengeCompletedIncompleteStreak,
            .devForceReadingChallengeCompletedNoStreak,
            .devForceReadingChallengeNotLiveYet,
            .devForceReadingChallengeNotEnrolled,
            .devForceReadingChallengeEnrolledNotStarted,
            .devForceReadingChallengeStreakOngoingRead,
            .devForceReadingChallengeStreakOngoingNotYetRead
        ]
        keys.forEach { save($0, false) }
    }

    /// When a user joins the challenge while dev force is enabled, transition the forced state to enrolledNotStarted
    public func transitionToEnrolledStateIfForced() {
        guard devForceReadingChallengeEnabled else { return }
        // Only transition from pre-enrolled states
        guard devForceReadingChallengeNotEnrolled || devForceReadingChallengeNotLiveYet || devForceReadingChallengeEnrolledNotStarted else { return }
        clearAllForcedReadingChallengeStates()
        saveAndReloadWidget(.devForceReadingChallengeEnrolledNotStarted, true)
    }

    public var devForceReadingChallengeEnabled: Bool {
        get { load(.devForceReadingChallengeEnabled) }
        set {
            saveAndReloadWidget(.devForceReadingChallengeEnabled, newValue)
            if newValue {
                if forcedReadingChallengeState == nil {
                    saveAndReloadWidget(.devForceReadingChallengeNotEnrolled, true)
                }
            } else {
                clearAllForcedReadingChallengeStates()
            }
        }
    }

    public var devForceReadingChallengeStreakCount: Int {
        get {
            let stored = sharedDefaults?.integer(forKey: WMFUserDefaultsKey.devForceReadingChallengeStreakCount.rawValue) ?? 0
            return stored == 0 ? 7 : stored
        }
        set {
            let clamped = min(max(newValue, 1), 25)
            sharedDefaults?.set(clamped, forKey: WMFUserDefaultsKey.devForceReadingChallengeStreakCount.rawValue)
            NotificationCenter.default.post(name: WMFNSNotification.readingChallengeWidgetReload, object: nil)
        }
    }

    public var devForceReadingChallengeCompletedFullStreak: Bool {
        get { load(.devForceReadingChallengeCompletedFullStreak) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeCompletedFullStreak, newValue) }
    }

    public var devForceReadingChallengeCompletedIncompleteStreak: Bool {
        get { load(.devForceReadingChallengeCompletedIncompleteStreak) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeCompletedIncompleteStreak, newValue) }
    }

    public var devForceReadingChallengeCompletedNoStreak: Bool {
        get { load(.devForceReadingChallengeCompletedNoStreak) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeCompletedNoStreak, newValue) }
    }

    public var devForceReadingChallengeNotLiveYet: Bool {
        get { load(.devForceReadingChallengeNotLiveYet) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeNotLiveYet, newValue) }
    }

    public var devForceReadingChallengeNotEnrolled: Bool {
        get { load(.devForceReadingChallengeNotEnrolled) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeNotEnrolled, newValue) }
    }

    public var devForceReadingChallengeEnrolledNotStarted: Bool {
        get { load(.devForceReadingChallengeEnrolledNotStarted) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeEnrolledNotStarted, newValue) }
    }

    public var devForceReadingChallengeStreakOngoingRead: Bool {
        get { load(.devForceReadingChallengeStreakOngoingRead) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeStreakOngoingRead, newValue) }
    }

    public var devForceReadingChallengeStreakOngoingNotYetRead: Bool {
        get { load(.devForceReadingChallengeStreakOngoingNotYetRead) }
        set { if newValue { clearAllForcedReadingChallengeStates() }; saveAndReloadWidget(.devForceReadingChallengeStreakOngoingNotYetRead, newValue) }
    }

    public var forcedReadingChallengeState: ReadingChallengeState? {
        if load(.devForceReadingChallengeCompletedFullStreak) { return .challengeCompleted }
        if load(.devForceReadingChallengeCompletedIncompleteStreak) { return .challengeConcludedIncomplete(streak: 12) }
        if load(.devForceReadingChallengeCompletedNoStreak) { return .challengeConcludedNoStreak }
        if load(.devForceReadingChallengeNotLiveYet) { return .notLiveYet }
        if load(.devForceReadingChallengeNotEnrolled) { return .notEnrolled }
        if load(.devForceReadingChallengeEnrolledNotStarted) { return .enrolledNotStarted }
        if load(.devForceReadingChallengeStreakOngoingRead) { return .streakOngoingRead(streak: 7) }
        if load(.devForceReadingChallengeStreakOngoingNotYetRead) { return .streakOngoingNotYetRead(streak: 7) }
        return nil
    }

    public func resetReadingChallengeState() {
        clearAllForcedReadingChallengeStates()
        let sharedDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")
        sharedDefaults?.set(false, forKey: WMFUserDefaultsKey.hasEnrolledInReadingChallenge2026.rawValue)
        sharedDefaults?.set(false, forKey: WMFUserDefaultsKey.hasSeenFullPageReadingChallengeAnnouncement2026.rawValue)
        sharedDefaults?.set(false, forKey: WMFUserDefaultsKey.hasSeenWidgetReadingChallengeAnnouncement2026.rawValue)
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
}
