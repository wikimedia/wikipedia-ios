
import Foundation

final class ImageCacheController: CacheController {
    
    public static let shared: ImageCacheController = {
        let imageFetcher = ImageFetcher()
        let imageCacheKeyGenerator = ImageCacheKeyGenerator.self
        
        let cacheBackgroundContext = CacheController.backgroundCacheContext
        
        let imageFileWriter = CacheFileWriter(fetcher: imageFetcher, cacheBackgroundContext: cacheBackgroundContext, cacheKeyGenerator: imageCacheKeyGenerator)

        let imageDBWriter = ImageCacheDBWriter(imageFetcher: imageFetcher, cacheBackgroundContext: cacheBackgroundContext)

        return ImageCacheController(dbWriter: imageDBWriter, fileWriter: imageFileWriter, imageFetcher: imageFetcher, cacheKeyGenerator: imageCacheKeyGenerator)
    }()
    
    let cacheKeyGenerator = ImageCacheKeyGenerator.self
    
    //batch inserts to db and selectively decides which file variant to download. Used when inserting multiple image urls from media-list endpoint via ArticleCacheController.
    
    // MARK: Permanent Cache
    func add(urls: [URL], groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {

        //tonitodo: DRY gatekeeper logic with superclass
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
    
    init(dbWriter: CacheDBWriting, fileWriter: CacheFileWriter, imageFetcher: ImageFetcher, cacheKeyGenerator: CacheKeyGenerating.Type) {
        self.imageFetcher = imageFetcher
        memoryCache = NSCache<NSString, Image>()
        memoryCache.totalCostLimit = 10000000 //pixel count
        super.init(dbWriter: dbWriter, fileWriter: fileWriter, cacheKeyGenerator: cacheKeyGenerator)
    }
    
    struct FetchResult {
        let data: Data
        let response: URLResponse
    }
    
    enum ImageCacheControllerError: Error {
        case unableToDetermineItemKey
    }
    
    private var dataCompletionManager = ImageControllerCompletionManager<ImageControllerDataCompletion>()
    
    //called when saving an image to persistent cache has completed. Hook here to allow additional saving into memoryCache.
    override func finishFileSave(data: Data, mimeType: String?, uniqueKey: CacheController.UniqueKey, url: URL) {
        
        guard let image = self.createImage(data: data, mimeType: mimeType) else {
            return
        }
        
        addToMemoryCache(image, url: url)
    }
    
    // MARK: Fetching
    
    /// Fetches data from a given URL. Coalesces completion blocks so the same data isn't requested multiple times.
    
    func fetchData(withURL url: URL, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (Data, URLResponse) -> Void) -> String? {
        
        guard let itemKey =  cacheKeyGenerator.itemKeyForURL(url) else { failure(ImageCacheControllerError.unableToDetermineItemKey)
            return nil
        }
        
        let variant = cacheKeyGenerator.variantForURL(url)
        let uniqueKey = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant)
        
        let token = UUID().uuidString
        let completion = ImageControllerDataCompletion(success: success, failure: failure)
        dataCompletionManager.add(completion, priority: priority, forIdentifier: uniqueKey, token: token) { (isFirst) in
            guard isFirst else {
                return
            }
            let schemedURL = (url as NSURL).wmf_urlByPrependingSchemeIfSchemeless() as URL
            
            let urlRequest = self.imageFetcher.request(for: schemedURL)
            let task = self.imageFetcher.data(for: urlRequest) { (result) in
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
    func fetchImage(withURL url: URL?, priority: Float, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) -> String? {
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
    
    func fetchImage(withURL url: URL?, failure: @escaping (Error) -> Void, success: @escaping (ImageDownload) -> Void) {
        let _ = fetchImage(withURL: url, priority: URLSessionTask.defaultPriority, failure: failure, success: success)
    }
    
   func cancelFetch(withURL url: URL?, token: String?) {
        guard let url = url, let token = token else {
            return
        }
        
        guard let itemKey = cacheKeyGenerator.itemKeyForURL(url) else {
            return
        }
        
        let variant = cacheKeyGenerator.variantForURL(url)

        let uniqueKey = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant)
        dataCompletionManager.cancel(uniqueKey, token: token)
    }
    
    /// Populate the cache for a given URL
   func prefetch(withURL url: URL?) {
        prefetch(withURL: url) { }
    }
    
    /// Populate the cache for a given URL
    func prefetch(withURL url: URL?, completion: @escaping () -> Void) {
        let _ =  fetchImage(withURL: url, priority: URLSessionTask.lowPriority, failure: { (error) in }) { (download) in }
    }
    
    // MARK: Cache
    
    func cachedImage(withURL url: URL?) -> Image? {
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
    
    func data(withURL url: URL) -> TypedImageData? {
        let request = imageFetcher.request(for: url)
        guard let response = responseFromPersistentCacheOrFallbackIfNeeded(request: request, cacheKeyGenerator: cacheKeyGenerator) else {
            return TypedImageData(data: nil, MIMEType: nil)
        }
        
        //tonitodo: sort out these mime types
        return TypedImageData(data: response.data, MIMEType: response.response.mimeType)
    }
    
    // MARK: Memory Cache
    
    func memoryCachedImage(withURL url: URL) -> Image? {
        
        guard let itemKey = cacheKeyGenerator.itemKeyForURL(url) else {
            return nil
        }
        let variant = cacheKeyGenerator.variantForURL(url)
        let uniqueKey = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant) as NSString
        
        return memoryCache.object(forKey: uniqueKey)
    }
    
    func addToMemoryCache(_ image: Image, url: URL) {
        guard let itemKey = cacheKeyGenerator.itemKeyForURL(url) else {
            return
        }
        let variant = cacheKeyGenerator.variantForURL(url)
        let uniqueKey = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant) as NSString
        memoryCache.setObject(image, forKey: uniqueKey, cost: Int(image.staticImage.size.width * image.staticImage.size.height))
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
