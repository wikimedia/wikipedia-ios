import Foundation

public struct WMFFeatureConfigResponse: Codable {
    public struct FeatureConfigIOS: Codable {
        
        public struct Slide: Codable {
            public let id: String
            public let isEnabled: Bool
        }
        
        let version: Int
        public let yirIsEnabled: Bool
        public let yirCountryCodes: [String]
        public let yirPrimaryAppLanguageCodes: [String]
        public let yirDataPopulationStartDateString: String
        public let yirDataPopulationEndDateString: String
        public let yirDataPopulationFetchMaxPagesPerSession: Int
        public let yirPersonalizedSlides: [Slide]
    }
    
    public let ios: [FeatureConfigIOS]
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
        self.cachedDate = try? overallContainer.decode(Date.self, forKey: .cachedDate)
    }
}
