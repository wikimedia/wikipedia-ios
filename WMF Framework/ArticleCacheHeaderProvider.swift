
import Foundation

class ArticleCacheHeaderProvider: CacheHeaderProviding {
    
    private let cacheKeyGenerator: CacheKeyGenerating.Type = ArticleCacheKeyGenerator.self
    
    func requestHeader(urlRequest: URLRequest) -> [String: String] {
        
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
            
            let responseFileName = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant)
            let responseHeaderFileName = cacheKeyGenerator.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
            cachedUrlResponse = CacheProviderHelper.persistedCacheResponse(url: url, responseFileName: responseFileName, responseHeaderFileName: responseHeaderFileName)?.response as? HTTPURLResponse
        }
        
        //convert cached url response headers to applicable request headers.
        
        //tonitodo: Accept-Language?
        if let cachedUrlResponse = cachedUrlResponse {
            
            for (key, value) in cachedUrlResponse.allHeaderFields {
                if let keyString = key as? String,
                    keyString == HTTPURLResponse.etagHeaderKey {
                    header[HTTPURLResponse.ifNoneMatchHeaderKey] = value as? String
                } else if let keyString = key as? String,
                    let valueString = value as? String {
                    header[keyString] = valueString
                }
            }
        }
        
        return header
        
    }
    
}
