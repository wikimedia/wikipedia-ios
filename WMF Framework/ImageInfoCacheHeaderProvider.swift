
import Foundation

@objc class ImageInfoCacheHeaderProvider: NSObject, CacheHeaderProviding {
    
    internal let cacheKeyGenerator: CacheKeyGenerating.Type = ImageInfoCacheKeyGenerator.self
    
    @objc func requestHeader(urlRequest: URLRequest) -> [String : String] {
        return requestHeaderWithETag(urlRequest: urlRequest, itemType: .imageInfo)
    }
}
