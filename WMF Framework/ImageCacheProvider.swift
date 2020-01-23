
import Foundation

final class ImageCacheProvider: CacheProviding {
    
    private let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    func cachedURLResponse(for request: URLRequest) -> CachedURLResponse? {
    
        let urlCache = URLCache.shared
        if let response =  urlCache.cachedResponse(for: request) {
            return response
        }
        
        guard let url = request.url,
            let itemKey = url.wmf_databaseKey else {
            return nil
        }
        
        return CacheProviderHelper.persistedCacheResponse(url: url, itemKey: itemKey)
    }
    
    func cachedURLResponseUponError(for request: URLRequest) -> CachedURLResponse? {

        guard let url = request.url,
            let itemKey = url.wmf_databaseKey else {
            return nil
        }
        
        return CacheProviderHelper.persistedCacheResponse(url: url, itemKey: itemKey)
    }
    
    func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL) -> URLRequest? {
        
        let itemKey = newURL.wmf_databaseKey
            
        return CacheProviderHelper.newCachePolicyRequest(from: originalRequest, newURL: newURL, itemKey: itemKey, moc: moc)
    }
}
