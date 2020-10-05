
import Foundation

enum ImageCacheControllerError: Error {
    case failureGeneratingUniqueKey
}

public final class ImageCacheController: CacheController {
    // MARK: Permanent Cache
    
    //batch inserts to db and selectively decides which file variant to download. Used when inserting multiple image urls from media-list endpoint via ArticleCacheController.
    func add(urls: [URL], groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {

        //todo: could use DRY gatekeeper logic with superclass. this will likely get refactored out so holding off.
        if gatekeeper.shouldQueueAddCompletion(groupKey: groupKey) {
            gatekeeper.queueAddCompletion(groupKey: groupKey) {
                self.add(urls: urls, groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion)
                return
            }
        } else {
            gatekeeper.addCurrentlyAddingGroupKey(groupKey)
        }
        
        if gatekeeper.numberOfQueuedGroupCompletions(for: groupKey) > 0 {
            gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
            return
        }
        
        gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
        
        dbWriter.add(urls: urls, groupKey: groupKey) { [weak self] (result) in
            self?.finishDBAdd(groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion, result: result)
        }
    }
    
    //MARK: Logic taken from ImageController
    
    private let imageFetcher: ImageFetcher
    fileprivate let memoryCache: NSCache<NSString, Image>
    
    init(moc: NSManagedObjectContext, session: Session, configuration: Configuration) {
        self.imageFetcher = ImageFetcher(session: session, configuration: configuration)
        memoryCache = NSCache<NSString, Image>()
        memoryCache.totalCostLimit = 10000000 //pixel count
        let fileWriter = CacheFileWriter(fetcher: imageFetcher)
        let dbWriter = ImageCacheDBWriter(imageFetcher: imageFetcher, cacheBackgroundContext: moc)
        super.init(dbWriter: dbWriter, fileWriter: fileWriter)
    }
    
    struct FetchResult {
        let data: Data
        let response: URLResponse
    }
    
    private var dataCompletionManager = ImageControllerCompletionManager<ImageControllerDataCompletion>()
    
    //called when saving an image to persistent cache has completed. Hook here to allow additional saving into memoryCache.
    override func finishFileSave(data: Data, mimeType: String?, uniqueKey: CacheController.UniqueKey, url: URL) {
        
        guard let image = self.createImage(data: data, mimeType: mimeType) else {
            return
        }
        
        addToMemoryCache(image, url: url)
    }
    
    // MARK: Errors
    public enum FetchError: Error {
        case dataNotFound
        case invalidOrEmptyURL
        case invalidImageCache
        case invalidResponse
        case duplicateRequest
        case fileError
        case dbError
        case `deinit`
    }
    
    // MARK: Fetching
    
    /// Fetches data from a given URL. Coalesces completion blocks so the same data isn't requested multiple times.
    
    func fetchData(withURL url: URL, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) -> String? {
        
        guard let uniqueKey = imageFetcher.uniqueKeyForURL(url, type: .image) else {
            failure(ImageCacheControllerError.failureGeneratingUniqueKey)
            return nil
        }
        
        let token = UUID().uuidString
        let completion = ImageControllerDataCompletion(success: success, failure: failure)
        dataCompletionManager.add(completion, priority: priority, forIdentifier: uniqueKey, token: token) { [weak self] (isFirst) in
            guard let self = self else {
                return
            }
            guard isFirst else {
                return
            }
            let schemedURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless() as URL
            let acceptAnyContentType = ["Accept": "*/*"]
            let task = self.imageFetcher.dataForURL(schemedURL, persistType: .image, headers: acceptAnyContentType) { [weak self] (result) in
                guard let self = self else {
                    return
                }
                switch result {
                case .failure(let error):
                    guard !self.isCancellationError(error) else {
                        return
                    }
                default:
                    break
                }
                
                self.dataCompletionManager.complete(uniqueKey, enumerator: { (completion) in
                    //DDLogDebug("complete: \(url) \(token)")
                    switch result {
                    case .success(let result):
                        completion.success(result.data, result.response)
                    case .failure(let error):
                        completion.failure(error)
                    }
                })
            }
            
            if let task = task {
                task.priority = priority
                self.dataCompletionManager.add(task, forIdentifier: uniqueKey)
                task.resume()
            }
            
        }
        return token
    }
    
    func fetchData(withURL url: URL, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) {
        let _ = fetchData(withURL: url, priority: URLSessionTask.defaultPriority, failure: failure, success: success)
    }
    
    /// Fetches an image from a given URL. Coalesces completion blocks so the same data isn't requested multiple times.
    public func fetchImage(withURL url: URL?, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) -> String? {
        assert(Thread.isMainThread)
        guard let url = url else {
            failure(FetchError.invalidOrEmptyURL)
            return nil
        }
        if let memoryCachedImage = memoryCachedImage(withURL: url) {
            success(ImageDownload(url: url, image: memoryCachedImage, origin: .memory))
            return nil
        }
        return fetchData(withURL: url, priority: priority, failure: failure) { (data, response) in
            guard let image = self.createImage(data: data, mimeType: response.mimeType) else {
                DispatchQueue.main.async {
                    failure(FetchError.invalidResponse)
                }
                return
            }
            self.addToMemoryCache(image, url: url)
            DispatchQueue.main.async {
                success(ImageDownload(url: url, image: image, origin: .unknown))
            }
        }
    }
    
    public func fetchImage(withURL url: URL?, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) {
        let _ = fetchImage(withURL: url, priority: URLSessionTask.defaultPriority, failure: failure, success: success)
    }
    
   public func cancelFetch(withURL url: URL?, token: String?) {
    
        guard let url = url,
            let uniqueKey = imageFetcher.uniqueKeyForURL(url, type: .image),
            let token = token else {
            return
        }
    
        dataCompletionManager.cancel(uniqueKey, token: token)
    }
    
    /// Populate the cache for a given URL
   public func prefetch(withURL url: URL?) {
        prefetch(withURL: url) { }
    }
    
    /// Populate the cache for a given URL
    public func prefetch(withURL url: URL?, completion: @escaping () -> Void) {
        let _ =  fetchImage(withURL: url, priority: URLSessionTask.lowPriority, failure: { (error) in }) { (download) in }
    }
    
    // MARK: Cache
    
    /// Retrieves the image with the given url from the memory or file cache
    public func cachedImage(withURL url: URL?) -> Image? {
        guard let url = url else {
            return nil
        }
        
        if let memoryCachedImage = memoryCachedImage(withURL: url) {
            return memoryCachedImage
        }
        
        guard let typedImageData = data(withURL: url),
            let data = typedImageData.data,
        let image = createImage(data: data, mimeType: typedImageData.MIMEType) else {
            return nil
        }
        
        addToMemoryCache(image, url: url)
        return image
    }
    
    /// Retrieves the image data from the file cache
    func data(withURL url: URL) -> TypedImageData? {
        guard let response = imageFetcher.cachedResponseForURL(url, type: .image) else {
            return TypedImageData(data: nil, MIMEType: nil)
        }
        
        return TypedImageData(data: response.data, MIMEType: response.response.mimeType)
    }
    
    // MARK: Memory Cache
    
    /// Retrieves the image with the given url from the memory cache
    public func memoryCachedImage(withURL url: URL) -> Image? {
        
        guard let uniqueKey = imageFetcher.uniqueKeyForURL(url, type: .image) else {
            return nil
        }
        
        return memoryCache.object(forKey: uniqueKey as NSString)
    }
    
    func addToMemoryCache(_ image: Image, url: URL) {
        
        guard let uniqueKey = imageFetcher.uniqueKeyForURL(url, type: .image) else {
            return
        }
        
        memoryCache.setObject(image, forKey: (uniqueKey as NSString), cost: Int(image.staticImage.size.width * image.staticImage.size.height))
    }
    
    // MARK: Utilities
    
    private func createImage(data: Data, mimeType: String?) -> Image? {
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
        let image: UIImage
        if let orientation = getUIImageOrientation(from: source, options: options) {
            image = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
        } else {
            image = UIImage(cgImage: cgImage)
        }
        return Image(staticImage: image, animatedImage: nil)
    }
    
    private func getUIImageOrientation(from imageSource: CGImageSource, options: CFDictionary) -> UIImage.Orientation? {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options) as? [String: Any],
            let orientationRawValue = properties[kCGImagePropertyOrientation as String] as? UInt32,
            let cgOrientation = CGImagePropertyOrientation(rawValue: orientationRawValue)
            else {
                return nil
        }
        switch cgOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right:  return .right
        case .rightMirrored: return .rightMirrored
        }
    }
    
    public override func cancelAllTasks() {
        super.cancelAllTasks()
        dataCompletionManager.cancelAll()
    }
}

private extension ImageCacheController {
    func isCancellationError(_ error: Error?) -> Bool {
        return error?.isCancellationError ?? false
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



@objc(WMFTypedImageData)
open class TypedImageData: NSObject {
    @objc public let data:Data?
    @objc public let MIMEType:String?
    
    @objc public init(data data_: Data?, MIMEType type_: String?) {
        data = data_
        MIMEType = type_
    }
}

let WMFExtendedFileAttributeNameMIMEType = "org.wikimedia.MIMEType"
