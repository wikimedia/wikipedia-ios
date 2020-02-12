
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
}
