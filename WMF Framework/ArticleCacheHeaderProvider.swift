
import Foundation

public class ArticleCacheHeaderProvider: CacheHeaderProviding {
    
    public let cacheKeyGenerator: CacheKeyGenerating.Type = ArticleCacheKeyGenerator.self
    
    public init() {
        
    }
    
    public func requestHeader(urlRequest: URLRequest) -> [String : String] {
        return requestHeaderWithETag(urlRequest: urlRequest)
    }
}
