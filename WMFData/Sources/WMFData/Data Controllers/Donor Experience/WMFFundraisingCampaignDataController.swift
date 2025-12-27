import Foundation

// MARK: - Pure Swift Actor (Clean Implementation)

public actor WMFFundraisingCampaignDataController {
    
    public static let shared = WMFFundraisingCampaignDataController()
    
    // MARK: - Properties
    
    private let service: WMFService?
    private let sharedCacheStore: WMFKeyValueStore?
    private let mediaWikiService: WMFService?
    
    private var activeCountryConfigs: [WMFFundraisingCampaignConfig] = []
    private var promptState: WMFFundraisingCampaignPromptState?
    private var preferencesBannerOptIns: [WMFProject: Bool] = [:]
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.donorExperience.rawValue
    private let cacheConfigFileName = "AppsCampaignConfig"
    private let cachePromptStateFileName = "WMFFundraisingCampaignPromptState"

    // MARK: - Lifecycle
    
    private init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore, mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
        self.mediaWikiService = mediaWikiService
    }
    
    // MARK: - Public
    
    public func isOptedIn(project: WMFProject) -> Bool {
        return preferencesBannerOptIns[project] ?? true
    }
    
    /// Set asset as "maybe later" in persistence, so that it can me loaded later only once the maybe later date has passed
    /// - Parameters:
    ///   - asset: WMFAsset to mark as maybe later
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    public func markAssetAsMaybeLater(asset: WMFFundraisingCampaignConfig.WMFAsset, currentDate: Date) {
        guard let oneDayLater = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
            return
        }
        let nextDayMidnight = Calendar.current.startOfDay(for: oneDayLater)
        let promptState = WMFFundraisingCampaignPromptState(campaignID: asset.id, isHidden: false, maybeLaterDate: nextDayMidnight)
        try? sharedCacheStore?.save(key: cacheDirectoryName, cachePromptStateFileName, value: promptState)
        self.promptState = promptState
    }

    
    /// Determine if "maybe later option"should be displayed
    /// - Parameters:
    ///   - asset: WMFAsset displayed
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    /// - Returns: Bool
    nonisolated public func showShowMaybeLaterOption(asset: WMFFundraisingCampaignConfig.WMFAsset, currentDate: Date) -> Bool {

        let calendar = Calendar.current
        let endDateComponents = calendar.dateComponents([.year, .month, .day], from: asset.endDate)
        let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)

        return !(endDateComponents == currentDateComponents)
    }

    /// Set asset as permanently hidden in persistence, so that it cannot be loaded and displayed on subsequent attempts.
    /// - Parameter asset: WMFAsset to mark as hidden
    public func markAssetAsPermanentlyHidden(asset: WMFFundraisingCampaignConfig.WMFAsset) {
        let promptState = WMFFundraisingCampaignPromptState(campaignID: asset.id, isHidden: true, maybeLaterDate: nil)
        try? sharedCacheStore?.save(key: cacheDirectoryName, cachePromptStateFileName, value: promptState)
        self.promptState = promptState
    }
    
    /// Load actively running campaign text. This method automatically filters out campaigns that:
    ///     1. Have start or end dates that do not contain the current date param
    ///     2. That were flagged as permanently hidden or "maybe later" and "maybe later" date has not come to pass
    ///     3. That do not have a country code that matches the country code param
    ///     4. That do not have translation text for the associated wiki param (wmfProject).
    ///
    /// - Parameters:
    ///   - countryCode: Country code of the user. Can use Locale.current.regionCode
    ///   - wmfProject: wmfProject to pull translated campaign text against. Send in the article view project if displaying campaign text on article.
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    /// - Returns: WMFAsset containing information to display in campaign modal.
    public func loadActiveCampaignAsset(countryCode: String, wmfProject: WMFProject, currentDate: Date) -> WMFFundraisingCampaignConfig.WMFAsset? {
        
        guard activeCountryConfigs.isEmpty else {
            
            // re-filter activeCountryConfigs in case campaigns have ended
            self.activeCountryConfigs = activeCountryConfigs(from: activeCountryConfigs, currentDate: currentDate)
            
            return queuedActiveLanguageSpecificAsset(languageCode: wmfProject.languageCode, languageVariantCode: wmfProject.languageVariantCode, currentDate: currentDate)
        }
        
        // Load old response from cache and return first asset with matching country code, valid date, and matching language assets.
        let cachedResult: WMFFundraisingCampaignConfigResponse? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheConfigFileName)
        
        if let cachedResult {
            activeCountryConfigs = activeCountryConfigs(from: cachedResult, countryCode: countryCode, currentDate: currentDate)

            return queuedActiveLanguageSpecificAsset(languageCode: wmfProject.languageCode, languageVariantCode: wmfProject.languageVariantCode, currentDate: currentDate)
        }
        
        return nil
    }

    /// Fetches the apps campaign configuration data at https://donate.wikimedia.org/w/index.php?title=MediaWiki:AppsCampaignConfig.json and caches the response. Valid assets can be loaded with loadActiveCampaignAsset
    /// - Parameters:
    ///   - countryCode: Country code of the user. Can use Locale.current.regionCode
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    public func fetchConfig(countryCode: String, currentDate: Date) async throws {
        guard let service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }
        
        guard let url = URL.fundraisingCampaignConfigURL() else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let parameters: [String: Any] = [
            "action": "raw"
        ]
        
        let request = WMFBasicServiceRequest(url: url, method: .GET, parameters: parameters, acceptType: .json)
        
        let response: WMFFundraisingCampaignConfigResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<WMFFundraisingCampaignConfigResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        activeCountryConfigs = self.activeCountryConfigs(from: response, countryCode: countryCode, currentDate: currentDate)
        
        try? sharedCacheStore?.save(key: cacheDirectoryName, cacheConfigFileName, value: response)
    }
    
    public func fetchMediaWikiBannerOptIn(project: WMFProject) async throws {
        guard let mediaWikiService else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let parameters: [String: Any] = [
            "action": "query",
            "meta": "userinfo",
            "uiprop": "options",
            "format": "json"
        ]
        
        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        let actor = self
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            mediaWikiService.perform(request: request) { (result: Result<[String: Any]?, Error>) in
                
                // Extract Sendable data before Task
                let optInValue: Bool?
                switch result {
                case .success(let dict):
                    if let query = dict?["query"] as? [String: Any],
                       let userInfo = query["userinfo"] as? [String: Any],
                       let options = userInfo["options"] as? [String: Any],
                       options.keys.contains("centralnotice-display-campaign-type-fundraising") {
                        
                        optInValue = (options["centralnotice-display-campaign-type-fundraising"] as? Bool) ?? false
                    } else {
                        optInValue = nil
                    }
                case .failure(let error):
                    Task {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                
                Task {
                    if let value = optInValue {
                        await actor.setOptIn(project: project, value: value)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func setOptIn(project: WMFProject, value: Bool) {
        preferencesBannerOptIns[project] = value
    }
    
    // MARK: - Internal
    
    func reset() {
        activeCountryConfigs = []
        promptState = nil
    }
    
    // MARK: - Private
    
    private func queuedActiveLanguageSpecificAsset(languageCode: String?, languageVariantCode: String?, currentDate: Date) -> WMFFundraisingCampaignConfig.WMFAsset? {
        
        guard let asset = activeLanguageSpecificAsset(languageCode: languageCode, languageVariantCode: languageVariantCode) else {
            return nil
        }
        
        let validateAsset: ((WMFFundraisingCampaignConfig.WMFAsset, WMFFundraisingCampaignPromptState) -> WMFFundraisingCampaignConfig.WMFAsset?) = { asset, promptState in
            guard promptState.campaignID == asset.id else {
                return asset
            }
            
            // We have saved some state on the campaign ID. Check to confirm it hasn't been permanently hidden and maybe later date has passed
            
            guard promptState.isHidden == false else {
                return nil
            }
            
            guard let maybeLaterDate = promptState.maybeLaterDate else {
                return asset
            }
            
            guard maybeLaterDate <= currentDate else {
                return nil
            }
            
            return asset
        }
         
        if let promptState {
            return validateAsset(asset, promptState)
        } else if let promptState: WMFFundraisingCampaignPromptState = try? sharedCacheStore?.load(key: cacheDirectoryName, cachePromptStateFileName) {
            return validateAsset(asset, promptState)
        } else {
            return asset
        }
    }
    
    private func activeLanguageSpecificAsset(languageCode: String?, languageVariantCode: String?) -> WMFFundraisingCampaignConfig.WMFAsset? {
        
        guard let languageCode else {
            return nil
        }
        
        for config in activeCountryConfigs {
            if let languageCodeAsset = config.assets[languageCode] {
                return languageCodeAsset
            } else if let languageVariantCode,
                let languageVariantCodeAsset = config.assets[languageVariantCode] {
                return languageVariantCodeAsset
            }
        }
        
        return nil
    }
    
    private func activeCountryConfigs(from currentConfigs: [WMFFundraisingCampaignConfig], currentDate: Date) -> [WMFFundraisingCampaignConfig] {
        
        var configs: [WMFFundraisingCampaignConfig] = []
        currentConfigs.forEach { config in
            
            guard let firstAsset = config.assets.values.first else {
                return
            }
            
            
            guard (firstAsset.startDate...firstAsset.endDate).contains(currentDate) else {
                return
            }
            
            configs.append(config)
        }
        
        return configs
    }
    
    private func activeCountryConfigs(from response: WMFFundraisingCampaignConfigResponse, countryCode: String, currentDate: Date) -> [WMFFundraisingCampaignConfig] {
            
        var configs: [WMFFundraisingCampaignConfig] = []
        
        for config in response.configs {
            
            guard config.countryCodes.contains(countryCode) else {
                continue
            }
            
            let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
            guard let startDate = dateFormatter.date(from: config.startTimeString),
                  let endDate = dateFormatter.date(from: config.endTimeString) else {
                continue
            }
            
            guard (startDate...endDate).contains(currentDate) else {
                continue
            }
            
            var finalAssets: [String: WMFFundraisingCampaignConfig.WMFAsset] = [:]
            
            for (key, value) in config.assets {
                
                guard !value.isEmpty else {
                    continue
                }
                let appInstallID = WMFDataEnvironment.current.appInstallIDUtility?() ?? "TEST-INSTALL-ID"

                let seed = "\(config.id)|\(key)|\(appInstallID)"
                let randomAsset = randomAssetFrom(assets: value, seed: seed)

                let actions: [WMFFundraisingCampaignConfig.WMFAsset.WMFAction] = randomAsset.actions.map { action in
                    
                    guard let urlString = action.urlString?.replacingOccurrences(of: "$platform;", with: "iOS"),
                       let url = URL(string: urlString) else {
                        return WMFFundraisingCampaignConfig.WMFAsset.WMFAction(title: action.title, url: nil)
                    }
                    
                    return WMFFundraisingCampaignConfig.WMFAsset.WMFAction(title: action.title, url: url)
                }

                let asset = WMFFundraisingCampaignConfig.WMFAsset(id: config.id, assetID: randomAsset.id, textHtml: randomAsset.text, footerHtml: randomAsset.footer, actions: actions, countryCode: countryCode, currencyCode: randomAsset.currencyCode, startDate: startDate, endDate: endDate, languageCode: key)
                finalAssets[key] = asset
            }
            
            configs.append(WMFFundraisingCampaignConfig(id: config.id, assets: finalAssets))
        }
        
        return configs
    }


    // MARK: - Deterministic bucketing

    /// Stable hash mapped to [0, 1).
    private func stableHash01(_ seed: String) -> Double {
        // FNV-1a 64-bit
        var hash: UInt64 = 1469598103934665603
        let prime: UInt64 = 1099511628211
        for b in seed.utf8 {
            hash ^= UInt64(b)
            hash &*= prime
        }
        return Double(hash) / Double(UInt64.max)
    }

    /// Deterministically picks one asset using (optionally) weighted A/B configuration.
    private func randomAssetFrom(assets: [WMFFundraisingCampaignConfigResponse.FundraisingCampaignConfig.Asset], seed: String
    ) -> WMFFundraisingCampaignConfigResponse.FundraisingCampaignConfig.Asset {
        guard !assets.isEmpty else { return assets[0] }

        let weights = assets.compactMap { $0.weight.map(Double.init) }
        if weights.count != assets.count || !weights.allSatisfy({ $0 >= 0 }) {
            return assets[0]
        }

        let sum = weights.reduce(0, +)
        if abs(sum - 1.0) >= 1e-6 { // tolerence for 0.000001
            return assets[0]
        }

        let stableSeed = stableHash01(seed)
        var currentSum = 0.0
        for (index, weight) in weights.enumerated() {
            currentSum += weight
            if stableSeed <= currentSum || index == weights.count - 1 {
                return assets[index]
            }
        }
        return assets[0]
    }

}

// MARK: - Objective-C Bridge

@objc final public class WMFFundraisingCampaignDataControllerSyncBridge: NSObject, @unchecked Sendable {
    
    @objc(sharedInstance)
    public static let shared = WMFFundraisingCampaignDataControllerSyncBridge(controller: .shared)
    
    private let controller: WMFFundraisingCampaignDataController
    
    public init(controller: WMFFundraisingCampaignDataController) {
        self.controller = controller
        super.init()
    }
    
    public func isOptedIn(project: WMFProject, completion: @escaping @Sendable (Bool) -> Void) {
        let controller = self.controller
        Task {
            let result = await controller.isOptedIn(project: project)
            completion(result)
        }
    }
    
    public func markAssetAsMaybeLater(asset: WMFFundraisingCampaignConfig.WMFAsset, currentDate: Date) {
        let controller = self.controller
        Task {
            await controller.markAssetAsMaybeLater(asset: asset, currentDate: currentDate)
        }
    }
    
    public func markAssetAsPermanentlyHidden(asset: WMFFundraisingCampaignConfig.WMFAsset) {
        let controller = self.controller
        Task {
            await controller.markAssetAsPermanentlyHidden(asset: asset)
        }
    }
    
    public func loadActiveCampaignAsset(countryCode: String, wmfProject: WMFProject, currentDate: Date, completion: @escaping @Sendable (WMFFundraisingCampaignConfig.WMFAsset?) -> Void) {
        let controller = self.controller
        Task {
            let result = await controller.loadActiveCampaignAsset(countryCode: countryCode, wmfProject: wmfProject, currentDate: currentDate)
            completion(result)
        }
    }
    
    @objc public func fetchConfig(countryCode: String, currentDate: Date) {
        let controller = self.controller
        Task {
            try? await controller.fetchConfig(countryCode: countryCode, currentDate: currentDate)
        }
    }
    
    @objc public func fetchConfig(countryCode: String, currentDate: Date, completion: @escaping @Sendable (Error?) -> Void) {
        let controller = self.controller
        Task {
            do {
                try await controller.fetchConfig(countryCode: countryCode, currentDate: currentDate)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func fetchMediaWikiBannerOptIn(project: WMFProject, completion: @escaping @Sendable (Error?) -> Void) {
        let controller = self.controller
        Task {
            do {
                try await controller.fetchMediaWikiBannerOptIn(project: project)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}

// MARK: - Private Models

private struct WMFFundraisingCampaignConfigResponse: Codable {
    
    struct FundraisingCampaignConfig: Codable {
        
        struct Platforms: Codable {
            let ios: [String: String]
            
            enum CodingKeys: String, CodingKey {
                case ios = "iOS"
            }
        }
        
        struct Asset: Codable {
            
            struct Action: Codable {
                let title: String
                let urlString: String?
                
                enum CodingKeys: String, CodingKey {
                    case title = "title"
                    case urlString = "url"
                }
            }
            
            let weight: Float?
            let id: String?
            let text: String
            let footer: String
            let actions: [Action]
            let currencyCode: String
            
            enum CodingKeys: String, CodingKey {
                case id, weight
                case text = "text"
                case footer = "footer"
                case actions = "actions"
                case currencyCode = "currency_code"
            }
        }

        let startTimeString: String
        let endTimeString: String
        let id: String
        let platforms: Platforms
        let version: Int
        let countryCodes: [String]
        let assets: [String: [Asset]]
        
        enum CodingKeys: String, CodingKey {
            case startTimeString = "start_time"
            case endTimeString = "end_time"
            case id = "id"
            case platforms = "platforms"
            case version = "version"
            case countryCodes = "countries"
            case assets = "assets"
        }
    }
    
    static let currentVersion = 2
    let configs: [FundraisingCampaignConfig]
    
    init(from decoder: Decoder) throws {
        
        // Custom decoding to ignore invalid versions
        
        var versionContainer = try decoder.unkeyedContainer()
        var campaignContainer = try decoder.unkeyedContainer()
        
        var validVersionConfigs: [FundraisingCampaignConfig] = []
        while !versionContainer.isAtEnd {
            
            let wmfVersion: WMFConfigVersion
            let config: FundraisingCampaignConfig
            do {
                wmfVersion = try versionContainer.decode(WMFConfigVersion.self)
            } catch {
                // Skip
                _ = try? versionContainer.decode(WMFDiscardedElement.self)
                _ = try? campaignContainer.decode(WMFDiscardedElement.self)
                continue
            }
            
            guard wmfVersion.version == Self.currentVersion else {
                _ = try? campaignContainer.decode(WMFDiscardedElement.self)
                continue
            }
                
            do {
                config = try campaignContainer.decode(FundraisingCampaignConfig.self)
            } catch {
                // Skip
                _ = try? campaignContainer.decode(WMFDiscardedElement.self)
                continue
            }
            
            validVersionConfigs.append(config)
        }
        
        self.configs = validVersionConfigs
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: configs)
    }
}

private struct WMFFundraisingCampaignPromptState: Codable {
    let campaignID: String
    let isHidden: Bool
    let maybeLaterDate: Date?
}
