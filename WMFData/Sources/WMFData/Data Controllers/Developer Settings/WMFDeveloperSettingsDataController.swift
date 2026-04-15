import Foundation

public protocol WMFDeveloperSettingsDataControlling: AnyObject {
    func loadFeatureConfig() -> WMFFeatureConfigResponse?
    var enableMoreDynamicTabsV2GroupC: Bool { get }
    var forceMaxArticleTabsTo5: Bool { get }
    var showYiRV3: Bool { get }
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

    private func loadSharedStore(_ key: WMFUserDefaultsKey) -> Any? {
        sharedDefaults?.value(forKey: key.rawValue)
    }

    private func saveSharedStore(_ key: WMFUserDefaultsKey, _ value: Any?) {
        sharedDefaults?.set(value, forKey: key.rawValue)
    }
    
    public func devClearAllReadingChallengePersistence() {
        let sharedDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")
        
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.devReadingChallengeCurrentDate.rawValue)
        
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.hasEnrolledInReadingChallenge2026.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.hasSeenFullPageReadingChallengeAnnouncement2026.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.readingChallengeUserCompleted.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.readingChallengeStreakReadRandomIndex.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.readingChallengeStreakReadRandomIndexDate.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.readingChallengeStreakNotReadRandomIndex.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.readingChallengeStreakNotReadRandomIndexDate.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.readingChallengeEnrolledNotStartedRandomIndex.rawValue)
        sharedDefaults?.set(nil, forKey: WMFUserDefaultsKey.readingChallengeEnrolledNotStartedRandomIndexDate.rawValue)
        sharedDefaults?.synchronize()
        
        Task {
            let dataController = try? WMFPageViewsDataController()
            try? await dataController?.deleteAllPageViewsAndCategories()
            
            NotificationCenter.default.post(name: WMFNSNotification.readingChallengeWidgetReload, object: nil)
        }
    }
    
    public var devReadingChallengeOverrideCurrentDate: Bool? {
        loadSharedStore(.devReadingChallengeOverrideCurrentDate) as? Bool
    }
    
    public func setDevReadingChallengeOverrideCurrentDate(_ value: Bool?) {
        saveSharedStore(.devReadingChallengeOverrideCurrentDate, value)
    }
    
    public func reloadWidget() {
        NotificationCenter.default.post(name: WMFNSNotification.readingChallengeWidgetReload, object: nil)
    }

    public var devReadingChallengeCurrentDate: Date? {
        loadSharedStore(.devReadingChallengeCurrentDate) as? Date
    }
    
    public func setDevReadingChallengeCurrentDate(_ date: Date?) {
        saveSharedStore(.devReadingChallengeCurrentDate, date)
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
