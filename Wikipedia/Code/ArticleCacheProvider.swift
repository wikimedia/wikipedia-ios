
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
        
        var maybePreferredItemKey: CacheController.ItemKey?
        var nonVariantKey: String?
        if let articleDesktopURL = ArticleURLConverter.desktopURL(mobileHTMLURL: url) {
            nonVariantKey = articleDesktopURL.wmf_databaseKey
            maybePreferredItemKey = nonVariantKey?.appendingLanguageVariantIfNecessary(host: articleDesktopURL.host)
        } else if ArticleURLConverter.urlIsMediaList(url: url) {
            nonVariantKey = url.wmf_databaseKey
            maybePreferredItemKey = nonVariantKey?.appendingLanguageVariantIfNecessary(host: url.host)
        } else {
            nonVariantKey = url.wmf_databaseKey
            maybePreferredItemKey = nonVariantKey
        }
        
        guard var preferredItemKey = maybePreferredItemKey else {
            return nil
        }
        
        moc.performAndWait {
            
            if let cacheItem = CacheDBWriterHelper.cacheItem(with: preferredItemKey, in: moc),
                cacheItem.isDownloaded {
                return
            }
            
            guard let nonVariantKey = nonVariantKey else {
                return
            }
            
            //fallback to variant that isDownloaded here, reassign preferredItemKey
            let allVariantItems = CacheDBWriterHelper.allDownloadedVariantItems(variantGroupKey: nonVariantKey, in: moc)
            
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
        
        var itemKey: CacheController.ItemKey?
        if let articleDesktopURL = ArticleURLConverter.desktopURL(mobileHTMLURL: newURL) {
            itemKey = articleDesktopURL.wmf_databaseKey?.appendingLanguageVariantIfNecessary(host: articleDesktopURL.host)
        } else if ArticleURLConverter.urlIsMediaList(url: newURL) {
            itemKey = newURL.wmf_databaseKey?.appendingLanguageVariantIfNecessary(host: newURL.host)
        } else {
            itemKey = newURL.wmf_databaseKey
        }
        
        if let itemKey = itemKey {
            return CacheProviderHelper.newCachePolicyRequest(from: originalRequest, newURL: newURL, itemKey: itemKey, moc: moc)
        }
        
        return nil
    }
    
    private func isMimeTypeImage(type: String) -> Bool {
        return type.hasPrefix("image")
    }
}
