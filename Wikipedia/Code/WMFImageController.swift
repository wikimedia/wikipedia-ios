import Foundation

///
/// @name Constants
///

/**
 WMFImageControllerError
 
 - warning: Due to issues with `ErrorType` to `NSError` bridging, you must check domains of bridged errors like so:
 
 [MyCustomErrorTypeErrorDomain hasSuffix:nsError.domain]
 
 because the generated constant in the Swift header (in this case, `WMFImageControllerErrorDomain` in
 "Wikipedia-Swift.h") doesn't match the actual domain when `ErrorType` is cast to `NSError`.
 
 - DataNotFound:      Failed to find cached image data for the provided URL.
 - InvalidOrEmptyURL: The provided URL was empty or `nil`.
 - Deinit:            Fetch was cancelled because the image controller was deallocated.
 */
@objc public enum WMFImageControllerError: Int, Error {
    case dataNotFound
    case invalidOrEmptyURL
    case `deinit`
}

open class WMFTypedImageData: NSObject {
    let data:Data?
    let MIMEType:String?
    
    public init(data data_: Data?, MIMEType type_: String?) {
        data = data_
        MIMEType = type_
    }
}

// FIXME: Can't extend the SDWebImageOperation protocol or cast the return value, so we wrap it.
class SDWebImageOperationWrapper: NSObject, Cancellable {
    weak var operation: SDWebImageOperation?
    required init(operation: SDWebImageOperation) {
        super.init()
        self.operation = operation
        // keep wrapper around as long as operation is around
        objc_setAssociatedObject(operation,
                                 "SDWebImageOperationWrapper",
                                 self,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func cancel() -> Void {
        operation?.cancel()
    }
}


let WMFExtendedFileAttributeNameMIMEType = "org.wikimedia.MIMEType"

@objc
open class WMFImageController : NSObject {
    open override class func initialize() {
        if self === WMFImageController.self {
            let deinitError = WMFImageControllerError.Deinit as NSError
            NSError.registerCancelledErrorDomain(deinitError.domain, code: deinitError.code)
        }
    }
    
    // MARK: - Initialization
    
    fileprivate static let defaultNamespace = "default"
    
    fileprivate static let _sharedInstance: WMFImageController = {
        let downloader = SDWebImageDownloader.sharedDownloader()
        let cache = SDImageCache.wmf_appSupportCacheWithNamespace(defaultNamespace)
        let memory = ProcessInfo.processInfo.physicalMemory
        //Don't enable this, it causes crazy memory consumption
        //https://github.com/rs/SDWebImage/issues/586
        cache.shouldDecompressImages = false
        downloader.shouldDecompressImages = false
        if memory < 805306368 {
            downloader.maxConcurrentDownloads = 4
        }else{
            downloader.maxConcurrentDownloads = 6
        }
        return WMFImageController(manager: SDWebImageManager(downloader: downloader, cache: cache),
                                  namespace: defaultNamespace)
    }()
    
    open static let backgroundImageFetchOptions: SDWebImageOptions = [.LowPriority, .ContinueInBackground, .ReportCancellationAsError]
    
    open class func sharedInstance() -> WMFImageController {
        return _sharedInstance
    }
    
    let imageManager: SDWebImageManager
    
    let cancellingQueue: DispatchQueue
    
    fileprivate lazy var cancellables: NSMapTable = {
        NSMapTable.strongToWeakObjects()
    }()
    
    public required init(manager: SDWebImageManager, namespace: String) {
        self.imageManager = manager;
        self.imageManager.cacheKeyFilter = { (url: NSURL?) in url?.wmf_schemelessURLString() }
        self.cancellingQueue = dispatch_queue_create("org.wikimedia.wikipedia.wmfimagecontroller.\(namespace)",
                                                     DISPATCH_QUEUE_SERIAL)
        super.init()
    }
    
    deinit {
        cancelAllFetches()
    }
    
    // MARK: - Complex Fetching
    
    /**
     Cache the image at `url` slowly in the background. The image will not be in the memory cache after success
     
     - parameter url: A URL pointing to an image.
     
     */
    open func cacheImageWithURLInBackground(_ url: URL, failure: (Error) -> Void, success: @escaping (Bool) -> Void) {
        let key = self.cacheKeyForURL(url)
        if(self.imageManager.imageCache.diskImageExistsWithKey(key)){
            success(true)
            return
        }
        fetchImageWithURL(url, options: WMFImageController.backgroundImageFetchOptions, failure: failure) { (download) in
            self.imageManager.imageCache.removeImageForKey(key, fromDisk: false, withCompletion: nil)
            success(true)
        }
    }
    
    // MARK: - Simple Fetching
    
    /**
     Retrieve the data and uncompressed image for `url`.
     
     If the URL is `nil`, then the promise will be rejected with `InvalidOrEmptyURL`.
     
     - parameter url: URL which corresponds to the image being retrieved. Ignores URL schemes.
     
     - returns: A `WMFImageDownload` with the image data and the origin it was loaded from.
     
     - seealso: WMFImageControllerError
     */
    open func fetchImageWithURL(
        _ url: URL,
        options: SDWebImageOptions = .ReportCancellationAsError,
        failure: @escaping (Error) -> Void,
        success: @escaping (WMFImageDownload) -> Void) {
        
        let url = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless()
        let webImageOperation = imageManager.downloadImageWithURL(url, options: options, progress: nil) { (image, opError, type, finished, imageURL) in
            if let opError = opError {
                failure(opError)
            } else {
                let origin = ImageOrigin(sdOrigin: type)
                success(WMFImageDownload(url: imageURL, image: image, origin: origin))
            }
        }
        
        addCancellableForURL(SDWebImageOperationWrapper(operation: webImageOperation), url: url)
    }
    
    
    
    
    /// - returns: Whether or not a fetch is outstanding for an image with `url`.
    open func isDownloadingImageWithURL(_ url: URL) -> Bool {
        return imageManager.imageDownloader.isDownloadingImageAtURL(url)
    }
    
    // MARK: - Caching
    
    /// - returns: Whether or not the image corresponding to `url` has been downloaded (ignores URL schemes).
    open func hasImageWithURL(_ url: URL?) -> Bool {
        return url == nil ? false : imageManager.cachedImageExistsForURL(url!)
    }
    
    open func cachedImageInMemoryWithURL(_ url: NSURL?) -> UIImage? {
        return url == nil ? nil : imageManager.imageCache.imageFromMemoryCacheForKey(cacheKeyForURL(url!))
    }
    
    open func syncCachedImageWithURL(_ url: NSURL?) -> UIImage? {
        guard let url = url else{
            return nil
        }
        let key = cacheKeyForURL(url)
        var image = imageManager.imageCache.imageFromDiskCacheForKey(key)
        if image  == nil { // if it's not in the SDWebImage cache, check the NSURLCache
            let request = URLRequest(URL: url.wmf_urlByPrependingSchemeIfSchemeless())
            if let cachedResponse = URLCache.sharedURLCache().cachedResponseForRequest(request),
                let cachedImage = UIImage(data: cachedResponse.data) {
                image = cachedImage
                //since we got a valid image, store it in the SDWebImage memory cache
                imageManager.imageCache.storeImage(image, recalculateFromImage: false, imageData: cachedResponse.data, forKey: key, toDisk: false)
            }
        }
        return image
    }
    
    open func hasDataInMemoryForImageWithURL(_ url: URL?) -> Bool {
        return cachedImageInMemoryWithURL(url) != nil
    }
    
    open func hasDataOnDiskForImageWithURL(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        return imageManager.diskImageExistsForURL(url)
    }
    
    open func diskDataForImageWithURL(_ url: URL?) -> Data? {
        return typedDiskDataForImageWithURL(url).data
    }
    
    open func typedDiskDataForImageWithURL(_ url: URL?) -> WMFTypedImageData {
        if let url = url {
            let path = imageManager.imageCache.defaultCachePathForKey(cacheKeyForURL(url))
            let mimeType: String? = FileManager.defaultManager().wmf_valueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: path)
            let data = FileManager.defaultManager().contentsAtPath(path)
            return WMFTypedImageData(data: data, MIMEType: mimeType)
        } else {
            return WMFTypedImageData(data: nil, MIMEType: nil)
        }
    }
    
    open func cachedImageWithURL(_ url: URL, failure: @escaping (Error) -> Void, success: @escaping (WMFImageDownload) -> Void) {
        let op = imageManager.imageCache.queryDiskCacheForKey(cacheKeyForURL(url)) { (image, origin) in
            guard let image = image else {
                failure(WMFImageControllerError.DataNotFound)
                return
            }
            success(WMFImageDownload(url: url, image: image, origin: ImageOrigin(sdOrigin: origin) ?? .None))
        }
        addCancellableForURL(op, url: url)
    }
    
    // MARK: - Deletion
    
    open func clearMemoryCache() {
        imageManager.imageCache.clearMemory()
    }
    
    open func deleteImagesWithURLs(_ urls: [URL]) {
        self.imageManager.wmf_removeImageURLs(urls, fromDisk: true)
    }
    
    open func deleteImageWithURL(_ url: URL?) {
        self.imageManager.wmf_removeImageForURL(url, fromDisk: true)
    }
    
    open func deleteAllImages() {
        self.imageManager.imageCache.clearMemory()
        self.imageManager.imageCache.clearDisk()
    }
    
    fileprivate func updateCachedFileMimeTypeAtPath(_ path: String, toMIMEType MIMEType: String?) {
        if let MIMEType = MIMEType {
            do {
                try FileManager.default.wmf_setValue(MIMEType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: path)
            } catch let error {
                DDLogError("Error setting extended file attribute for MIME Type: \(error)")
            }
        }
    }
    
    open func cacheImageFromFileURL(_ fileURL: Foundation.URL, forURL URL: Foundation.URL, MIMEType: String?){
        let diskCachePath = self.imageManager.imageCache.defaultCachePathForKey(self.cacheKeyForURL(URL))
        let diskCacheURL = Foundation.URL(fileURLWithPath: diskCachePath, isDirectory: false)
        
        do {
            try FileManager.defaultManager().copyItemAtURL(fileURL, toURL: diskCacheURL)
        } catch let error {
            DDLogError("Error copying cached file: \(error)")
        }
        
        updateCachedFileMimeTypeAtPath(diskCachePath, toMIMEType: MIMEType)
    }
    
    open func cacheImageData(_ imageData: Data, url: URL, MIMEType: String?){
        let diskCachePath = self.imageManager.imageCache.defaultCachePathForKey(self.cacheKeyForURL(url))
        
        if (FileManager.defaultManager().createFileAtPath(diskCachePath, contents: imageData, attributes:nil)) {
            updateCachedFileMimeTypeAtPath(diskCachePath, toMIMEType: MIMEType)
        } else {
            DDLogDebug("Error caching image data")
        }
    }
    
    /**
     Import image data associated with a URL from a file into the receiver's disk storage.
     
     - parameter filepath: Path the image data on disk.
     - parameter url:      The URL from which the data was downloaded.
     
     - returns: A promise which resolves after the migration was completed.
     */
    open func importImage(fromFile filepath: String, withURL url: URL, failure: @escaping (Error) -> Void, success: @escaping () -> Void) {
        guard FileManager.default.fileExists(atPath: filepath) else {
            DDLogInfo("Source file does not exist: \(filepath)")
            // Do not treat this as an error, as the image record could have been created w/o data ever being imported.
            success()
            return
        }
        
        let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background);
        queue.async { [weak self] in
            guard let `self` = self else {
                failure(WMFImageControllerError.deinit)
                return
            }
            
            if self.hasDataOnDiskForImageWithURL(url) {
                DDLogDebug("Skipping import of image with URL \(url) since it's already in the cache, deleting it instead")
                do {
                    try FileManager.default.removeItem(atPath: filepath)
                    success()
                } catch let error {
                    failure(error)
                }
                return
            }
            
            let diskCachePath = self.imageManager.imageCache.defaultCachePathForKey(self.cacheKeyForURL(url))
            let diskCacheURL = URL(fileURLWithPath: diskCachePath, isDirectory: false)
            let fileURL = URL(fileURLWithPath: filepath, isDirectory: false)
            
            do {
                try FileManager.defaultManager()
                    .createDirectoryAtURL(diskCacheURL.URLByDeletingLastPathComponent!,
                                          withIntermediateDirectories: true,
                                          attributes: nil)
            } catch let fileExistsError as NSError where fileExistsError.code == NSFileWriteFileExistsError {
                DDLogDebug("Ignoring file exists error for path \(fileExistsError)")
            } catch let error {
                failure(error)
                return
            }
            
            do {
                try FileManager.defaultManager().moveItemAtURL(fileURL, toURL: diskCacheURL)
                success()
            } catch let fileExistsError as NSError where fileExistsError.code == NSFileWriteFileExistsError {
                DDLogDebug("Ignoring file exists error for path \(fileExistsError)")
                success()
            } catch let error {
                failure(error)
            }
        }
    }
    
    func cacheKeyForURL(_ url: URL) -> String {
        return imageManager.cacheKeyForURL(url)
    }
    
    // MARK: - Cancellation
    
    /// Cancel a pending fetch for an image at `url`.
    open func cancelFetchForURL(_ url: URL?) {
        guard let url = url else {
            return
        }
        self.cancellingQueue.sync { [weak self] in
            if let strongSelf = self,
                let cancellable = strongSelf.cancellables.object(forKey: url.absoluteString) as? Cancellable {
                strongSelf.cancellables.removeObject(forKey: url.absoluteString)
                DDLogDebug("Cancelling request for image \(url)")
                cancellable.cancel()
            }
        }
    }
    
    open func cancelAllFetches() {
        self.cancellingQueue.sync {
            let currentCancellables = self.cancellables.objectEnumerator()!.allObjects as! [Cancellable]
            currentCancellables.forEach({ $0.cancel() })
        }
    }
    
    fileprivate func addCancellableForURL(_ cancellable: Cancellable, url: URL) {
        self.cancellingQueue.sync { [weak self] in
            guard let cancellables = self?.cancellables else {
                return
            }
            if cancellables.object(forKey: _(rawValue: _(url.absoluteString))) != nil {
                DDLogWarn("Ignoring duplicate cancellable for \(url)")
                return
            }
            DDLogVerbose("Adding cancellable for \(url)")
            cancellables.setObject(cancellable, forKey: url.absoluteString)
        }
    }
    
    open func cachePathForImageWithURL(_ URL: Foundation.URL) -> NSString {
        return imageManager.imageCache.defaultCachePathForKey(cacheKeyForURL(URL))
    }
}


// MARK: - Objective-C Bridge

extension WMFImageController {
    
    /**
     Objective-C-compatible variant of fetchImageWithURL(url:options:) using default options & using blocks.
     
     - returns: `AnyPromise` which resolves to `WMFImageDownload`.
     */
    @objc public func fetchImageWithURL(_ url: URL?, failure: @escaping (_ error: NSError) -> Void, success: (_ download: WMFImageDownload) -> Void) {
        guard let url = url else {
            failure(WMFImageControllerError.InvalidOrEmptyURL as NSError)
            return
        }
        
        let metaFailure = { (error: Error) in
            failure(error as NSError)
        }
        fetchImageWithURL(url, failure: metaFailure, success:success);
    }

    /**
     Objective-C-compatible variant of cacheImageWithURLInBackground(url:, failure:, success:)
     
     - returns: A string to make OCMockito work.
     */
    @objc public func cacheImageWithURLInBackground(_ url: URL?, failure: @escaping (_ error: NSError) -> Void, success: (_ didCache: Bool) -> Void) -> AnyObject? {
        guard let url = url else {
            failure(WMFImageControllerError.InvalidOrEmptyURL as NSError)
            return nil
        }
        
        let metaFailure = { (error: Error) in
            failure(error as NSError)
        }
        cacheImageWithURLInBackground(url, failure: metaFailure, success: success);
        
        return nil
    }
    
    
    @objc public func cacheImagesWithURLsInBackground(_ imageURLs: [URL], failure: @escaping (_ error: NSError) -> Void, success: @escaping () -> Void) -> AnyObject? {
        let cacheGroup = WMFTaskGroup()
        var errors = [NSError]()
        
        for imageURL in imageURLs {
            cacheGroup.enter()
            
            let failure = { (error: Error) in
                errors.append(error as NSError)
                cacheGroup.leave()
            }

            let success = { (didCache: Bool) in
                self.imageManager.wmf_removeImageForURL(imageURL, fromDisk: false)
                cacheGroup.leave()
            }
            
            cacheImageWithURLInBackground(imageURL, failure:failure, success: success)
        }
        
        cacheGroup.waitInBackgroundWithCompletion { 
            if let error = errors.first {
                failure(error: error)
            } else {
                success()
            }
        }
        
        return nil
    }
}
