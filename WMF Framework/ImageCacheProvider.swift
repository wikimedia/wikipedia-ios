
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
        
        
        guard let url = request.url else {
            return nil
        }
        
        var preferredItemKey = ImageCacheDBWriter.identifierForURL(url)
        
        moc.performAndWait {
            
            if let cacheItem = CacheDBWriterHelper.cacheItem(with: preferredItemKey, in: moc),
                cacheItem.isDownloaded {
                return
            }
            
            //fallback to variant that isDownloaded here, reassign preferredItemKey
            var allVariantItems = CacheDBWriterHelper.allDownloadedVariantItems(itemKey: preferredItemKey, in: moc)
            
            allVariantItems.sort { (lhs, rhs) -> Bool in
                
                guard let lhsVariant = lhs.variant,
                    let lhsSize = Int64(lhsVariant),
                    let rhsVariant = rhs.variant,
                    let rhsSize = Int64(rhsVariant) else {
                        return true
                }
                
                return lhsSize < rhsSize
            }
            
            if let fallbackItemKey = allVariantItems.first?.key {
                preferredItemKey = fallbackItemKey
            }
        }
        
        return CacheProviderHelper.persistedCacheResponse(url: url, itemKey: preferredItemKey)
    }
    
    func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL) -> URLRequest? {
        
        let itemKey = ImageCacheDBWriter.identifierForURL(newURL)
            
        return CacheProviderHelper.newCachePolicyRequest(from: originalRequest, newURL: newURL, itemKey: itemKey, moc: moc)
    }
}
