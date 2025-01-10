import Foundation

@objc final public class WMFFundraisingCampaignDataController: NSObject {
    
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
    
    var service: WMFService?
    var sharedCacheStore: WMFKeyValueStore?
    var mediaWikiService: WMFService?
    
    private var activeCountryConfigs: [WMFFundraisingCampaignConfig] = []
    private var promptState: WMFFundraisingCampaignPromptState?
    private var preferencesBannerOptIns: SafeDictionary<WMFProject, Bool> = SafeDictionary<WMFProject, Bool>()
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.donorExperience.rawValue
    private let cacheConfigFileName = "AppsCampaignConfig"
    private let cachePromptStateFileName = "WMFFundraisingCampaignPromptState"
    
    // MARK: - Lifecycle
    
    private init(service: WMFService? = WMFDataEnvironment.current.basicService, sharedCacheStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore, mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.service = service
        self.sharedCacheStore = sharedCacheStore
        self.mediaWikiService = mediaWikiService
    }
    
    @objc(sharedInstance)
    public static let shared = WMFFundraisingCampaignDataController()
    
    // MARK: - Public
    
    public func isOptedIn(project: WMFProject) async -> Bool {
        return await preferencesBannerOptIns.getValue(forKey: project) ?? true
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
    public func showShowMaybeLaterOption(asset: WMFFundraisingCampaignConfig.WMFAsset, currentDate: Date) -> Bool {

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
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }
        
        guard let url = URL.fundraisingCampaignConfigURL() else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let parameters: [String: Any] = [
            "action": "raw"
        ]
        
        let request = WMFBasicServiceRequest(url: url, method: .GET, parameters: parameters, acceptType: .json)
        service.performDecodableGET(request: request) { [weak self] (result: Result<WMFFundraisingCampaignConfigResponse, Error>) in
            
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
    
    public func fetchMediaWikiBannerOptIn(project: WMFProject, completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let mediaWikiService else {
            completion?(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion?(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let parameters: [String: Any] = [
            "action": "query",
            "meta": "userinfo",
            "uiprop": "options",
            "format": "json"
        ]
        
        let request = WMFMediaWikiServiceRequest(url:url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
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
            
            var assets: [String: WMFFundraisingCampaignConfig.WMFAsset] = [:]
            for (key, value) in config.assets {
                
                let actions: [WMFFundraisingCampaignConfig.WMFAsset.WMFAction] = value.actions.map { action in
                    
                    guard let urlString = action.urlString?.replacingOccurrences(of: "$platform;", with: "iOS"),
                       let url = URL(string: urlString) else {
                        return WMFFundraisingCampaignConfig.WMFAsset.WMFAction(title: action.title, url: nil)
                    }
                    
                    return WMFFundraisingCampaignConfig.WMFAsset.WMFAction(title: action.title, url: url)
                }

                let asset = WMFFundraisingCampaignConfig.WMFAsset(id: config.id, textHtml: value.text, footerHtml: value.footer, actions: actions, countryCode: countryCode, currencyCode: value.currencyCode, startDate: startDate, endDate: endDate, languageCode: key)
                assets[key] = asset
            }
            
            configs.append(WMFFundraisingCampaignConfig(id: config.id, assets: assets))
        })
        
        return configs
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
