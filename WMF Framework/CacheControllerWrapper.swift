
import Foundation

//DEBT: Wrapper class for accessing CacheControllers from MWKDataStore. Remove once MWKDataStore is no longer Objective-C and reference ArticleCacheController and ImageCacheController directly.

@objc(WMFCacheControllerType)
enum CacheControllerType: Int {
    case image
    case article
}

@objc(WMFCacheControllerWrapper)
public final class CacheControllerWrapper: NSObject {
    
    public private(set) var cacheController: CacheController? = nil
    
    @objc override init() {
        assertionFailure("Must init from init(type) or init(articleCacheWithImageCacheControllerWrapper)")
        self.cacheController = nil
        super.init()
    }
    
    @objc init?(type: CacheControllerType) {

        super.init()
        switch type {
        case .image:
            
            let imageFetcher = ImageFetcher()
            
            guard let cacheBackgroundContext = CacheController.backgroundCacheContext,
                let imageFileWriter = CacheFileWriter(fetcher: imageFetcher, cacheBackgroundContext: cacheBackgroundContext, cacheKeyGenerator: ImageCacheKeyGenerator.self) else {
                    return
            }

            let imageDBWriter = ImageCacheDBWriter(imageFetcher: imageFetcher, cacheBackgroundContext: cacheBackgroundContext)

            self.cacheController = ImageCacheController(dbWriter: imageDBWriter, fileWriter: imageFileWriter)
        case .article:
            assertionFailure("Must init from initArticleCacheWithImageCacheControllerWrapper for this type.")
            return nil
        }
    }
    
    @objc init?(articleCacheWithImageCacheControllerWrapper imageCacheWrapper: CacheControllerWrapper) {
        
        guard let imageCacheController = imageCacheWrapper.cacheController as? ImageCacheController else {
            assertionFailure("Expecting imageCacheWrapper.cacheController to be of type ImageCacheController")
            return nil
        }
        
        let articleFetcher = ArticleFetcher()
        
        guard let cacheBackgroundContext = CacheController.backgroundCacheContext,
            let cacheFileWriter = CacheFileWriter(fetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext, cacheKeyGenerator: ArticleCacheKeyGenerator.self) else {
            return nil
        }
        
        let articleDBWriter = ArticleCacheDBWriter(articleFetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext, imageController: imageCacheController)
        
        self.cacheController = ArticleCacheController(dbWriter: articleDBWriter, fileWriter: cacheFileWriter)
        
        super.init()
    }
}
