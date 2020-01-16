import Foundation

final class SchemeHandlerCache {
    static private let cachedResponseCountLimit = UInt(6)
    let responseCache = WMFFIFOCache<NSString, CachedURLResponse>(countLimit: SchemeHandlerCache.cachedResponseCountLimit)
}

extension SchemeHandlerCache: FileHandlerCacheDelegate {
    func cachedResponse(for path: String) -> CachedURLResponse? {
        return responseCache.object(forKey: (path as NSString))
    }
    
    func cacheResponse(_ response: URLResponse, data: Data?, path: String) {
        guard let data = data else {
            return
        }
        
        let cachedResponse = CachedURLResponse(response: response, data: data)
        responseCache.setObject(cachedResponse, forKey: path as NSString)
    }
}
