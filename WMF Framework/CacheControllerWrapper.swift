
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
                let imageFileWriter = ImageCacheFileWriter(imageFetcher: imageFetcher, cacheBackgroundContext: cacheBackgroundContext) else {
                    return
            }

            let imageProvider = ImageCacheProvider(moc: cacheBackgroundContext)

            let imageDBWriter = ImageCacheDBWriter(imageFetcher: imageFetcher, cacheBackgroundContext: cacheBackgroundContext)

            self.cacheController = ImageCacheController(fetcher: imageFetcher, dbWriter: imageDBWriter, fileWriter: imageFileWriter, provider: imageProvider)
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
            let articleFileWriter = ArticleCacheFileWriter(articleFetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext) else {
            return nil
        }
        
        let articleProvider = ArticleCacheProvider(imageController: imageCacheController, moc: cacheBackgroundContext)
        
        let articleDBWriter = ArticleCacheDBWriter(articleFetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext, imageController: imageCacheController)
        
        self.cacheController = ArticleCacheController(fetcher: articleFetcher, dbWriter: articleDBWriter, fileWriter: articleFileWriter, provider: articleProvider)
        
        super.init()
    }
}
