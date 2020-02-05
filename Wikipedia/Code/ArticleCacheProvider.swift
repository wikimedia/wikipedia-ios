
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
        
        //mobile-html endpoint is saved under the desktop url. if it's mobile-html first convert to desktop before pulling the key.
        guard var preferredItemKey = ArticleURLConverter.desktopURL(mobileHTMLURL: url)?.wmf_databaseKey ?? url.wmf_databaseKey else {
            return nil
        }
        
        moc.performAndWait {
            
            if let cacheItem = CacheDBWriterHelper.cacheItem(with: preferredItemKey, in: moc),
                cacheItem.isDownloaded {
                return
            }
            
            //fallback to variant that isDownloaded here, reassign preferredItemKey
            let allVariantItems = CacheDBWriterHelper.allDownloadedVariantItems(for: preferredItemKey, in: moc)
            
            //tonitodo: maybe sort allVariantItems based on NSLocale language preferences (i.e. more than 2)
            
            if let fallbackItemKey = allVariantItems.first?.key {
                preferredItemKey = fallbackItemKey
            }
        }
        
        return CacheProviderHelper.persistedCacheResponse(url: url, itemKey: preferredItemKey)
    }
    
    func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL) -> URLRequest? {
        
        if isMimeTypeImage(type: (newURL as NSURL).wmf_mimeTypeForExtension()) {
            return imageController.newCachePolicyRequest(from: originalRequest, newURL: newURL)
        }
        
        let itemKey = ArticleURLConverter.desktopURL(mobileHTMLURL: newURL)?.wmf_databaseKey?.appendingLanguageVariantIfNecessary(host: newURL.host) ?? newURL.wmf_databaseKey
        return CacheProviderHelper.newCachePolicyRequest(from: originalRequest, newURL: newURL, itemKey: itemKey, moc: moc)
    }
    
    private func isMimeTypeImage(type: String) -> Bool {
        return type.hasPrefix("image")
    }
}
