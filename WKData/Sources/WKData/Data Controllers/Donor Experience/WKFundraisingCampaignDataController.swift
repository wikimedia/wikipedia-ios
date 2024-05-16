import Foundation

@objc final public class WKFundraisingCampaignDataController: NSObject {
    
    private actor SafeDictionary<Key: Hashable, Value> {
        private var dictionary: [Key: Value]
        init(dict: [Key: Value] = [Key: Value]()) {
            self.dictionary = dict
        }
        
        func getValue(forKey key: Key) -> Value? {
            dictionary[key]
        }
        
        func update(value: Value, forKey key: Key) {
            dictionary[key] = value
        }
    }
    
    // MARK: - Properties
    
    var service: WKService?
    var sharedCacheStore: WKKeyValueStore?
    var mediaWikiService: WKService?
    
    private var activeCountryConfigs: [WKFundraisingCampaignConfig] = []
    private var promptState: WKFundraisingCampaignPromptState?
    private var preferencesBannerOptIns: SafeDictionary<WKProject, Bool> = SafeDictionary<WKProject, Bool>()
    
    private let cacheDirectoryName = WKSharedCacheDirectoryNames.donorExperience.rawValue
    private let cacheConfigFileName = "AppsCampaignConfig"
    private let cachePromptStateFileName = "WKFundraisingCampaignPromptState"
    
    // MARK: - Lifecycle
    
    private init(service: WKService? = WKDataEnvironment.current.basicService, sharedCacheStore: WKKeyValueStore? = WKDataEnvironment.current.sharedCacheStore, mediaWikiService: WKService? = WKDataEnvironment.current.mediaWikiService) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
        self.mediaWikiService = mediaWikiService
    }
    
    @objc(sharedInstance)
    public static let shared = WKFundraisingCampaignDataController()
    
    // MARK: - Public
    
    public func isOptedIn(project: WKProject) async -> Bool {
        return await preferencesBannerOptIns.getValue(forKey: project) ?? true
    }
    
    /// Set asset as "maybe later" in persistence, so that it can me loaded later only once the maybe later date has passed
    /// - Parameters:
    ///   - asset: WKAsset to mark as maybe later
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    public func markAssetAsMaybeLater(asset: WKFundraisingCampaignConfig.WKAsset, currentDate: Date) {
        guard let oneDayLater = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
            return
        }
        let nextDayMidnight = Calendar.current.startOfDay(for: oneDayLater)
        let promptState = WKFundraisingCampaignPromptState(campaignID: asset.id, isHidden: false, maybeLaterDate: nextDayMidnight)
        try? sharedCacheStore?.save(key: cacheDirectoryName, cachePromptStateFileName, value: promptState)
        self.promptState = promptState
    }

    
    /// Determine if "maybe later option"should be displayed
    /// - Parameters:
    ///   - asset: WKAsset displayed
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    /// - Returns: Bool
    public func showShowMaybeLaterOption(asset: WKFundraisingCampaignConfig.WKAsset, currentDate: Date) -> Bool {

        let calendar = Calendar.current
        let endDateComponents = calendar.dateComponents([.year, .month, .day], from: asset.endDate)
        let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)

        return !(endDateComponents == currentDateComponents)
    }

    /// Set asset as permanently hidden in persistence, so that it cannot be loaded and displayed on subsequent attempts.
    /// - Parameter asset: WKAsset to mark as hidden
    public func markAssetAsPermanentlyHidden(asset: WKFundraisingCampaignConfig.WKAsset) {
        let promptState = WKFundraisingCampaignPromptState(campaignID: asset.id, isHidden: true, maybeLaterDate: nil)
        try? sharedCacheStore?.save(key: cacheDirectoryName, cachePromptStateFileName, value: promptState)
        self.promptState = promptState
    }
    
    /// Load actively running campaign text. This method automatically filters out campaigns that:
    ///     1. Have start or end dates that do not contain the current date param
    ///     2. That were flagged as permanently hidden or "maybe later" and "maybe later" date has not come to pass
    ///     3. That do not have a country code that matches the country code param
    ///     4. That do not have translation text for the associated wiki param (wkProject).
    ///
    /// - Parameters:
    ///   - countryCode: Country code of the user. Can use Locale.current.regionCode
    ///   - wkProject: wkProject to pull translated campaign text against. Send in the article view project if displaying campaign text on article.
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    /// - Returns: WKAsset containing information to display in campaign modal.
    public func loadActiveCampaignAsset(countryCode: String, wkProject: WKProject, currentDate: Date) -> WKFundraisingCampaignConfig.WKAsset? {
        
        guard activeCountryConfigs.isEmpty else {
            
            // re-filter activeCountryConfigs in case campaigns have ended
            self.activeCountryConfigs = activeCountryConfigs(from: activeCountryConfigs, currentDate: currentDate)
            
            return queuedActiveLanguageSpecificAsset(languageCode: wkProject.languageCode, languageVariantCode: wkProject.languageVariantCode, currentDate: currentDate)
        }
        
        // Load old response from cache and return first asset with matching country code, valid date, and matching language assets.
        let cachedResult: WKFundraisingCampaignConfigResponse? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheConfigFileName)
        
        if let cachedResult {
            activeCountryConfigs = activeCountryConfigs(from: cachedResult, countryCode: countryCode, currentDate: currentDate)

            return queuedActiveLanguageSpecificAsset(languageCode: wkProject.languageCode, languageVariantCode: wkProject.languageVariantCode, currentDate: currentDate)
        }
        
        return nil
    }
    
    @objc public func fetchConfig(countryCode: String, currentDate: Date) {
        fetchConfig(countryCode: countryCode, currentDate: currentDate) { result in
            
        }
    }

    /// Fetches the apps campaign configuration data at https://donate.wikimedia.org/w/index.php?title=MediaWiki:AppsCampaignConfig.json and caches the response. Valid assets can be loaded with loadActiveCampaignAsset
    /// - Parameters:
    ///   - countryCode: Country code of the user. Can use Locale.current.regionCode
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    ///   - completion: Completion handler indicating if the fetch was successful or not.
    public func fetchConfig(countryCode: String, currentDate: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let service else {
            completion(.failure(WKDataControllerError.basicServiceUnavailable))
            return
        }
        
        guard let url = URL.fundraisingCampaignConfigURL() else {
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let parameters: [String: Any] = [
            "action": "raw"
        ]
        
        let request = WKBasicServiceRequest(url: url, method: .GET, parameters: parameters, acceptType: .json)
        service.performDecodableGET(request: request) { [weak self] (result: Result<WKFundraisingCampaignConfigResponse, Error>) in
            
            guard let self else {
                return
            }

            switch result {
            case .success(let response):
                activeCountryConfigs = self.activeCountryConfigs(from: response, countryCode: countryCode, currentDate: currentDate)

                try? sharedCacheStore?.save(key: cacheDirectoryName, cacheConfigFileName, value: response)
                
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchMediaWikiBannerOptIn(project: WKProject, completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let mediaWikiService else {
            completion?(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion?(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let parameters: [String: Any] = [
            "action": "query",
            "meta": "userinfo",
            "uiprop": "options",
            "format": "json"
        ]
        
        let request = WKMediaWikiServiceRequest(url:url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        let completion: (Result<[String: Any]?, Error>) -> Void = { result in
            switch result {
            case .success(let dict):
                
                if let query = dict?["query"] as? [String: Any],
                   let userInfo = query["userinfo"] as? [String: Any],
                   let options = userInfo["options"] as? [String: Any] {
                    
                    if options.keys.contains("centralnotice-display-campaign-type-fundraising") {
                        
                        if let responseOptInFlag = (options["centralnotice-display-campaign-type-fundraising"] as? Bool) {
                            
                            Task {
                                await self.preferencesBannerOptIns.update(value:responseOptInFlag, forKey:project)
                                
                            }
                        } else {
                            Task {
                                await self.preferencesBannerOptIns.update(value:false, forKey:project)
                                
                            }
                        }
                    }
                    
                }
                
                completion?(.success(()))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
        
        mediaWikiService.perform(request: request, completion: completion)
    }
    
    // MARK: - Internal
    
    func reset() {
        activeCountryConfigs = []
        promptState = nil
    }
    
    // MARK: - Private
    
    private func queuedActiveLanguageSpecificAsset(languageCode: String?, languageVariantCode: String?, currentDate: Date) -> WKFundraisingCampaignConfig.WKAsset? {
        
        guard let asset = activeLanguageSpecificAsset(languageCode: languageCode, languageVariantCode: languageVariantCode) else {
            return nil
        }
        
        let validateAsset: ((WKFundraisingCampaignConfig.WKAsset, WKFundraisingCampaignPromptState) -> WKFundraisingCampaignConfig.WKAsset?) = { asset, promptState in
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
        } else if let promptState: WKFundraisingCampaignPromptState = try? sharedCacheStore?.load(key: cacheDirectoryName, cachePromptStateFileName) {
            return validateAsset(asset, promptState)
        } else {
            return asset
        }
    }
    
    private func activeLanguageSpecificAsset(languageCode: String?, languageVariantCode: String?) -> WKFundraisingCampaignConfig.WKAsset? {
        
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
    
    private func activeCountryConfigs(from currentConfigs: [WKFundraisingCampaignConfig], currentDate: Date) -> [WKFundraisingCampaignConfig] {
        
        var configs: [WKFundraisingCampaignConfig] = []
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
    
    private func activeCountryConfigs(from response: WKFundraisingCampaignConfigResponse, countryCode: String, currentDate: Date) -> [WKFundraisingCampaignConfig] {
        
        var configs: [WKFundraisingCampaignConfig] = []
        
        response.configs.forEach({ config in
            
            guard config.countryCodes.contains(countryCode) else {
                return
            }
            
            let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
            guard let startDate = dateFormatter.date(from: config.startTimeString),
                  let endDate = dateFormatter.date(from: config.endTimeString) else {
                return
            }
            
            guard (startDate...endDate).contains(currentDate) else {
                return
            }
            
            var assets: [String: WKFundraisingCampaignConfig.WKAsset] = [:]
            for (key, value) in config.assets {
                
                let actions: [WKFundraisingCampaignConfig.WKAsset.WKAction] = value.actions.map { action in
                    
                    guard let urlString = action.urlString?.replacingOccurrences(of: "$platform;", with: "iOS"),
                       let url = URL(string: urlString) else {
                        return WKFundraisingCampaignConfig.WKAsset.WKAction(title: action.title, url: nil)
                    }
                    
                    return WKFundraisingCampaignConfig.WKAsset.WKAction(title: action.title, url: url)
                }

                let asset = WKFundraisingCampaignConfig.WKAsset(id: config.id, textHtml: value.text, footerHtml: value.footer, actions: actions, countryCode: countryCode, currencyCode: value.currencyCode, startDate: startDate, endDate: endDate, languageCode: key)
                assets[key] = asset
            }
            
            configs.append(WKFundraisingCampaignConfig(id: config.id, assets: assets))
        })
        
        return configs
    }
}

// MARK: - Private Models

private struct WKFundraisingCampaignConfigResponse: Codable {
    
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
            
            let text: String
            let footer: String
            let actions: [Action]
            let currencyCode: String
            
            enum CodingKeys: String, CodingKey {
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
        let assets: [String: Asset]
        
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
    
    static var currentVersion = 1
    let configs: [FundraisingCampaignConfig]
    
    init(from decoder: Decoder) throws {
        
        // Custom decoding to ignore invalid versions
        
        var versionContainer = try decoder.unkeyedContainer()
        var campaignContainer = try decoder.unkeyedContainer()
        
        var validVersionConfigs: [FundraisingCampaignConfig] = []
        while !versionContainer.isAtEnd {
            
            let wkVersion: WKConfigVersion
            let config: FundraisingCampaignConfig
            do {
                wkVersion = try versionContainer.decode(WKConfigVersion.self)
            } catch {
                // Skip
                _ = try? versionContainer.decode(DiscardedElement.self)
                _ = try? campaignContainer.decode(DiscardedElement.self)
                continue
            }
            
            guard wkVersion.version == Self.currentVersion else {
                _ = try? campaignContainer.decode(DiscardedElement.self)
                continue
            }
                
            do {
                config = try campaignContainer.decode(FundraisingCampaignConfig.self)
            } catch {
                // Skip
                _ = try? campaignContainer.decode(DiscardedElement.self)
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
    
    struct DiscardedElement: Codable {}
}

private struct WKFundraisingCampaignPromptState: Codable {
    let campaignID: String
    let isHidden: Bool
    let maybeLaterDate: Date?
}
