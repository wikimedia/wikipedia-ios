import Foundation

@objc(WMFPermanentCacheController)
public final class PermanentCacheController: NSObject {
    public let imageCache: ImageCacheController
    public let articleCache: ArticleCacheController
    let urlCache: PermanentlyPersistableURLCache
    let managedObjectContext: NSManagedObjectContext
    
    /// - Parameter moc: the managed object context for the cache
    /// - Parameter session: the session to utilize for image and article requests
    /// - Parameter configuration: the configuration to utilize for configuring requests
    /// - Parameter preferredLanguageDelegate: the preferredLanguageDelegate to utilize for determining the user's preferred languages
    @objc public init(moc: NSManagedObjectContext, session: Session, configuration: Configuration, preferredLanguageDelegate: WMFPreferredLanguageCodesProviding) {
        imageCache = ImageCacheController(moc: moc, session: session, configuration: configuration)
        articleCache = ArticleCacheController(moc: moc, imageCacheController: imageCache, session: session, configuration: configuration, preferredLanguageDelegate: preferredLanguageDelegate)
        urlCache = PermanentlyPersistableURLCache(moc: moc)
        managedObjectContext = moc
        super.init()
        session.permanentCache = self
    }
    
    /// Performs any necessary migrations on the CacheController's internal storage
    /// Exists on this @objc PermanentCacheController so it can be accessed from WMFDataStore
    @objc public static func setupCoreDataStack(_ completion: @escaping (NSManagedObjectContext?, Error?) -> Void) {
        CacheController.setupCoreDataStack(completion)
    }
    
    /// Performs any necessary teardown on CacheController's internal storage
    /// Exists on this @objc PermanentCacheController so it can be accessed from WMFDataStore
    @objc public func teardown(_ completion: @escaping () -> Void) {
        imageCache.cancelAllTasks()
        articleCache.cancelAllTasks()
        managedObjectContext.perform {
            // Give a bit of a buffer for other async activity to cease
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: completion)
        }
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
    
    @objc public func cancelImageFetch(withURL url: URL?, token: String?) {
        imageCache.cancelFetch(withURL: url, token: token)
    }
    
    @objc public func cachedImage(withURL url: URL?) -> Image? {
        return imageCache.cachedImage(withURL: url)
    }
    
    @objc public func fetchData(withURL url: URL, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) {
        imageCache.fetchData(withURL: url, failure: failure, success: success)
    }
    
    @objc public func imageData(withURL url: URL) -> TypedImageData? {
        return imageCache.data(withURL: url)
    }
    #if TEST
    @objc public static func testController(with directory: URL, dataStore: MWKDataStore) -> PermanentCacheController {
        let moc = CacheController.createCacheContext(cacheURL: directory)!
        return PermanentCacheController(moc: moc, session: dataStore.session, configuration: dataStore.configuration, preferredLanguageDelegate: dataStore.languageLinkController)
    }
    #endif
}
