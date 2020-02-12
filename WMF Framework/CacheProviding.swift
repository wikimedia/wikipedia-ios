
import Foundation

public protocol CacheProviding {
    
    func cachedURLResponse(for request: URLRequest) -> CachedURLResponse?
}
