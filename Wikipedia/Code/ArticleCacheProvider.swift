
import Foundation

final class ArticleCacheProvider: CacheProviding {
    
    private let imageController: ImageCacheController
    private let moc: NSManagedObjectContext
    
    init(imageController: ImageCacheController, moc: NSManagedObjectContext) {
        self.imageController = imageController
        self.moc = moc
    }
    
    //fetches from URLCache.shared, fallback PersistentCacheItem (or forwards to ImageCacheProvider if image type)
    func cachedURLResponse(for request: URLRequest) -> CachedURLResponse? {
        
        guard let url = request.url else {
            return nil
        }
        
        if isMimeTypeImage(type: (url as NSURL).wmf_mimeTypeForExtension()) {
            return imageController.cachedURLResponse(for: request)
        }
        
        let urlCache = URLCache.shared
        
        if let response = urlCache.cachedResponse(for: request) {
            return response
        }
        
        // Use the cache key to check for the response
        guard let itemKey = request.value(forHTTPHeaderField: Session.Header.persistentCacheKey) else {
            return nil
        }
        
        return CacheProviderHelper.persistedCacheResponse(url: url, itemKey: itemKey)
    }
    
    func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL) -> URLRequest? {
        
        if isMimeTypeImage(type: (newURL as NSURL).wmf_mimeTypeForExtension()) {
            return imageController.newCachePolicyRequest(from: originalRequest, newURL: newURL)
        }
        
        let itemKey = originalRequest.value(forHTTPHeaderField: Session.Header.persistentCacheKey) ?? newURL.wmf_databaseKey
        return CacheProviderHelper.newCachePolicyRequest(from: originalRequest, newURL: newURL, itemKey: itemKey, moc: moc)
    }
    
    private func isMimeTypeImage(type: String) -> Bool {
        return type.hasPrefix("image")
    }
}
