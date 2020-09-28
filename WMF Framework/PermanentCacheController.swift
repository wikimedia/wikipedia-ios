import Foundation

@objc(WMFPermanentCacheController)
public final class PermanentCacheController: NSObject {

    public let imageCache: ImageCacheController
    public let articleCache: ArticleCacheController
    let urlCache: PermanentlyPersistableURLCache
    let contextProvider: ManagedObjectContextProviding
    
    /// - Parameter session: the session to utilize for image and article requests
    /// - Parameter configuration: the configuration to utilize for configuring requests
    /// - Parameter preferredLanguageDelegate: the preferredLanguageDelegate to utilize for determining the user's preferred languages
    @objc public init(session: Session, configuration: Configuration, preferredLanguageDelegate: WMFPreferredLanguageCodesProviding, cacheContextProvider: ManagedObjectContextProviding? = nil, cacheContextProviderDelegate: ManagedObjectContextProvidingDelegate? = nil) {
        contextProvider = cacheContextProvider ?? PermanentCacheManagedObjectContextProvider()
        contextProvider.delegate = cacheContextProviderDelegate
        imageCache = ImageCacheController(contextProvider: contextProvider, session: session, configuration: configuration)
        articleCache = ArticleCacheController(contextProvider: contextProvider, imageCacheController: imageCache, session: session, configuration: configuration, preferredLanguageDelegate: preferredLanguageDelegate)
        urlCache = PermanentlyPersistableURLCache(contextProvider: contextProvider)
        super.init()
        session.permanentCache = self
    }
    
    /// Performs any necessary teardown on CacheController's internal storage
    /// Exists on this @objc PermanentCacheController so it can be accessed from WMFDataStore
    @objc public func teardown(_ completion: @escaping () -> Void) {
        imageCache.cancelAllTasks()
        articleCache.cancelAllTasks()
        contextProvider.perform { moc in
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
        let provider = TestMocProvider(moc: moc)
        return PermanentCacheController(session: dataStore.session, configuration: dataStore.configuration, preferredLanguageDelegate: dataStore.languageLinkController, cacheContextProvider: provider)
    }
    
    class TestMocProvider: NSObject, ManagedObjectContextProviding {
        let moc: NSManagedObjectContext
        weak var delegate: ManagedObjectContextProvidingDelegate?
        init(moc: NSManagedObjectContext) {
            self.moc = moc
        }
        
        func perform(_ block: @escaping (NSManagedObjectContext) -> Void) {
            moc.perform { [weak self] in
                guard let self = self else {
                    return
                }
                block(self.moc)
            }
        }
        
        func performAndWait(_ block: (NSManagedObjectContext) -> Void) {
            moc.performAndWait {
                block(moc)
            }
        }
    }
    #endif
}


