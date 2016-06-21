import Foundation
import CocoaLumberjackSwift

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
@objc public enum WMFImageControllerError: Int, ErrorType {
    case DataNotFound
    case InvalidOrEmptyURL
    case Deinit
}

public class WMFTypedImageData: NSObject {
    let data:NSData?
    let MIMEType:String?
    
    public init(data data_: NSData?, MIMEType type_: String?) {
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
public class WMFImageController : NSObject {
    public override class func initialize() {
        if self === WMFImageController.self {
            let deinitError = WMFImageControllerError.Deinit as NSError
            NSError.registerCancelledErrorDomain(deinitError.domain, code: deinitError.code)
        }
    }
    
    // MARK: - Initialization
    
    private static let defaultNamespace = "default"
    
    private static let _sharedInstance: WMFImageController = {
        let downloader = SDWebImageDownloader.sharedDownloader()
        let cache = SDImageCache.wmf_appSupportCacheWithNamespace(defaultNamespace)
        let memory = NSProcessInfo.processInfo().physicalMemory
        if memory < 805306368 {
            cache.shouldDecompressImages = false
            downloader.shouldDecompressImages = false
            downloader.maxConcurrentDownloads = 4
        }else{
            cache.shouldDecompressImages = true
            downloader.shouldDecompressImages = true
            downloader.maxConcurrentDownloads = 6
        }
        return WMFImageController(manager: SDWebImageManager(downloader: downloader, cache: cache),
                                  namespace: defaultNamespace)
    }()
    
    public static let backgroundImageFetchOptions: SDWebImageOptions = [.LowPriority, .ContinueInBackground, .ReportCancellationAsError]
    
    public class func sharedInstance() -> WMFImageController {
        return _sharedInstance
    }
    
    let imageManager: SDWebImageManager
    
    let cancellingQueue: dispatch_queue_t
    
    private lazy var cancellables: NSMapTable = {
        NSMapTable.strongToWeakObjectsMapTable()
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
     Cache the image at `url` slowly in the background. The image will not be in the memory cache after completion
     
     - parameter url: A URL pointing to an image.
     
     */
    public func cacheImageWithURLInBackground(url: NSURL, failure: (ErrorType) -> Void, completion: (Bool) -> Void) {
        let key = self.cacheKeyForURL(url)
        if(self.imageManager.imageCache.diskImageExistsWithKey(key)){
            completion(true)
        }
        fetchImageWithURL(url, options: WMFImageController.backgroundImageFetchOptions, failure: failure) { (download) in
            self.imageManager.imageCache.removeImageForKey(key, fromDisk: false, withCompletion: nil)
            completion(true)
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
    public func fetchImageWithURL(
        url: NSURL,
        options: SDWebImageOptions = .ReportCancellationAsError,
        failure: (ErrorType) -> Void,
        completion: (WMFImageDownload) -> Void) {
        
        let url = url.wmf_urlByPrependingSchemeIfSchemeless()
        let webImageOperation = imageManager.downloadImageWithURL(url, options: options, progress: nil) { (image, opError, type, finished, imageURL) in
            if let opError = opError {
                failure(opError)
            } else {
                let origin = ImageOrigin(sdOrigin: type)
                completion(WMFImageDownload(url: imageURL, image: image, origin: origin))
            }
        }
        
        addCancellableForURL(SDWebImageOperationWrapper(operation: webImageOperation), url: url)
    }
    
    
    
    
    /// - returns: Whether or not a fetch is outstanding for an image with `url`.
    public func isDownloadingImageWithURL(url: NSURL) -> Bool {
        return imageManager.imageDownloader.isDownloadingImageAtURL(url)
    }
    
    // MARK: - Caching
    
    /// - returns: Whether or not the image corresponding to `url` has been downloaded (ignores URL schemes).
    public func hasImageWithURL(url: NSURL?) -> Bool {
        return url == nil ? false : imageManager.cachedImageExistsForURL(url!)
    }
    
    public func cachedImageInMemoryWithURL(url: NSURL?) -> UIImage? {
        return url == nil ? nil : imageManager.imageCache.imageFromMemoryCacheForKey(cacheKeyForURL(url!))
    }
    
    public func syncCachedImageWithURL(url: NSURL?) -> UIImage? {
        guard url != nil else{
            return nil
        }
        let image = imageManager.imageCache.imageFromDiskCacheForKey(cacheKeyForURL(url!))
        return image
    }
    
    public func hasDataInMemoryForImageWithURL(url: NSURL?) -> Bool {
        return cachedImageInMemoryWithURL(url) != nil
    }
    
    public func hasDataOnDiskForImageWithURL(url: NSURL?) -> Bool {
        guard let url = url else {
            return false
        }
        return imageManager.diskImageExistsForURL(url)
    }
    
    public func diskDataForImageWithURL(url: NSURL?) -> NSData? {
        return typedDiskDataForImageWithURL(url).data
    }
    
    public func typedDiskDataForImageWithURL(url: NSURL?) -> WMFTypedImageData {
        if let url = url {
            let path = imageManager.imageCache.defaultCachePathForKey(cacheKeyForURL(url))
            let mimeType: String? = NSFileManager.defaultManager().wmf_valueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: path)
            let data = NSFileManager.defaultManager().contentsAtPath(path)
            return WMFTypedImageData(data: data, MIMEType: mimeType)
        } else {
            return WMFTypedImageData(data: nil, MIMEType: nil)
        }
    }
    
    public func cachedImageWithURL(url: NSURL, failure: (ErrorType) -> Void, completion: (WMFImageDownload) -> Void) {
        let op = imageManager.imageCache.queryDiskCacheForKey(cacheKeyForURL(url)) { (image, origin) in
            guard let image = image else {
                failure(WMFImageControllerError.DataNotFound)
                return
            }
            completion(WMFImageDownload(url: url, image: image, origin: ImageOrigin(sdOrigin: origin) ?? .None))
        }
        addCancellableForURL(op, url: url)
    }
    
    // MARK: - Deletion
    
    public func clearMemoryCache() {
        imageManager.imageCache.clearMemory()
    }
    
    public func deleteImagesWithURLs(urls: [NSURL]) {
        self.imageManager.wmf_removeImageURLs(urls, fromDisk: true)
    }
    
    public func deleteImageWithURL(url: NSURL?) {
        self.imageManager.wmf_removeImageForURL(url, fromDisk: true)
    }
    
    public func deleteAllImages() {
        self.imageManager.imageCache.clearMemory()
        self.imageManager.imageCache.clearDisk()
    }
    
    public func cacheImageData(imageData: NSData, url: NSURL, MIMEType: String?){
        let diskCachePath = self.imageManager.imageCache.defaultCachePathForKey(self.cacheKeyForURL(url))
        
        let success = NSFileManager.defaultManager().createFileAtPath(diskCachePath, contents: imageData, attributes:nil)
        
        if let MIMEType = MIMEType {
            do {
                try NSFileManager.defaultManager().wmf_setValue(MIMEType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: diskCachePath)
            } catch let error {
                DDLogError("Error setting extended file attribute for MIME Type: \(error)")
            }
        }
        if(!success){
            DDLogDebug("Error caching image data")
        }
    }
    
    /**
     Import image data associated with a URL from a file into the receiver's disk storage.
     
     - parameter filepath: Path the image data on disk.
     - parameter url:      The URL from which the data was downloaded.
     
     - returns: A promise which resolves after the migration was completed.
     */
    public func importImage(fromFile filepath: String, withURL url: NSURL, failure: (ErrorType) -> Void, completion: () -> Void) {
        guard NSFileManager.defaultManager().fileExistsAtPath(filepath) else {
            DDLogInfo("Source file does not exist: \(filepath)")
            // Do not treat this as an error, as the image record could have been created w/o data ever being imported.
            completion()
            return
        }
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queue) { [weak self] in
            guard let `self` = self else {
                failure(WMFImageControllerError.Deinit)
                return
            }
            
            if self.hasDataOnDiskForImageWithURL(url) {
                DDLogDebug("Skipping import of image with URL \(url) since it's already in the cache, deleting it instead")
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(filepath)
                    completion()
                } catch let error {
                    failure(error)
                }
                return
            }
            
            let diskCachePath = self.imageManager.imageCache.defaultCachePathForKey(self.cacheKeyForURL(url))
            let diskCacheURL = NSURL(fileURLWithPath: diskCachePath, isDirectory: false)
            let fileURL = NSURL(fileURLWithPath: filepath, isDirectory: false)
            
            do {
                try NSFileManager.defaultManager()
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
                try NSFileManager.defaultManager().moveItemAtURL(fileURL, toURL: diskCacheURL)
                completion()
            } catch let fileExistsError as NSError where fileExistsError.code == NSFileWriteFileExistsError {
                DDLogDebug("Ignoring file exists error for path \(fileExistsError)")
                completion()
            } catch let error {
                failure(error)
            }
        }
    }
    
    func cacheKeyForURL(url: NSURL) -> String {
        return imageManager.cacheKeyForURL(url)
    }
    
    /**
     Utility which returns a rejected promise for `nil` URLs, or passes valid URLs to function `then`.
     
     - parameter url:  An optional URL.
     - parameter then: The function to call if the URL is valid.
     
     - returns: A rejected promise with `InvalidOrEmptyURL` error if `url` is `nil`, otherwise the promise from `then`.
     */
    private func checkForValidURL(url: NSURL?, @noescape then: (NSURL) -> Promise<WMFImageDownload>) -> Promise<WMFImageDownload> {
        return url.map(then) ?? Promise(error: WMFImageControllerError.InvalidOrEmptyURL)
    }
    
    // MARK: - Cancellation
    
    /// Cancel a pending fetch for an image at `url`.
    public func cancelFetchForURL(url: NSURL?) {
        guard let url = url else {
            return
        }
        dispatch_sync(self.cancellingQueue) { [weak self] in
            if let strongSelf = self,
                cancellable = strongSelf.cancellables.objectForKey(url.absoluteString) as? Cancellable {
                strongSelf.cancellables.removeObjectForKey(url.absoluteString)
                DDLogDebug("Cancelling request for image \(url)")
                cancellable.cancel()
            }
        }
    }
    
    public func cancelAllFetches() {
        dispatch_sync(self.cancellingQueue) {
            let currentCancellables = self.cancellables.objectEnumerator()!.allObjects as! [Cancellable]
            currentCancellables.forEach({ $0.cancel() })
        }
    }
    
    private func addCancellableForURL(cancellable: Cancellable, url: NSURL) {
        dispatch_sync(self.cancellingQueue) { [weak self] in
            guard let cancellables = self?.cancellables else {
                return
            }
            if cancellables.objectForKey(url.absoluteString) != nil {
                DDLogWarn("Ignoring duplicate cancellable for \(url)")
                return
            }
            DDLogVerbose("Adding cancellable for \(url)")
            cancellables.setObject(cancellable, forKey: url.absoluteString)
        }
    }
}


// MARK: - Objective-C Bridge

extension WMFImageController {
    /**
     Objective-C-compatible variant of fetchImageWithURL(url:options:) using default options & returning an `AnyPromise`.
     
     - returns: `AnyPromise` which resolves to `WMFImageDownload`.
     */
    @objc public func fetchImageWithURL(url: NSURL?) -> AnyPromise {
        return AnyPromise(bound: Promise<WMFImageDownload> { fulfill, reject in
            guard let url = url else {
                reject(WMFImageControllerError.InvalidOrEmptyURL)
                return
            }
            fetchImageWithURL(url,
                    failure: { (error) in
                        reject(error);
                    },
                    completion: { (download) in
                        fulfill(download)
                    })
        })
    }

    /**
     Objective-C-compatible variant of cacheImageWithURLInBackground(url:) returning an `AnyPromise`.
     
     - returns: `AnyPromise` which resolves to `WMFImageDownload`.
     */
    @objc public func cacheImageWithURLInBackground(url: NSURL?) -> AnyPromise {
        return AnyPromise(bound: Promise<Bool> { fulfill, reject in
         
            guard let url = url else {
                reject(WMFImageControllerError.InvalidOrEmptyURL)
                return
            }
            cacheImageWithURLInBackground(url, failure: { (error) in
                    reject(error)
                }, completion: { (finished) in
                    fulfill(finished)
            })
        })
    }
    
}