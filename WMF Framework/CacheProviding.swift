
import Foundation

public protocol CacheProviding {
    
    func recentCachedURLResponse(for request: URLRequest) -> CachedURLResponse?
    func persistedCachedURLResponse(for request: URLRequest) -> CachedURLResponse?
}

public extension CacheProviding {
    func recentCachedURLResponse(for request: URLRequest) -> CachedURLResponse? {
        let urlCache = URLCache.shared
        return urlCache.cachedResponse(for: request)
    }
}
