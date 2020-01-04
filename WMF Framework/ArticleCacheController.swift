
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
    
    public func cacheMobileHtmlUrlFromMigration(articleURL: URL) {
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            return
        }
        
        articleDBWriter.cacheMobileHtmlUrlFromMigration(articleURL: articleURL)
    }
}
