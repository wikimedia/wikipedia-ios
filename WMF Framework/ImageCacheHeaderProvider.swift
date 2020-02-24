
import Foundation

public class ImageCacheHeaderProvider: CacheHeaderProviding {
    
    public let cacheKeyGenerator: CacheKeyGenerating.Type = ImageCacheKeyGenerator.self
    
    public init() {
        
    }
    
    public func requestHeader(urlRequest: URLRequest) -> [String: String] {
        var header: [String: String] = [:]
        
        guard let url = urlRequest.url,
            let itemKey = cacheKeyGenerator.itemKeyForURL(url) else {
            return header
        }
        
        header[Session.Header.persistentCacheItemKey] = itemKey
        
        if let variant = cacheKeyGenerator.variantForURL(url) {
            header[Session.Header.persistentCacheItemVariant] = variant
        }
        
        header[Session.Header.persistentCacheItemType] = Session.Header.ItemType.image.rawValue
        
        return header
    }
}
