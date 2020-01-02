
import Foundation

public protocol CacheProviding {
    
    func recentCachedURLResponse(for url: URL) -> CachedURLResponse?
    func persistedCachedURLResponse(for url: URL) -> CachedURLResponse?
}

public extension CacheProviding {
    func recentCachedURLResponse(for url: URL) -> CachedURLResponse? {
        let request = URLRequest(url: url)
        let urlCache = URLCache.shared
        return urlCache.cachedResponse(for: request)
    }
}
