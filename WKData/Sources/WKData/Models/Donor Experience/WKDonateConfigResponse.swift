import Foundation

public struct WKDonateConfigResponse: Codable {
    
    static var currentVersion = 1
    var config: WKDonateConfig
    
    public init(from decoder: Decoder) throws {
        
        // Custom decoding to ignore invalid versions
        
        var versionContainer = try decoder.unkeyedContainer()
        var donateContainer = try decoder.unkeyedContainer()
        
        var validConfigs: [WKDonateConfig] = []
        while !versionContainer.isAtEnd {
            
            let wkVersion: WKConfigVersion
            let config: WKDonateConfig
            do {
                wkVersion = try versionContainer.decode(WKConfigVersion.self)
            } catch {
                // Skip
                _ = try? versionContainer.decode(DiscardedElement.self)
                _ = try? donateContainer.decode(DiscardedElement.self)
                continue
            }
            
            guard wkVersion.version == Self.currentVersion else {
                _ = try? donateContainer.decode(DiscardedElement.self)
                continue
            }
                
            do {
                config = try donateContainer.decode(WKDonateConfig.self)
            } catch {
                // Skip
                _ = try? donateContainer.decode(DiscardedElement.self)
                continue
            }
            
            validConfigs.append(config)
        }
        
        guard let firstValidConfig = validConfigs.first else {
            throw WKServiceError.invalidResponseVersion
        }
        
        self.config = firstValidConfig
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: [config])
    }
    
    struct DiscardedElement: Codable {}
}
