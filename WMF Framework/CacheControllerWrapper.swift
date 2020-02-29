
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
            
            cacheController = ImageCacheController.shared
        case .article:
            assertionFailure("Must init from initArticleCacheWithImageCacheControllerWrapper for this type.")
            return nil
        }
    }
    
    @objc init?(articleCacheWithImageCacheControllerWrapper imageCacheWrapper: CacheControllerWrapper) {
        
        super.init()
        cacheController = ArticleCacheController.shared
    }
}
