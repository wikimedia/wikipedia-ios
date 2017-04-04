import Foundation
import CocoaLumberjackSwift

///
/// @name Constants
///


// Warning: Due to issues with `ErrorType` to `NSError` bridging, you must check domains of bridged errors like so: [MyCustomErrorTypeErrorDomain hasSuffix:nsError.domain] because the generated constant in the Swift header (in this case, `WMFImageControllerErrorDomain` in "Wikipedia-Swift.h") doesn't match the actual domain when `ErrorType` is cast to `NSError`.
/**
 WMFImageControllerError

 - DataNotFound:      Failed to find cached image data for the provided URL.
 - InvalidOrEmptyURL: The provided URL was empty or `nil`.
 - Deinit:            Fetch was cancelled because the image controller was deallocated.
 */
@objc(WMFImageControllerError) public enum ImageControllerError: Int, Error {
    case dataNotFound
    case invalidOrEmptyURL
    case invalidImageCache
    case invalidResponse
    case `deinit`
}

@objc(WMFTypedImageData)
open class TypedImageData: NSObject {
    open let data:Data?
    open let MIMEType:String?
    
    public init(data data_: Data?, MIMEType type_: String?) {
        data = data_
        MIMEType = type_
    }
}



let WMFExtendedFileAttributeNameMIMEType = "org.wikimedia.MIMEType"

@objc(WMFImageController)
open class ImageController : NSObject {
    // MARK: - Initialization
    
    @objc(sharedInstance) public static let shared: ImageController = {
        let session = URLSession.shared
        let cache = URLCache.shared
        let fileManager = FileManager.default
        let permanentStorageDirectory = fileManager.wmf_containerURL().appendingPathComponent("Permanent Image Cache", isDirectory: true)
        do {
            try fileManager.createDirectory(at: permanentStorageDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            
        }
        return ImageController(session: session, cache: cache, fileManager: fileManager, permanentStorageDirectory: permanentStorageDirectory)
    }()
    
    var sessionTasks: [String: URLSessionTask] = [:]
    var operations: [String: Operation] = [:]
    
    fileprivate let session: URLSession
    fileprivate let cache: URLCache
    fileprivate let permanentStorageDirectory: URL
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate let persistentStoreCoordinator: NSPersistentStoreCoordinator
    fileprivate let fileManager: FileManager
    
    
    public required init(session: URLSession, cache: URLCache, fileManager: FileManager, permanentStorageDirectory: URL) {
        self.session = session
        self.cache = cache
        self.fileManager = fileManager
        self.permanentStorageDirectory = permanentStorageDirectory
        let bundle = Bundle(identifier: "org.wikimedia.WMF")!
        let modelURL = bundle.url(forResource: "Cache", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        let containerURL = permanentStorageDirectory
        let dbURL = containerURL.appendingPathComponent("Cache.sqlite", isDirectory: false)
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true), NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)]
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
        } catch {
            do {
                try FileManager.default.removeItem(at: dbURL)
            } catch {
                
            }
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
            } catch {
                abort()
            }
        }
        persistentStoreCoordinator = psc
        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        super.init()
    }
    
    
    fileprivate func cacheKeyForURL(_ url: URL) -> String? {
        guard let siteURL = (url as NSURL).wmf_site, let imageName = WMFParseImageNameFromSourceURL(url) else {
            return nil
        }
        return siteURL.absoluteString + "||" + imageName
    }
    
    fileprivate func variantForURL(_ url: URL) -> Int64 { // A return value of 0 indicates the original size
        let sizePrefix = WMFParseSizePrefixFromSourceURL(url)
        return Int64(sizePrefix == NSNotFound ? 0 : sizePrefix)
    }
    
    fileprivate func permanentCacheFileURL(key: String, variant: Int64) -> URL {
        return self.permanentStorageDirectory.appendingPathComponent("\(key)||\(variant)", isDirectory: false)
    }
    
    fileprivate func fetchCacheItem(key: String, variant: Int64, moc: NSManagedObjectContext) -> CacheItem? {
        let itemRequest: NSFetchRequest<CacheItem> = CacheItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "key == %@ && variant == %lli", key, variant)
        itemRequest.fetchLimit = 1
        do {
            let items = try moc.fetch(itemRequest)
            return items.first
        } catch let error {
            DDLogError("Error fetching cache item: \(error)")
        }
        return nil
    }
    
    fileprivate func fetchCacheGroup(key: String, moc: NSManagedObjectContext) -> CacheGroup? {
        let groupRequest: NSFetchRequest<CacheGroup> = CacheGroup.fetchRequest()
        groupRequest.predicate = NSPredicate(format: "key == %@", key)
        groupRequest.fetchLimit = 1
        do {
            let groups = try moc.fetch(groupRequest)
            return groups.first
        } catch let error {
            DDLogError("Error fetching cache group: \(error)")
        }
        return nil
    }
    
    fileprivate func createCacheItem(key: String, variant: Int64, moc: NSManagedObjectContext) -> CacheItem? {
        guard let entity = NSEntityDescription.entity(forEntityName: "CacheItem", in: moc) else {
            return nil
        }
        let item = CacheItem(entity: entity, insertInto: moc)
        item.key = key
        item.variant = variant
        item.date = NSDate()
        return item
    }
    
    fileprivate func createCacheGroup(key: String, moc: NSManagedObjectContext) -> CacheGroup? {
        guard let entity = NSEntityDescription.entity(forEntityName: "CacheGroup", in: moc) else {
            return nil
        }
        let group = CacheGroup(entity: entity, insertInto: moc)
        group.key = key
        return group
    }
    
    fileprivate func fetchOrCreateCacheItem(key: String, variant: Int64, moc: NSManagedObjectContext) -> CacheItem? {
        return fetchCacheItem(key: key, variant: variant, moc:moc) ?? createCacheItem(key: key, variant: variant, moc: moc)
    }
    
    fileprivate func fetchOrCreateCacheGroup(key: String, moc: NSManagedObjectContext) -> CacheGroup? {
        return fetchCacheGroup(key: key, moc: moc) ?? createCacheGroup(key: key, moc: moc)
    }
    
    
    fileprivate func save(moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            DDLogError("Error saving cache moc: \(error)")
        }
    }
    
    fileprivate func updateCachedFileMimeTypeAtPath(_ path: String, toMIMEType MIMEType: String?) {
        if let MIMEType = MIMEType {
            do {
                try self.fileManager.wmf_setValue(MIMEType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: path)
            } catch let error {
                DDLogError("Error setting extended file attribute for MIME Type: \(error)")
            }
        }
    }
    
    public func permanentlyCache(url: URL, groupKey: String, priority: Float = 0, failure: @escaping (Error) -> Void, success: @escaping () -> Void) {
        let moc = self.managedObjectContext
        moc.perform {
            guard let key = self.cacheKeyForURL(url) else {
                failure(ImageControllerError.invalidOrEmptyURL)
                return
            }
            let variant = self.variantForURL(url)
            if let item = self.fetchCacheItem(key: key, variant: variant, moc: moc) {
                if let group = self.fetchOrCreateCacheGroup(key: groupKey, moc: moc) {
                    group.addToCacheItems(item)
                }
                self.save(moc: moc)
                success()
                return
            }
            let schemedURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless() as URL
            let task = self.session.downloadTask(with: schemedURL, completionHandler: { (fileURL, response, error) in
                guard let fileURL = fileURL, let response = response else {
                    let err = error ?? ImageControllerError.invalidResponse
                    failure(err)
                    return
                }
                moc.perform {
                    let permanentCacheFileURL = self.permanentCacheFileURL(key: key, variant: variant)
                    do {
                        try self.fileManager.moveItem(at: fileURL, to: permanentCacheFileURL)
                        self.updateCachedFileMimeTypeAtPath(permanentCacheFileURL.path, toMIMEType: response.mimeType)
                    } catch let error {
                        DDLogError("Error moving cached file: \(error)")
                    }
                    guard let item = self.fetchOrCreateCacheItem(key: key, variant: variant, moc: moc), let group = self.fetchOrCreateCacheGroup(key: groupKey, moc: moc) else {
                        failure(ImageControllerError.invalidImageCache)
                        return
                    }
                    group.addToCacheItems(item)
                    self.save(moc: moc)
                    success()
                }
            })
            task.priority = priority
            task.resume()
        }
    }
    
    public func permanentlyCacheInBackground(urls: [URL], groupKey: String,  failure: @escaping (Error) -> Void, success: @escaping () -> Void) {
        let cacheGroup = WMFTaskGroup()
        var errors = [NSError]()
        
        for url in urls {
            cacheGroup.enter()
            
            let failure = { (error: Error) in
                errors.append(error as NSError)
                cacheGroup.leave()
            }
            
            let success = {
                cacheGroup.leave()
            }
            
            permanentlyCache(url: url, groupKey: groupKey, failure: failure, success: success)
        }
        cacheGroup.waitInBackground {
            if let error = errors.first {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    public func removePermanentlyCachedImages(groupKey: String) {
        let moc = self.managedObjectContext
        let fm = self.fileManager
        moc.perform {
            guard let group = self.fetchCacheGroup(key: groupKey, moc: moc) else {
                return
            }
            for item in group.cacheItems ?? [] {
                guard let item = item as? CacheItem, let key = item.key, item.cacheGroups?.count == 1 else {
                    continue
                }
                do {
                    let fileURL = self.permanentCacheFileURL(key: key, variant: item.variant)
                    try fm.removeItem(at: fileURL)
                } catch let error {
                    DDLogError("Error removing from permanent cache: \(error)")
                }
                moc.delete(item)
            }
            moc.delete(group)
            self.save(moc: moc)
        }
    }
    
    public func permanentlyCachedTypedDiskDataForImage(withURL url: URL?) -> TypedImageData {
        guard let url = url, let key = cacheKeyForURL(url) else {
            return TypedImageData(data: nil, MIMEType: nil)
        }
        let variant = variantForURL(url)
        let fileURL = permanentCacheFileURL(key: key, variant: variant)
        let mimeType: String? = fileManager.wmf_value(forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: fileURL.path)
        let data = fileManager.contents(atPath: fileURL.path)
        return TypedImageData(data: data, MIMEType: mimeType)
    }
    
    public func permanentlyCachedData(withURL url: URL) -> Data? {
        guard let key = cacheKeyForURL(url) else {
            return nil
        }
        let variant = variantForURL(url)
        let fileURL = permanentCacheFileURL(key: key, variant: variant)
        return fileManager.contents(atPath: fileURL.path)
    }
    
    public func sessionCachedData(withURL url: URL) -> Data? {
        let requestURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless()
        let request = URLRequest(url: requestURL as URL)
        guard let cachedResponse = URLCache.shared.cachedResponse(for: request) else {
            return nil
        }
        return cachedResponse.data
    }

    public func data(withURL url: URL) -> Data? {
        return sessionCachedData(withURL: url) ?? permanentlyCachedData(withURL: url)
    }
    
    public func permanentlyCachedImage(withURL url: URL) -> UIImage? {
        guard let key = cacheKeyForURL(url) else {
            return nil
        }
        let variant = variantForURL(url)
        let fileURL = permanentCacheFileURL(key: key, variant: variant)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    public func sessionCachedImage(withURL url: URL?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        guard let data = sessionCachedData(withURL: url) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    public func cachedImage(withURL url: URL?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        return sessionCachedImage(withURL: url) ?? permanentlyCachedImage(withURL: url)
    }
    
    public func fetchData(withURL url: URL?, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) {
        guard let url = url else {
            failure(ImageControllerError.invalidOrEmptyURL)
            return
        }
        let schemedURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless() as URL
        let task = session.dataTask(with: schemedURL) { (data, response, error) in
            guard let data = data, let response = response else {
                failure(error ?? ImageControllerError.invalidResponse)
                return
            }
            
            success(data, response)
        }
        task.priority = priority
        task.resume()
    }
    
    public func fetchData(withURL url: URL?, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) {
        fetchData(withURL: url, priority: 0.5, failure: failure, success: success)
    }
    
    public func fetchImage(withURL url: URL?, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) {
        guard let url = url else {
            failure(ImageControllerError.invalidOrEmptyURL)
            return
        }
        fetchData(withURL: url, priority: priority, failure: failure) { (data, response) in
            guard let image = UIImage(data: data) else {
                failure(ImageControllerError.invalidResponse)
                return
            }
            success(ImageDownload(url: url, image: image, origin: .unknown, data: data))
        }
    }
    
    public func fetchImage(withURL url: URL?, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) {
        fetchImage(withURL: url, priority: 0.5, failure: failure, success: success)
    }
    
    public func cancelFetch(withURL url: URL?) {
        
    }
    
    public func prefetch(withURL url: URL?) {

        prefetch(withURL: url) {
            
        }
    }
    
    public func prefetch(withURL url: URL?, completion: @escaping () -> Void) {
        guard let url = url else {
            completion()
            return
        }
        fetchData(withURL: url, priority: 0, failure: { (error) in
            completion()
        }) { (data, response) in
            completion()
        }
    }
    
}
