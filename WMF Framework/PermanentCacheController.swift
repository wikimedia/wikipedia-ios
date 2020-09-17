import Foundation

@objc(WMFPermanentCacheController)
public final class PermanentCacheController: NSObject {
    public let imageCache: ImageCacheController
    public let articleCache: ArticleCacheController
    let urlCache: PermanentlyPersistableURLCache
    let managedObjectContext: NSManagedObjectContext
    
    /// - Parameter moc: the managed object context for the cache
    /// - Parameter dataStore: the data store for the cache - weakly referenced
    @objc public init(moc: NSManagedObjectContext, dataStore: MWKDataStore) {
        imageCache = ImageCacheController(moc: moc, session: dataStore.session, configuration: dataStore.configuration)
        articleCache = ArticleCacheController(moc: moc, imageCacheController: imageCache, dataStore: dataStore)
        urlCache = PermanentlyPersistableURLCache(moc: moc)
        managedObjectContext = moc
        super.init()
        dataStore.session.permanentCache = self
    }
    
    /// Performs any necessary migrations on the CacheController's internal storage
    /// Exists on this @objc ImageCacheControllerWrapper so it can be accessed from WMFDataStore
    @objc public static func setupCoreDataStack(_ completion: @escaping (NSManagedObjectContext?, Error?) -> Void) {
        CacheController.setupCoreDataStack(completion)
    }
    
    @objc public func fetchImage(withURL url: URL?, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) {
        let _ = imageCache.fetchImage(withURL: url, failure: failure, success: success)
    }
    
    @objc public func memoryCachedImage(withURL url: URL) -> Image? {
        return imageCache.memoryCachedImage(withURL: url)
    }
    
    @objc public func fetchImage(withURL url: URL?, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) -> String? {
        return imageCache.fetchImage(withURL: url, priority: priority, failure: failure, success: success)
    }
    
    @objc public func cancelFetch(withURL url: URL?, token: String?) {
        imageCache.cancelFetch(withURL: url, token: token)
    }
    
    @objc public func cachedImage(withURL url: URL?) -> Image? {
        return imageCache.cachedImage(withURL: url)
    }
    
    @objc public func fetchData(withURL url: URL, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) {
        imageCache.fetchData(withURL: url, failure: failure, success: success)
    }
    
    @objc public func data(withURL url: URL) -> TypedImageData? {
        return imageCache.data(withURL: url)
    }
    #if TEST
    @objc public static func testController(with directory: URL, session: Session, configuration: Configuration) -> PermanentCacheController {
        let moc = CacheController.createCacheContext(cacheURL: directory)!
        return PermanentCacheController(moc: moc, session: session, configuration: configuration)
    }
    #endif
}
