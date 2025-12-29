import Foundation

public protocol WMFDeveloperSettingsDataControlling: AnyObject {
    func loadFeatureConfig() async -> WMFFeatureConfigResponse?
    var enableMoreDynamicTabsV2GroupC: Bool { get async }
    var forceMaxArticleTabsTo5: Bool { get async }
    var showYiRV3: Bool { get async }
    var enableYiRLoginExperimentControl: Bool { get async }
    var enableYiRLoginExperimentB: Bool { get async }
    var showActivityTab: Bool { get async }
    var forceActivityTabControl: Bool { get async }
    var forceActivityTabExperiment: Bool { get async }
}

// MARK: - Pure Swift Actor (Clean Implementation)

@objc public actor WMFDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {

    @objc public static let shared = WMFDeveloperSettingsDataController()
    
    private let service: WMFService?
    private let sharedCacheStore: WMFKeyValueStore?
    
    private var featureConfig: WMFFeatureConfigResponse?
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.developerSettings.rawValue
    private let cacheFeatureConfigFileName = "AppsFeatureConfig"
    
    public init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
    }
    
    // MARK: - Local Settings from App Settings Menu

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
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
    
    public var showActivityTab: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue)) ?? false
    }
    
    public func setShowActivityTab(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue, value: value)
    }

    public var forceActivityTabControl: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceActivityTabControl.rawValue)) ?? false
    }
    
    public func setForceActivityTabControl(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceActivityTabControl.rawValue, value: value)
    }

    public var forceActivityTabExperiment: Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceActivityTabExperiment.rawValue)) ?? false
    }
    
    public func setForceActivityTabExperiment(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceActivityTabExperiment.rawValue, value: value)
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

// Sync Bridge Methods

extension WMFDeveloperSettingsDataController {
    nonisolated public var doNotPostImageRecommendationsEditSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await doNotPostImageRecommendationsEdit
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var sendAnalyticsToWMFLabsSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await sendAnalyticsToWMFLabs
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var bypassDonationSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await bypassDonation
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var forceEmailAuthSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await forceEmailAuth
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var showActivityTabSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await showActivityTab
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var forceActivityTabControlSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await forceActivityTabControl
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var forceActivityTabExperimentSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await forceActivityTabExperiment
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var showYiRV3SyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await showYiRV3
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var enableYiRLoginExperimentBSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await enableYiRLoginExperimentB
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var enableYiRLoginExperimentControlSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await enableYiRLoginExperimentControl
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var forceMaxArticleTabsTo5SyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await forceMaxArticleTabsTo5
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public var enableMoreDynamicTabsV2GroupCSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await enableMoreDynamicTabsV2GroupC
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    
    nonisolated public func loadFeatureConfigSyncBridge() -> WMFFeatureConfigResponse? {
        var result: WMFFeatureConfigResponse? = nil
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            result = await loadFeatureConfig()
            semaphore.signal()
        }
        semaphore.wait()
        return result
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
