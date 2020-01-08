
import Foundation

public final class ArticleCacheController: CacheController {
    
    public static let shared: ArticleCacheController? = {
        
        let articleFetcher = ArticleFetcher()
        let imageFetcher = ImageFetcher()
        
        guard let cacheBackgroundContext = CacheController.backgroundCacheContext,
        let articleFileWriter = ArticleCacheFileWriter(articleFetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext),
        let imageFileWriter = ImageCacheFileWriter(imageFetcher: imageFetcher, cacheBackgroundContext: cacheBackgroundContext) else {
            return nil
        }
        
        let imageProvider = ImageCacheProvider()
        let imageDBWriter = ImageCacheDBWriter(cacheBackgroundContext: cacheBackgroundContext)
        
        let imageController = ImageCacheController(fetcher: imageFetcher, dbWriter: imageDBWriter, fileWriter: imageFileWriter, provider: imageProvider)
        
        let articleProvider = ArticleCacheProvider(imageController: imageController)
        
        let articleDBWriter = ArticleCacheDBWriter(articleFetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext, imageController: imageController)
        let cacheController = ArticleCacheController(fetcher: articleFetcher, dbWriter: articleDBWriter, fileWriter: articleFileWriter, provider: articleProvider)
        
        articleDBWriter.delegate = cacheController
        articleFileWriter.delegate = cacheController
        
        imageDBWriter.delegate = imageController
        imageFileWriter.delegate = imageController
        
        return cacheController
    }()
    
    public func cacheFromMigration(desktopArticleURL: URL, itemKey: String? = nil, content: String, mimeType: String) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter,
        let articleFileWriter = fileWriter as? ArticleCacheFileWriter else {
            return
        }
        
        articleDBWriter.cacheMobileHtmlFromMigration(desktopArticleURL: desktopArticleURL) { (item) in
            articleFileWriter.migrateCachedContent(content: content, cacheItem: item, mimeType: mimeType) {
                articleDBWriter.migratedCacheItemFile(cacheItem: item) {
                    print("success")
                }
            }
        }
    }
}
