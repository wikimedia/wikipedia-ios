import Foundation
import CocoaLumberjackSwift
import ImageIO
import FLAnimatedImage

@objc(WMFImageControllerError) public enum ImageControllerError: Int, Error {
    case dataNotFound
    case invalidOrEmptyURL
    case invalidImageCache
    case invalidResponse
    case duplicateRequest
    case fileError
    case dbError
    case `deinit`
}

@objc(WMFTypedImageData)
open class TypedImageData: NSObject {
    @objc public let data:Data?
    @objc public let MIMEType:String?
    
    @objc public init(data data_: Data?, MIMEType type_: String?) {
        data = data_
        MIMEType = type_
    }
}

fileprivate extension Error {
    var isCancellationError: Bool {
        get {
            let potentialCancellationError = self as NSError
            return potentialCancellationError.domain == NSURLErrorDomain && potentialCancellationError.code == NSURLErrorCancelled
        }
    }
}

let WMFExtendedFileAttributeNameMIMEType = "org.wikimedia.MIMEType"

@objc(WMFImageController)
open class ImageController : NSObject {
    // MARK: - Initialization
    
    @objc(sharedInstance) public static let shared: ImageController = {
        let session = Session.urlSession
        let cache = URLCache.shared
        let fileManager = FileManager.default
        var permanentStorageDirectory = fileManager.wmf_containerURL().appendingPathComponent("Permanent Image Cache", isDirectory: true)
        var didGetDirectoryExistsError = false
        do {
            try fileManager.createDirectory(at: permanentStorageDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            DDLogError("Error creating permanent cache: \(error)")
        }
        do {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try permanentStorageDirectory.setResourceValues(values)
        } catch let error {
            DDLogError("Error excluding from backup: \(error)")
        }
        return ImageController(session: session, cache: cache, fileManager: fileManager, permanentStorageDirectory: permanentStorageDirectory)
    }()
    
    
    @objc public static func temporaryController() -> ImageController {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let imageControllerDirectory = temporaryDirectory.appendingPathComponent("ImageController-" + UUID().uuidString)
        let config = Session.defaultConfiguration
        let cache = URLCache(memoryCapacity: 1000000000, diskCapacity: 1000000000, diskPath: imageControllerDirectory.path)
        config.urlCache = cache
        let session = URLSession(configuration: config)
        let fileManager = FileManager.default
        let permanentStorageDirectory = imageControllerDirectory.appendingPathComponent("Permanent Image Cache", isDirectory: true)
        do {
            try fileManager.createDirectory(at: permanentStorageDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            DDLogError("Error creating permanent cache: \(error)")
        }
        return ImageController(session: session, cache: cache, fileManager: fileManager, permanentStorageDirectory: permanentStorageDirectory)
    }
    
    
    fileprivate let session: URLSession
    fileprivate let cache: URLCache
    fileprivate let permanentStorageDirectory: URL
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate let persistentStoreCoordinator: NSPersistentStoreCoordinator
    fileprivate let fileManager: FileManager
    fileprivate let memoryCache: NSCache<NSString, Image>
    
    fileprivate var permanentCacheCompletionManager = ImageControllerCompletionManager<ImageControllerPermanentCacheCompletion>()
    fileprivate var dataCompletionManager = ImageControllerCompletionManager<ImageControllerDataCompletion>()
    
    @objc public required init(session: URLSession, cache: URLCache, fileManager: FileManager, permanentStorageDirectory: URL) {
        self.session = session
        self.cache = cache
        self.fileManager = fileManager
        self.permanentStorageDirectory = permanentStorageDirectory
        memoryCache = NSCache<NSString, Image>()
        memoryCache.totalCostLimit = 10000000 //pixel count
        let bundle = Bundle.wmf
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
    
    
    fileprivate func cacheKeyForURL(_ url: URL) -> String {
        guard let host = url.host, let imageName = WMFParseImageNameFromSourceURL(url) else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
        return (host + "__" + imageName).precomposedStringWithCanonicalMapping
    }
    
    fileprivate func variantForURL(_ url: URL) -> Int64 { // A return value of 0 indicates the original size
        let sizePrefix = WMFParseSizePrefixFromSourceURL(url)
        return Int64(sizePrefix == NSNotFound ? 0 : sizePrefix)
    }
    
    fileprivate func identifierForURL(_ url: URL) -> String {
        let key = cacheKeyForURL(url)
        let variant = variantForURL(url)
        return "\(key)__\(variant)".precomposedStringWithCanonicalMapping
    }
    
    fileprivate func identifierForKey(_ key: String, variant: Int64) -> String {
        return "\(key)__\(variant)".precomposedStringWithCanonicalMapping
    }
    
    fileprivate func legacyPermanentCacheFileURL(key: String, variant: Int64) -> URL {
        let identifier = identifierForKey(key, variant: variant)
        return self.permanentStorageDirectory.appendingPathComponent(identifier, isDirectory: false)
    }
    
    fileprivate func permanentCacheFileURL(key: String, variant: Int64) -> URL {
        let identifier = identifierForKey(key, variant: variant)
        let component = identifier.sha256 ?? identifier
        return self.permanentStorageDirectory.appendingPathComponent(component, isDirectory: false)
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
    
    @objc public func permanentlyCache(url: URL, groupKey: String, priority: Float = URLSessionTask.lowPriority, failure: @escaping (Error) -> Void, success: @escaping () -> Void) {
        let key = self.cacheKeyForURL(url)
        let variant = self.variantForURL(url)
        let identifier = self.identifierForKey(key, variant: variant)
        let completion = ImageControllerPermanentCacheCompletion(success: success, failure: failure)
        let token = UUID().uuidString
        guard permanentCacheCompletionManager.add(completion, priority: priority, forGroup: groupKey, identifier: identifier, token: token) else {
            return
        }
        perform { (moc) in
            if let item = self.fetchCacheItem(key: key, variant: variant, moc: moc) {
                if let group = self.fetchOrCreateCacheGroup(key: groupKey, moc: moc) {
                    group.addToCacheItems(item)
                }
                self.save(moc: moc)
                self.permanentCacheCompletionManager.complete(groupKey, identifier: identifier, enumerator: { (completion) in
                    completion.success()
                })
                return
            }
            let schemedURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless() as URL
            let task = self.session.downloadTask(with: schemedURL, completionHandler: { (fileURL, response, error) in
                guard !self.isCancellationError(error) else {
                    return
                }
                guard let fileURL = fileURL, let response = response else {
                    let err = error ?? ImageControllerError.invalidResponse
                    self.permanentCacheCompletionManager.complete(groupKey, identifier: identifier, enumerator: { (completion) in
                        completion.failure(err)
                    })
                    return
                }
                let permanentCacheFileURL = self.permanentCacheFileURL(key: key, variant: variant)
                var createItem = false
                do {
                    try self.fileManager.moveItem(at: fileURL, to: permanentCacheFileURL)
                    self.updateCachedFileMimeTypeAtPath(permanentCacheFileURL.path, toMIMEType: response.mimeType)
                    createItem = true
                } catch let error as NSError {
                    if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteFileExistsError { // file exists
                        createItem = true
                    } else {
                        DDLogError("Error moving cached file: \(error)")
                    }
                } catch let error {
                    DDLogError("Error moving cached file: \(error)")
                }
                self.perform { (moc) in
                    guard createItem else {
                        self.permanentCacheCompletionManager.complete(groupKey, identifier: identifier, enumerator: { (completion) in
                            completion.failure(ImageControllerError.fileError)
                        })
                        return
                    }
                    guard let item = self.fetchOrCreateCacheItem(key: key, variant: variant, moc: moc), let group = self.fetchOrCreateCacheGroup(key: groupKey, moc: moc) else {
                        self.permanentCacheCompletionManager.complete(groupKey, identifier: identifier, enumerator: { (completion) in
                            completion.failure(ImageControllerError.dbError)
                        })
                        return
                    }
                    group.addToCacheItems(item)
                    self.save(moc: moc)
                    self.permanentCacheCompletionManager.complete(groupKey, identifier: identifier, enumerator: { (completion) in
                        completion.success()
                    })
                }
            })
            task.priority = priority
            self.permanentCacheCompletionManager.add(task, forGroup: groupKey, identifier: identifier)
            task.resume()
        }
    }
    
    @objc public func permanentlyCacheInBackground(urls: [URL], groupKey: String,  failure: @escaping (Error) -> Void, success: @escaping () -> Void) {
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
    
    private func perform(_ block: @escaping (_ moc: NSManagedObjectContext) -> Void) {
        let task = Background.manager.beginTask()
        let moc = self.managedObjectContext
        moc.perform {
            block(moc)
            Background.manager.endTask(withIdentifier: task)
        }
    }
    
    @objc public func removePermanentlyCachedImages(groupKey: String, completion: @escaping () -> Void) {
        let fm = self.fileManager
        perform { (moc) in
            self.permanentCacheCompletionManager.cancel(group: groupKey)
            guard let group = self.fetchCacheGroup(key: groupKey, moc: moc) else {
                completion()
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
                do {
                    let legacyFileURL = self.legacyPermanentCacheFileURL(key: key, variant: item.variant)
                    try fm.removeItem(at: legacyFileURL)
                } catch let error {
                    DDLogError("Error removing from permanent cache: \(error)")
                }
                moc.delete(item)
            }
            moc.delete(group)
            self.save(moc: moc)
            completion()
        }
    }
    
    @objc public func permanentlyCachedTypedDiskDataForImage(withURL url: URL?) -> TypedImageData {
        guard let url = url else {
            return TypedImageData(data: nil, MIMEType: nil)
        }
        let key = cacheKeyForURL(url)
        let variant = variantForURL(url)
        let fileURL = permanentCacheFileURL(key: key, variant: variant)
        var mimeType: String? = fileManager.wmf_value(forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: fileURL.path)
        var data = fileManager.contents(atPath: fileURL.path)
        if data == nil { // check for legacy data
            let legacyFileURL = legacyPermanentCacheFileURL(key: key, variant: variant)
           mimeType = fileManager.wmf_value(forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: legacyFileURL.path)
            data = fileManager.contents(atPath: legacyFileURL.path)
        }
        return TypedImageData(data: data, MIMEType: mimeType)
    }
    
    @objc public func sessionCachedData(withURL url: URL) -> TypedImageData? {
        let requestURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless()
        let request = URLRequest(url: requestURL as URL)
        guard let cachedResponse = URLCache.shared.cachedResponse(for: request) else {
            return nil
        }
        return TypedImageData(data: cachedResponse.data, MIMEType: cachedResponse.response.mimeType)
    }
    
    @objc public func data(withURL url: URL) -> TypedImageData? {
        return sessionCachedData(withURL: url) ?? permanentlyCachedTypedDiskDataForImage(withURL: url)
    }
    
    @objc public func memoryCachedImage(withURL url: URL) -> Image? {
        let identifier = identifierForURL(url) as NSString
        return memoryCache.object(forKey: identifier)
    }
    
    @objc public func addToMemoryCache(_ image: Image, url: URL) {
        let identifier = identifierForURL(url) as NSString
        memoryCache.setObject(image, forKey: identifier, cost: Int(image.staticImage.size.width * image.staticImage.size.height))
    }
    
    fileprivate func createImage(data: Data, mimeType: String?) -> Image? {
        if mimeType == "image/gif", let animatedImage = FLAnimatedImage.wmf_animatedImage(with: data), let staticImage = animatedImage.wmf_staticImage {
            return Image(staticImage: staticImage, animatedImage: animatedImage)
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) > 0 else {
            return nil
        }
        let options = [kCGImageSourceShouldCache as String: NSNumber(value: true)] as CFDictionary
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        return Image(staticImage: image, animatedImage: nil)
    }
    
    @objc public func permanentlyCachedImage(withURL url: URL) -> Image? {
        if let memoryCachedImage = memoryCachedImage(withURL: url) {
            return memoryCachedImage
        }
        let typedDiskData = permanentlyCachedTypedDiskDataForImage(withURL: url)
        guard let data = typedDiskData.data else {
            return nil
        }
        guard let image = createImage(data: data, mimeType: typedDiskData.MIMEType) else {
            return nil
        }
        self.addToMemoryCache(image, url: url)
        return image
    }
    
    @objc public func sessionCachedImage(withURL url: URL?) -> Image? {
        guard let url = url else {
            return nil
        }
        if let memoryCachedImage = memoryCachedImage(withURL: url) {
            return memoryCachedImage
        }
        guard let typedData = sessionCachedData(withURL: url), let data = typedData.data else {
            return nil
        }
        guard let image = createImage(data: data, mimeType:typedData.MIMEType) else {
            return nil
        }
        self.addToMemoryCache(image, url: url)
        return image
    }
    
    @objc public func cachedImage(withURL url: URL?) -> Image? {
        guard let url = url else {
            return nil
        }
        return sessionCachedImage(withURL: url) ?? permanentlyCachedImage(withURL: url)
    }
    
    fileprivate func isCancellationError(_ error: Error?) -> Bool {
        return error?.isCancellationError ?? false
    }
    
    @objc public func fetchData(withURL url: URL?, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) -> String? {
        guard let url = url else {
            failure(ImageControllerError.invalidOrEmptyURL)
            return nil
        }
        let token = UUID().uuidString
        let identifier = identifierForURL(url)
        let completion = ImageControllerDataCompletion(success: success, failure: failure)
        guard dataCompletionManager.add(completion, priority: priority, forIdentifier: identifier, token: token) else {
            //DDLogDebug("unable to add completion: %@", url)
            return nil
        }
        let schemedURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless() as URL
        //DDLogDebug("fetching: \(url) \(token)")
        let task = session.dataTask(with: schemedURL) { (data, response, error) in
            guard !self.isCancellationError(error) else {
                //DDLogDebug("cancelled: \(url) \(token)")
                return
            }
            self.dataCompletionManager.complete(identifier, enumerator: { (completion) in
                //DDLogDebug("complete: \(url) \(token)")
                guard let data = data, let response = response else {
                    completion.failure(error ?? ImageControllerError.invalidResponse)
                    return
                }
                completion.success(data, response)
            })
        }
        task.priority = priority
        dataCompletionManager.add(task, forIdentifier: identifier)
        task.resume()
        return token
    }
    
    @objc public func fetchData(withURL url: URL?, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) {
        let _ = fetchData(withURL: url, priority: URLSessionTask.defaultPriority, failure: failure, success: success)
    }

    @objc public func fetchImage(withURL url: URL?, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) -> String? {
        assert(Thread.isMainThread)
        guard let url = url else {
            //DDLogDebug("invalid or empty")
            failure(ImageControllerError.invalidOrEmptyURL)
            return nil
        }
        if let memoryCachedImage = memoryCachedImage(withURL: url) {
            //DDLogDebug("memory: \(url)")
            success(ImageDownload(url: url, image: memoryCachedImage, origin: .memory))
            return nil
        }
        return fetchData(withURL: url, priority: priority, failure: failure) { (data, response) in
            guard let image = self.createImage(data: data, mimeType: response.mimeType) else {
                DispatchQueue.main.async {
                    //DDLogDebug("invalid: \(url)")
                    failure(ImageControllerError.invalidResponse)
                }
                return
            }
            self.addToMemoryCache(image, url: url)
            DispatchQueue.main.async {
                //DDLogDebug("success: \(url)")
                success(ImageDownload(url: url, image: image, origin: .unknown))
            }
        }
    }
    
    @objc public func fetchImage(withURL url: URL?, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) {
        let _ = fetchImage(withURL: url, priority: URLSessionTask.defaultPriority, failure: failure, success: success)
    }
    
    @objc public func cancelFetch(withURL url: URL?, token: String?) {
        guard let url = url, let token = token else {
            return
        }
        let identifier = identifierForURL(url)
        //DDLogDebug("cancelling: \(url) \(token)")
        dataCompletionManager.cancel(identifier, token: token)
    }
    
    @objc public func prefetch(withURL url: URL?) {
        prefetch(withURL: url) { }
    }
    
    @objc public func prefetch(withURL url: URL?, completion: @escaping () -> Void) {
        let _ =  fetchImage(withURL: url, priority: URLSessionTask.lowPriority, failure: { (error) in }) { (download) in }
    }
    
    @objc public func deleteTemporaryCache() {
        cache.removeAllCachedResponses()
    }
    
    // MARK: - Migration from SDWebImage
    
    fileprivate var legacyCacheFolderURL: URL {
        get {
            return fileManager.wmf_containerURL().appendingPathComponent("Cache").appendingPathComponent("com.hackemist.SDWebImageCache.default")
        }
    }
    
    @objc public func migrateLegacyImageURLs(_ imageURLs: [URL], intoGroup group: String, completion: @escaping () -> Void) {
        let legacyCacheFolderURL = self.legacyCacheFolderURL
        let legacyCacheFolderPath = legacyCacheFolderURL.path
        perform { (moc) in
            let group = self.fetchOrCreateCacheGroup(key: group, moc: moc)
            for imageURL in imageURLs {
                let key = self.cacheKeyForURL(imageURL)
                let variant = self.variantForURL(imageURL)
                if let existingItem = self.fetchCacheItem(key: key, variant: variant, moc: moc) {
                    group?.addToCacheItems(existingItem)
                    continue
                }
                guard let legacyKey = (imageURL as NSURL).wmf_schemelessURLString(),
                    let legacyPath = WMFLegacyImageCache.cachePath(forKey: legacyKey, inPath: legacyCacheFolderPath) else {
                        continue
                }
                
                let fileURL = self.permanentCacheFileURL(key: key, variant: variant)
                let legacyFileURL = URL(fileURLWithPath: legacyPath, isDirectory: false)
                var createItem = false
                do {
                    try self.fileManager.moveItem(at: legacyFileURL, to: fileURL)
                    createItem = true
                } catch let error as NSError {
                    if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteFileExistsError { // file exists
                        createItem = true
                    }
                } catch let error {
                    DDLogError("Error moving cached file: \(error)")
                }
                
                if !createItem {
                    let legacyPermanentCacheURL = self.legacyPermanentCacheFileURL(key: key, variant: variant)
                    do {
                        try self.fileManager.moveItem(at: legacyPermanentCacheURL, to: fileURL)
                        createItem = true
                    } catch let error as NSError {
                        if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteFileExistsError { // file exists
                            createItem = true
                        }
                    } catch let error {
                        DDLogError("Error moving cached file: \(error)")
                    }
                }
                
                guard createItem else {
                    continue
                }
                if let item = self.fetchOrCreateCacheItem(key: key, variant: variant, moc: moc) {
                    group?.addToCacheItems(item)
                }
            }
            self.save(moc: moc)
            completion()
        }
    }
    
    @objc public func removeLegacyCache() {
        do {
            try fileManager.removeItem(at: legacyCacheFolderURL)
        } catch let error as NSError {
            guard error.domain != NSCocoaErrorDomain || error.code != NSFileNoSuchFileError else {
                return
            }
            DDLogError("Error removing legacy cache \(error)")
        }
    }
    
    public var temporaryCacheSize: Int64 {
        return FileManager.default.sizeOfDirectory(at: legacyCacheFolderURL) + Int64(cache.currentDiskUsage)
    }
}
