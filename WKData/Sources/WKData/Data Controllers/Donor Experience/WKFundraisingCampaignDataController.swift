import Foundation

final public class WKFundraisingCampaignDataController {
    
    // MARK: - Properties
    
    private let service = WKDataEnvironment.current.basicService
    private let sharedCacheStore = WKDataEnvironment.current.sharedCacheStore
    private var activeCountryConfigs: [WKFundraisingCampaignConfig] = []
    
    private let cacheDirectoryName = WKSharedCacheDirectoryNames.donorExperience.rawValue
    private let cacheConfigFileName = "AppsCampaignConfig"
    private let cachePromptStateFileName = "WKFundraisingCampaignPromptState"
    
    private static let temporaryTargetCampaignID = "NL_2023_11"
    
    // MARK: - Lifecycle
    
    public init() {
        
    }
    
    // MARK: - Public
    
    /// Set asset as "maybe later" in persistence, so that it can me loaded later only once the maybe later date has passed
    /// - Parameters:
    ///   - asset: WKAsset to mark as maybe later
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    public func markAssetAsMaybeLater(asset: WKFundraisingCampaignConfig.WKAsset, currentDate: Date) {
        let maybeLaterDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)
        let promptState = WKFundraisingCampaignPromptState(campaignID: asset.id, isHidden: false, maybeLaterDate: maybeLaterDate)
        try? sharedCacheStore?.save(key: cacheDirectoryName, cachePromptStateFileName, value: promptState)
    }
    
    
    /// Set asset as permanently hidden in persistence, so that it cannot be loaded and displayed on subsequent attempts.
    /// - Parameter asset: WKAsset to mark as hidden
    public func markAssetAsPermanentlyHidden(asset: WKFundraisingCampaignConfig.WKAsset) {
        let promptState = WKFundraisingCampaignPromptState(campaignID: asset.id, isHidden: true, maybeLaterDate: nil)
        try? sharedCacheStore?.save(key: cacheDirectoryName, cachePromptStateFileName, value: promptState)
    }
    
    /// Flag to indicate that there is an actively running campaign in the user's country for the current date.
    /// - Parameters:
    ///   - countryCode: Country code of the user. Can use Locale.current.regionCode
    ///   - currentDate: Current date, sent in as a parameter for stable unit testing.
    /// - Returns: Boolean to indicate if there's an actively running campaign or not
    public func hasActivelyRunningCampaigns(countryCode: String, currentDate: Date) -> Bool {
        
        let containsActiveCampaignWithTargetID: ([WKFundraisingCampaignConfig]) -> Bool = { configs in
            let containsTargetCampaignID = configs.contains { $0.id == Self.temporaryTargetCampaignID }
            return containsTargetCampaignID
        }
        
        guard activeCountryConfigs.isEmpty else {
            // TODO: When Oct 2023 NL campaign looks good, replace this closure with simply:
            // return !activeCountryConfigs.isEmpty
            return containsActiveCampaignWithTargetID(activeCountryConfigs)
        }
        
        // Load old response from cache and return first asset with matching country code, valid date, and matching language assets.
        let cachedResult: WKFundraisingCampaignConfigResponse? = try? sharedCacheStore?.load(key: cacheDirectoryName, cacheConfigFileName)
        
        if let cachedResult {
            activeCountryConfigs = activeCountryConfigs(from: cachedResult, countryCode: countryCode, currentDate: currentDate)
        }
        
        // TODO: When Oct 2023 NL campaign looks good, replace this closure with simply:
        // return !activeCountryConfigs.isEmpty
        return containsActiveCampaignWithTargetID(activeCountryConfigs)
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
        
        let request = WKBasicServiceRequest(url: url, method: .GET, parameters: parameters)
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
    
    // MARK: - Private
    
    private func queuedActiveLanguageSpecificAsset(languageCode: String?, languageVariantCode: String?, currentDate: Date) -> WKFundraisingCampaignConfig.WKAsset? {
        
        guard let asset = activeLanguageSpecificAsset(languageCode: languageCode, languageVariantCode: languageVariantCode) else {
            return nil
        }
                
        if let promptState: WKFundraisingCampaignPromptState = try? sharedCacheStore?.load(key: cacheDirectoryName, cachePromptStateFileName) {
            
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
        
        return asset
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
                    
                    guard let urlString = action.urlString?.decodingUnicodeCharacters.replacingOccurrences(of: "$platform;", with: "iOS"),
                       let url = URL(string: urlString) else {
                        return WKFundraisingCampaignConfig.WKAsset.WKAction(title: action.title, url: nil)
                    }
                    
                    return WKFundraisingCampaignConfig.WKAsset.WKAction(title: action.title, url: url)
                }
                
                let asset = WKFundraisingCampaignConfig.WKAsset(id: config.id, textHtml: value.text.decodingUnicodeCharacters, footerHtml: value.footer.decodingUnicodeCharacters, actions: actions, currencyCode: value.currencyCode)
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
    
    struct DiscardedElement: Codable {}
}

private struct WKFundraisingCampaignPromptState: Codable {
    let campaignID: String
    let isHidden: Bool
    let maybeLaterDate: Date?
}

// MARK: - Extensions

private extension String {
    var decodingUnicodeCharacters: String { applyingTransform(.init("Hex-Any"), reverse: false) ?? "" }
}
