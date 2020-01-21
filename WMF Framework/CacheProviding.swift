
import Foundation

public protocol CacheProviding {
    
    func cachedURLResponse(for request: URLRequest) -> CachedURLResponse?
    func cachedURLResponseUponError(for request: URLRequest) -> CachedURLResponse?
    func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL, cachePolicy: NSURLRequest.CachePolicy) -> URLRequest?
}
