import Foundation

public struct WMFDonateConfigResponse: Codable {
    
    static var currentVersion = 1
    var config: WMFDonateConfig
    
    public init(from decoder: Decoder) throws {
        
        // Custom decoding to ignore invalid versions
        
        var versionContainer = try decoder.unkeyedContainer()
        var donateContainer = try decoder.unkeyedContainer()
        
        var validConfigs: [WMFDonateConfig] = []
        while !versionContainer.isAtEnd {
            
            let wmfVersion: WMFConfigVersion
            let config: WMFDonateConfig
            do {
                wmfVersion = try versionContainer.decode(WMFConfigVersion.self)
            } catch {
                // Skip
                _ = try? versionContainer.decode(DiscardedElement.self)
                _ = try? donateContainer.decode(DiscardedElement.self)
                continue
            }
            
            guard wmfVersion.version == Self.currentVersion else {
                _ = try? donateContainer.decode(DiscardedElement.self)
                continue
            }
                
            do {
                config = try donateContainer.decode(WMFDonateConfig.self)
            } catch {
                // Skip
                _ = try? donateContainer.decode(DiscardedElement.self)
                continue
            }
            
            validConfigs.append(config)
        }
        
        guard let firstValidConfig = validConfigs.first else {
            throw WMFServiceError.invalidResponseVersion
        }
        
        self.config = firstValidConfig
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: [config])
    }
    
    struct DiscardedElement: Codable {}
}
