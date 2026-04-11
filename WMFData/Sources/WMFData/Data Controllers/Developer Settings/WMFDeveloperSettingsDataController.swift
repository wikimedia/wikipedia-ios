import Foundation

public protocol WMFDeveloperSettingsDataControlling: AnyObject {
    func loadFeatureConfigSyncBridge() -> WMFFeatureConfigResponse?
    var enableMoreDynamicTabsV2GroupCSyncBridge: Bool { get }
    var forceMaxArticleTabsTo5SyncBridge: Bool { get }
    var showYiRV3SyncBridge: Bool { get }
    var enableYiRLoginExperimentControlSyncBridge: Bool { get }
    var enableYiRLoginExperimentBSyncBridge: Bool { get }
}

// MARK: - Pure Swift Actor (Clean Implementation)

@objc public actor WMFDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {

    @objc public static let shared = WMFDeveloperSettingsDataController()
    
    private let service: WMFService?
    nonisolated(unsafe) private var sharedCacheStore: WMFKeyValueStore?
    
    nonisolated(unsafe) private var featureConfig: WMFFeatureConfigResponse?
    
    nonisolated(unsafe) private let cacheDirectoryName = WMFSharedCacheDirectoryNames.developerSettings.rawValue
    nonisolated(unsafe) private let cacheFeatureConfigFileName = "AppsFeatureConfig"
    
    public init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
        
        NotificationCenter.default.addObserver(
            forName: WMFNSNotification.coreDataStoreSetup,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            self.handleSharedCacheStoreSetup()
        }
    }
    
    private func handleSharedCacheStoreSetup() {
        if sharedCacheStore == nil {
            self.sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
        }
    }
    
    // MARK: - Local Settings from App Settings Menu

    nonisolated(unsafe) private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
    public var doNotPostImageRecommendationsEdit: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue)) ?? false
    }
    
    public func setDoNotPostImageRecommendationsEdit(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue, value: value)
    }
    
    public var sendAnalyticsToWMFLabs: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue)) ?? false
    }
    
    public func setSendAnalyticsToWMFLabs(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue, value: value)
    }

    public var bypassDonation: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.bypassDonation.rawValue)) ?? false
    }
    
    public func setBypassDonation(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.bypassDonation.rawValue, value: value)
    }

    public var forceEmailAuth: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.forceEmailAuth.rawValue)) ?? false
    }
    
    public func setForceEmailAuth(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.forceEmailAuth.rawValue, value: value)
    }
    
    public var forceMaxArticleTabsTo5: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceMaxArticleTabsTo5.rawValue)) ?? false
    }
    
    public func setForceMaxArticleTabsTo5(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceMaxArticleTabsTo5.rawValue, value: value)
    }

    public var enableMoreDynamicTabsV2GroupC: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsV2GroupC.rawValue)) ?? false
    }
    
    public func setEnableMoreDynamicTabsV2GroupC(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsV2GroupC.rawValue, value: value)
    }

    public var showYiRV3: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowYiRV3.rawValue)) ?? false
    }
    
    public func setShowYiRV3(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowYiRV3.rawValue, value: value)
    }
    
    public var enableYiRLoginExperimentControl: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentControl.rawValue)) ?? false
    }
    
    public func setEnableYiRLoginExperimentControl(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentControl.rawValue, value: value)
    }
    
    public var enableYiRLoginExperimentB: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentB.rawValue)) ?? false
    }
    
    public func setEnableYiRLoginExperimentB(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentB.rawValue, value: value)
    }
    
    public var forceHCaptchaChallenge: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue, value: newValue)
        }
    }
    
    public func setForceHCaptchaChallenge(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue, value: value)
    }

    // MARK: - Remote Settings from https://en.wikipedia.org/api/rest_v1/configuration
    
    public func loadFeatureConfig() -> WMFFeatureConfigResponse? {
        
        // First pull from memory
        guard featureConfig == nil else {
            return featureConfig
        }
        
        // Fall back to persisted objects if within four hours
        let featureConfig: WMFFeatureConfigResponse? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheFeatureConfigFileName)
        
        guard let featureConfigCachedDate = featureConfig?.cachedDate else {
            return nil
        }
        
        let fourHours = TimeInterval(60 * 60 * 4)
        guard (-featureConfigCachedDate.timeIntervalSinceNow) < fourHours else {
            return nil
        }
        
        self.featureConfig = featureConfig
        
        return featureConfig
    }
    
    public func fetchFeatureConfig() async throws {

        guard let service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage,
            let featureConfigURL = URL.featureConfigURL(project: WMFProject.wikipedia(primaryAppLanguage)) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let featureConfigRequest = WMFBasicServiceRequest(url: featureConfigURL, method: .GET, acceptType: .json)
        
        let response: WMFFeatureConfigResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: featureConfigRequest) { (result: Result<WMFFeatureConfigResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        var updatedResponse = response
        updatedResponse.cachedDate = Date()
        self.featureConfig = updatedResponse

        try? sharedCacheStore?.save(key: cacheDirectoryName, cacheFeatureConfigFileName, value: updatedResponse)
    }
}

// MARK: - Sync Bridge Extension

extension WMFDeveloperSettingsDataController {
    nonisolated public var doNotPostImageRecommendationsEditSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue)) ?? false
    }
    
    nonisolated public var sendAnalyticsToWMFLabsSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsSendAnalyticsToWMFLabs.rawValue)) ?? false
    }
    
    nonisolated public var bypassDonationSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.bypassDonation.rawValue)) ?? false
    }
    
    nonisolated public var forceEmailAuthSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.forceEmailAuth.rawValue)) ?? false
    }
    
    nonisolated public var showYiRV3SyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowYiRV3.rawValue)) ?? false
    }
    
    nonisolated public var enableYiRLoginExperimentBSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentB.rawValue)) ?? false
    }
    
    nonisolated public var enableYiRLoginExperimentControlSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsYiRV3LoginExperimentControl.rawValue)) ?? false
    }
    
    nonisolated public var forceMaxArticleTabsTo5SyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceMaxArticleTabsTo5.rawValue)) ?? false
    }
    
    nonisolated public var enableMoreDynamicTabsV2GroupCSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsV2GroupC.rawValue)) ?? false
    }
    
    nonisolated public var forceHCaptchaChallengeSyncBridge: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.forceHCaptchaChallenge.rawValue)) ?? false
    }
    
    nonisolated public func loadFeatureConfigSyncBridge() -> WMFFeatureConfigResponse? {
        if let featureConfig { return featureConfig }
        guard let cached: WMFFeatureConfigResponse = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheFeatureConfigFileName),
              let cachedDate = cached.cachedDate,
              (-cachedDate.timeIntervalSinceNow) < TimeInterval(60 * 60 * 4) else {
            return nil
        }
        return cached
    }
    
    @objc nonisolated public func fetchFeatureConfig(completion: @escaping @Sendable (Error?) -> Void) {
        Task {
            do {
                try await fetchFeatureConfig()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
