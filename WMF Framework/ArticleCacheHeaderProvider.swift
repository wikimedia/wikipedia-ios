
import Foundation

public class ArticleCacheHeaderProvider: NSObject, CacheHeaderProviding {
    
    private let cacheKeyGenerator: CacheKeyGenerating.Type = ArticleCacheKeyGenerator.self
    
    public override init() {
        
    }
    
    public func requestHeader(urlRequest: URLRequest) -> [String: String] {
        
        var header: [String: String] = [:]
        
        guard let url = urlRequest.url,
            let itemKey = cacheKeyGenerator.itemKeyForURL(url) else {
            return header
        }
        
        let variant = cacheKeyGenerator.variantForURL(url)
        
        header[Session.Header.persistentCacheItemKey] = itemKey
        
        if let variant = variant {
            header[Session.Header.persistentCacheItemVariant] = variant
        }
        
        //pull response header from cache
        let urlCache = URLCache.shared
        var cachedUrlResponse: HTTPURLResponse?
        
        if let response = urlCache.cachedResponse(for: urlRequest)?.response as? HTTPURLResponse {
            cachedUrlResponse = response
        } else {
            cachedUrlResponse = CacheProviderHelper.persistedCacheResponse(url: url, itemKey: itemKey, variant: variant, cacheKeyGenerator: cacheKeyGenerator)?.response as? HTTPURLResponse
        }
        
        //convert cached url response headers to applicable request headers.
        
        //tonitodo: Accept-Language?
        if let cachedUrlResponse = cachedUrlResponse {
            
            for (key, value) in cachedUrlResponse.allHeaderFields {
                if let keyString = key as? String,
                    keyString == HTTPURLResponse.etagHeaderKey {
                    header[HTTPURLResponse.ifNoneMatchHeaderKey] = value as? String
                    header[Session.Header.persistentCacheETag] = value as? String //fallback bucket, .ifNoneMatchHeaderKey seems to get reassigned through SchemeHandler
                }
                //tonitodo: might need to restore some of this later for variant corruption, but commenting for now. this caused urlSession errors in one of the resources requests.
//                } else if let keyString = key as? String,
//                    let valueString = value as? String {
//                    header[keyString] = valueString
//                }
            }
        }
        
        header[Session.Header.persistentCacheItemType] = Session.Header.ItemType.article.rawValue
        
        return header
        
    }
    
}
