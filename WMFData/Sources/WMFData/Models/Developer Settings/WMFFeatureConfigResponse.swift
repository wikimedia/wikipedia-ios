import Foundation

struct WMFFeatureConfigResponse: Codable {
    struct FeatureConfigIOS: Codable {
        
        struct Slide: Codable {
            let id: String
            let isEnabled: Bool
        }
        
        let version: Int
        let yirIsEnabled: Bool
        let yirCountryCodes: [String]
        let yirPrimaryAppLanguageCodes: [String]
        let yirDataPopulationStartDateString: String
        let yirDataPopulationEndDateString: String
        let yirDataPopulationFetchMaxPagesPerSession: Int
        let yirPersonalizedSlides: [Slide]
    }
    
    let ios: [FeatureConfigIOS]
    var cachedDate: Date?
    
    private let currentFeatureConfigVersion = 1
    
    public init(from decoder: Decoder) throws {
        
        // Custom decoding to filter out invalid versions
        
        let overallContainer = try decoder.container(keyedBy: CodingKeys.self)
        
        var versionContainer = try overallContainer.nestedUnkeyedContainer(forKey: .ios)
        var iosContainer = try overallContainer.nestedUnkeyedContainer(forKey: .ios)
        
        var validConfigs: [FeatureConfigIOS] = []
        while !versionContainer.isAtEnd {
            
            let wmfVersion: WMFConfigVersion
            let config: FeatureConfigIOS
            do {
                wmfVersion = try versionContainer.decode(WMFConfigVersion.self)
            } catch {
                // Skip
                _ = try? versionContainer.decode(WMFDiscardedElement.self)
                _ = try? iosContainer.decode(WMFDiscardedElement.self)
                continue
            }
            
            guard wmfVersion.version == currentFeatureConfigVersion else {
                // Skip
                _ = try? iosContainer.decode(WMFDiscardedElement.self)
                continue
            }
                
            do {
                config = try iosContainer.decode(FeatureConfigIOS.self)
            } catch {
                // Skip
                _ = try? iosContainer.decode(WMFDiscardedElement.self)
                continue
            }
            
            validConfigs.append(config)
        }
        
        self.ios = validConfigs
    }
}
