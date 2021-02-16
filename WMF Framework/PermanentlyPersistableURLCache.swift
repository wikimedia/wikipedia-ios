import Foundation
import CocoaLumberjackSwift

public struct Header {
    public static let persistentCacheItemType = "Persistent-Cache-Item-Type"
    
    //existence of a PersistItemType in a URLRequest header indicates to the system that we want to reference the persistent cache for the use of passing through Etags (If-None-Match) and falling back on a cached response (or other variant of) in the case of a urlSession error.
    //pass PersistItemType header value urlRequest headers to gain different behaviors on how a request interacts with the cache, such as:
        //for reading:
        //article & imageInfo both set If-None-Match request header value based on previous cached E-tags in response headers
        //there might be different fallback ordering logic if that particular variant is not cached but others are (image prioritizes by variant size, article by device language preferences)
        //for writing:
        //.image Cache database keys are saved as [host + "__" + imageName] pattern, variants = size prefix in url
        //article Cache database keys are saved as .wmf_databaseURL, variants = detected preferred language variant.
        //imageInfo Cache database keys are malformed with wmf_databaseURL, so it is saved as absoluteString.precomposedStringWithCanonicalMapping, variant = nil.
    public enum PersistItemType: String {
        case image = "Image"
        case article = "Article"
        case imageInfo = "ImageInfo"
    }
}

class PermanentlyPersistableURLCache: URLCache {
    let cacheManagedObjectContext: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        cacheManagedObjectContext = moc
        super.init(memoryCapacity: URLCache.shared.memoryCapacity, diskCapacity: URLCache.shared.diskCapacity, diskPath: nil)
    }
    
//MARK: Public - Overrides
    
    override func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        super.getCachedResponse(for: dataTask) { (response) in
            if let response = response {
                completionHandler(response)
                return
            }
            guard let request = dataTask.originalRequest else {
                completionHandler(nil)
                return
            }
            completionHandler(self.permanentlyCachedResponse(for: request))
        }
        
    }
    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        if let response = super.cachedResponse(for: request) {
            return response
        }
        let cachedResponse = permanentlyCachedResponse(for: request)
        return cachedResponse
    }
    
    
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        super.storeCachedResponse(cachedResponse, for: request)
        
        updateCacheWithCachedResponse(cachedResponse, request: request)
    }
    
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
        super.storeCachedResponse(cachedResponse, for: dataTask)
        
        if let request = dataTask.originalRequest {
            updateCacheWithCachedResponse(cachedResponse, request: request)
        }
    }
}

//MARK: Public - URLRequest Creation

extension PermanentlyPersistableURLCache {
    func urlRequestFromURL(_ url: URL, type: Header.PersistItemType, cachePolicy: WMFCachePolicy? = nil) -> URLRequest {
        
        var request = URLRequest(url: url)
        
        let typeHeaders = typeHeadersForType(type)
        
        for (key, value) in typeHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let additionalHeaders = additionalHeadersForType(type, urlRequest: request)
        
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let cachePolicy = cachePolicy {
            switch cachePolicy {
            case .foundation(let cachePolicy):
                request.cachePolicy = cachePolicy
                request.prefersPersistentCacheOverError = true
            case .noPersistentCacheOnError:
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.prefersPersistentCacheOverError = false
            }
        }
        
        return request
    }
    
    func typeHeadersForType(_ type: Header.PersistItemType) -> [String: String] {
        return [Header.persistentCacheItemType: type.rawValue]
    }
    
    func additionalHeadersForType(_ type: Header.PersistItemType, urlRequest: URLRequest) -> [String: String] {
        
        var headers: [String: String] = [:]
        
        //add If-None-Match, otherwise it will not be populated if URLCache.shared is cleared but persistent cache exists.
        switch type {
        case .article, .imageInfo:
            guard let cachedHeaders = permanentlyCachedHeaders(for: urlRequest) else {
                break
            }
            headers[URLRequest.ifNoneMatchHeaderKey] = cachedHeaders[HTTPURLResponse.etagHeaderKey]
        case .image:
            break
        }
        
        return headers
    }
    
    func isCachedWithURLRequest(_ urlRequest: URLRequest, completion: @escaping (Bool) -> Void) {
        guard let itemKey = itemKeyForURLRequest(urlRequest) else {
            completion(false)
            return
        }
        let moc = cacheManagedObjectContext
        let variant = variantForURLRequest(urlRequest)
        
        return CacheDBWriterHelper.isCached(itemKey: itemKey, variant: variant, in: moc, completion: completion)
    }
}

//MARK: Private - URLRequest header creation

private extension PermanentlyPersistableURLCache {
    
    func addEtagHeaderToURLRequest(_ urlRequest: inout URLRequest, type: Header.PersistItemType) {

        if let cachedUrlResponse = self.cachedResponse(for: urlRequest)?.response as? HTTPURLResponse {
            for (key, value) in cachedUrlResponse.allHeaderFields {
                if let keyString = key as? String,
                    let valueString = value as? String,
                    keyString == HTTPURLResponse.etagHeaderKey {
                    urlRequest.setValue(valueString, forHTTPHeaderField: URLRequest.ifNoneMatchHeaderKey)
                }
            }
        }
    }
}

//MARK: Database key and variant creation

extension PermanentlyPersistableURLCache {
    
    func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String? {
        guard let url = urlRequest.url,
            let type = typeFromURLRequest(urlRequest: urlRequest) else {
            return nil
        }
        
        return itemKeyForURL(url, type: type)
    }
    
    func variantForURLRequest(_ urlRequest: URLRequest) -> String? {
        guard let url = urlRequest.url,
            let type = typeFromURLRequest(urlRequest: urlRequest) else {
            return nil
        }
        
        return variantForURL(url, type: type)
    }
    
    func itemKeyForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        switch type {
        case .image:
            return imageItemKeyForURL(url)
        case .article:
            return articleItemKeyForURL(url)
        case .imageInfo:
            return imageInfoItemKeyForURL(url)
        }
    }
    
    func variantForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        switch type {
        case .image:
            return imageVariantForURL(url)
        case .article:
            return articleVariantForURL(url)
        case .imageInfo:
            return imageInfoVariantForURL(url)
        }
    }
}

private extension PermanentlyPersistableURLCache {

    func imageItemKeyForURL(_ url: URL) -> String? {
        guard let host = url.host, let imageName = WMFParseImageNameFromSourceURL(url) else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
        return (host + "__" + imageName).precomposedStringWithCanonicalMapping
    }
    
    func articleItemKeyForURL(_ url: URL) -> String? {
        return url.wmf_databaseKey
    }
    
    func imageInfoItemKeyForURL(_ url: URL) -> String? {
        return url.absoluteString.precomposedStringWithCanonicalMapping;
    }
    
    func imageVariantForURL(_ url: URL) -> String? {
        let sizePrefix = WMFParseSizePrefixFromSourceURL(url)
        return sizePrefix == NSNotFound ? "0" : String(sizePrefix)
    }
    
    func articleVariantForURL(_ url: URL) -> String? {
        
        // If the language variants feature is not turned on, use the old behavior.
        // This ensures the existing language variant behavior continues working.
        // This guard statment can be removed when languageVariantsEnabled is removed.
        guard WikipediaLookup.languageVariantsEnabled else {
            #if WMF_APPS_LABS_PAGE_CONTENT_SERVICE || WMF_LOCAL_PAGE_CONTENT_SERVICE
                if let pathComponents = (url as NSURL).pathComponents,
                pathComponents.count >= 2 {
                    let newHost = pathComponents[1]
                    let hostComponents = newHost.components(separatedBy: ".")
                    if hostComponents.count < 3 {
                        return Locale.preferredWikipediaLanguageVariant(for: url)
                    } else {
                        let potentialLanguage = hostComponents[0]
                        if potentialLanguage == "m" {
                            return Locale.preferredWikipediaLanguageVariant(for: url)
                        } else {
                            return Locale.preferredWikipediaLanguageVariant(for: url, urlLanguage: potentialLanguage)
                        }
                    }
                }
            
                return Locale.preferredWikipediaLanguageVariant(for: url)
            #else
                return Locale.preferredWikipediaLanguageVariant(for: url)
            #endif
        }
        
        return url.wmf_languageVariantCode
    }
    
    func imageInfoVariantForURL(_ url: URL) -> String? {
        return nil
    }
}

extension PermanentlyPersistableURLCache {
    
    func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String {
        let fileName = uniqueFileNameForItemKey(itemKey, variant: variant)
        
        return fileName + "__Header"
    }
    
    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String? {
        
        guard let url = urlRequest.url,
            let type = typeFromURLRequest(urlRequest: urlRequest) else {
            return nil
        }
        
        return uniqueFileNameForURL(url, type: type)
    }
    
    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String {
        
        guard let variant = variant else {
            let fileName = itemKey.precomposedStringWithCanonicalMapping
            return fileName.sha256 ?? fileName
        }
        
        let fileName = "\(itemKey)__\(variant)".precomposedStringWithCanonicalMapping
        return fileName.sha256 ?? fileName
    }
    
    func uniqueFileNameForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        
        guard let itemKey = itemKeyForURL(url, type: type) else {
            return nil
        }
        
        let variant = variantForURL(url, type: type)
        
        return uniqueFileNameForItemKey(itemKey, variant: variant)
    }
    
    func uniqueHeaderFileNameForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        
        guard let itemKey = itemKeyForURL(url, type: type) else {
            return nil
        }
        
        let variant = variantForURL(url, type: type)
        
        return uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
    }
}

//MARK: Private - Helpers

private extension PermanentlyPersistableURLCache {
    func typeFromURLRequest(urlRequest: URLRequest) -> Header.PersistItemType? {
        guard let typeRaw = urlRequest.allHTTPHeaderFields?[Header.persistentCacheItemType],
            let type = Header.PersistItemType(rawValue: typeRaw) else {
                return nil
        }
        
        return type
    }
}

//MARK: Public - Permanent Cache Writing

enum PermanentlyPersistableURLCacheError: Error {
    case unableToDetermineURLFromRequest
    case unableToDetermineTypeFromRequest
    case unableToDetermineHeaderOrContentFileName
}

public enum CacheResponseContentType {
    case data(Data)
    case string(String)
}

extension PermanentlyPersistableURLCache {
    
    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        guard let url = urlRequest.url else {
            failure(PermanentlyPersistableURLCacheError.unableToDetermineURLFromRequest)
            return
        }
            
        guard let type = typeFromURLRequest(urlRequest: urlRequest) else {
                failure(PermanentlyPersistableURLCacheError.unableToDetermineTypeFromRequest)
            return
        }
        
        guard let headerFileName = uniqueHeaderFileNameForURL(url, type: type),
        let contentFileName = uniqueFileNameForURL(url, type: type) else {
            failure(PermanentlyPersistableURLCacheError.unableToDetermineHeaderOrContentFileName)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        var headerSaveError: Error? = nil
        var contentSaveError: Error? = nil
        
        CacheFileWriterHelper.saveResponseHeader(httpUrlResponse: httpUrlResponse, toNewFileName: headerFileName) { (result) in
            
            defer {
                dispatchGroup.leave()
            }
            
            switch result {
            case .success, .exists:
                break
            case .failure(let error):
                headerSaveError = error
            }
        }
        
        switch content {
        case .data((let data)):
            dispatchGroup.enter()
            CacheFileWriterHelper.saveData(data: data, toNewFileWithKey: contentFileName) { (result) in
                
                defer {
                    dispatchGroup.leave()
                }
                
                switch result {
                case .success, .exists:
                    break
                case .failure(let error):
                    contentSaveError = error
                }
            }
        case .string(let string):
            dispatchGroup.enter()
            CacheFileWriterHelper.saveContent(string, toNewFileName: contentFileName) { (result) in
                defer {
                    dispatchGroup.leave()
                }
                
                switch result {
                case .success, .exists:
                    break
                case .failure(let error):
                    contentSaveError = error
                }
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.global(qos: .default)) { [headerSaveError, contentSaveError] in
            
            if let contentSaveError = contentSaveError {
                self.remove(fileName: headerFileName) {
                    failure(contentSaveError)
                }
                return
            }
            
            if let headerSaveError = headerSaveError {
                self.remove(fileName: contentFileName) {
                    failure(headerSaveError)
                }
                return
            }
            
            success()
        }
    }
    
    //Bundled migration only - copies files into cache
    func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let url = urlRequest.url else {
            completion(.failure(PermanentlyPersistableURLCacheError.unableToDetermineURLFromRequest))
            return
        }
            
        guard let type = typeFromURLRequest(urlRequest: urlRequest) else {
            completion(.failure(PermanentlyPersistableURLCacheError.unableToDetermineTypeFromRequest))
            return
        }
        
        guard let headerFileName = uniqueHeaderFileNameForURL(url, type: type),
        let contentFileName = uniqueFileNameForURL(url, type: type) else {
            completion(.failure(PermanentlyPersistableURLCacheError.unableToDetermineHeaderOrContentFileName))
            return
        }
        
        CacheFileWriterHelper.copyFile(from: bundledFileURL, toNewFileWithKey: contentFileName) { (result) in
            switch result {
            case .success, .exists:
                 CacheFileWriterHelper.saveResponseHeader(headerFields: ["Content-Type": mimeType], toNewFileName: headerFileName) { (result) in
                    switch result {
                    case .success, .exists:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func remove(fileName: String, completion: () -> Void) {
        
        //remove from file system
        let fileURL = CacheFileWriterHelper.fileURL(for: fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch let error as NSError {
            DDLogError("Error removing file: \(error)")
        }
        
        completion()
    }
    
    private func updateCacheWithCachedResponse(_ cachedResponse: CachedURLResponse, request: URLRequest) {
        
        func customCacheUpdatingItemKeyForURLRequest(_ urlRequest: URLRequest) -> String? {
            
            //this inner method is a workaround to allow the mobile-html URLRequest with a revisionID in the url to update the cached response under the revisionless url.
            //we intentionally don't want to modify the itemKeyForURLRequest(_ urlRequest: URLRequest) method to keep this a lighter touch
            
            guard let url = urlRequest.customCacheUpdatingURL ?? urlRequest.url,
                let type = typeFromURLRequest(urlRequest: urlRequest) else {
                return nil
            }
            
            return itemKeyForURL(url, type: type)
        }
        
        func clearCustomCacheUpdatingResponseFromFoundation(with urlRequest: URLRequest) {
            
            //If we have a custom cache url to update, we need to remove that from foundation's URLCache, otherwise that
            //will still take over even if we have updated the saved article cache.
            
            if let customCacheUpdatingURL = urlRequest.customCacheUpdatingURL {
                let updatingRequest = URLRequest(url: customCacheUpdatingURL)
                removeCachedResponse(for: updatingRequest)
            }
        }

        let isArticleOrImageInfoRequest: Bool
        if let typeRaw = request.allHTTPHeaderFields?[Header.persistentCacheItemType],
            let type = Header.PersistItemType(rawValue: typeRaw),
            (type == .article || type == .imageInfo) {
            isArticleOrImageInfoRequest = true
        } else {
            isArticleOrImageInfoRequest = false
        }
        
        //we only want to update specific variant for image types
        //for articles and imageInfo's it's okay to update the alternative language variants in the cache.
        let variant: String? = isArticleOrImageInfoRequest ? nil : variantForURLRequest(request)
        
        clearCustomCacheUpdatingResponseFromFoundation(with: request)
        
        guard let itemKey = customCacheUpdatingItemKeyForURLRequest(request),
            let httpResponse = cachedResponse.response as? HTTPURLResponse,
            httpResponse.statusCode == 200 else {
            return
        }
        
        let moc = cacheManagedObjectContext
        
        CacheDBWriterHelper.isCached(itemKey: itemKey, variant: variant, in: moc, completion: { (isCached) in
            guard isCached else {
                return
            }

            let cachedHeaders = self.permanentlyCachedHeaders(for: request)
            let cachedETag = cachedHeaders?[HTTPURLResponse.etagHeaderKey]
            let responseETag = httpResponse.allHeaderFields[HTTPURLResponse.etagHeaderKey] as? String
            guard cachedETag == nil || cachedETag != responseETag else {
                return
            }
            
            let headerFileName: String
            let contentFileName: String
            
            if isArticleOrImageInfoRequest,
                let topVariant = CacheDBWriterHelper.allDownloadedVariantItems(itemKey: itemKey, in: moc).first {
                
                headerFileName = self.uniqueHeaderFileNameForItemKey(itemKey, variant: topVariant.variant)
                contentFileName = self.uniqueFileNameForItemKey(itemKey, variant: topVariant.variant)
                
            } else {
                headerFileName = self.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
                contentFileName = self.uniqueFileNameForItemKey(itemKey, variant: variant)
            }
            
            CacheFileWriterHelper.replaceResponseHeaderWithURLResponse(httpResponse, atFileName: headerFileName) { (result) in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    DDLogError("Failed updating cached header file: \(error)")
                case .exists:
                    assertionFailure("This shouldn't happen.")
                    break
                }
            }
            
            CacheFileWriterHelper.replaceFileWithData(cachedResponse.data, fileName: contentFileName) { (result) in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    DDLogError("Failed updating cached content file: \(error)")
                case .exists:
                    assertionFailure("This shouldn't happen.")
                    break
                }
            }
        })

    }
}

//MARK: Private - Permanent Cache Fetching

private extension PermanentlyPersistableURLCache {
    
    func permanentlyCachedHeaders(for request: URLRequest) -> [String: String]? {
        guard let url = request.url,
            let typeRaw = request.allHTTPHeaderFields?[Header.persistentCacheItemType],
            let type = Header.PersistItemType(rawValue: typeRaw) else {
                return nil
        }
        guard let responseHeaderFileName = uniqueHeaderFileNameForURL(url, type: type) else {
            return nil
        }
        guard let responseHeaderData = FileManager.default.contents(atPath: CacheFileWriterHelper.fileURL(for: responseHeaderFileName).path) else {
            return nil
        }
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(responseHeaderData) as? [String: String]
    }
    
    func permanentlyCachedResponse(for request: URLRequest) -> CachedURLResponse? {
        
        //1. try pulling from Persistent Cache
        if let persistedCachedResponse = persistedResponseWithURLRequest(request) {
            return persistedCachedResponse
        //2. else try pulling a fallback from Persistent Cache
        } else if let fallbackCachedResponse = fallbackPersistedResponse(urlRequest: request, moc: cacheManagedObjectContext) {
            return fallbackCachedResponse
        }
        
        return nil
    }
    
    enum PersistedResponseRequest {
        case urlAndType(url: URL, type: Header.PersistItemType)
        case fallbackItemKeyAndVariant(url: URL, itemKey: String, variant: String?)
    }
    
    func persistedResponseWithURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? {
        
        guard let url = urlRequest.url,
            let typeRaw = urlRequest.allHTTPHeaderFields?[Header.persistentCacheItemType],
            let type = Header.PersistItemType(rawValue: typeRaw) else {
                return nil
        }
        
        let request = PersistedResponseRequest.urlAndType(url: url, type: type)
        return persistedResponseWithRequest(request)
    }
    
    func persistedResponseWithRequest(_ request: PersistedResponseRequest) -> CachedURLResponse? {
        
        let maybeResponseFileName: String?
        let maybeResponseHeaderFileName: String?
        let url: URL
        
        switch request {
        case .urlAndType(let inURL, let type):
            url = inURL
            maybeResponseFileName = uniqueFileNameForURL(url, type: type)
            maybeResponseHeaderFileName = uniqueHeaderFileNameForURL(url, type: type)
        case .fallbackItemKeyAndVariant(let inURL, let itemKey, let variant):
            url = inURL
            maybeResponseFileName = uniqueFileNameForItemKey(itemKey, variant: variant)
            maybeResponseHeaderFileName = uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
        }
        
        guard let responseFileName = maybeResponseFileName,
            let responseHeaderFileName = maybeResponseHeaderFileName else {
                return nil
        }
        
        //assert(!Thread.isMainThread)
        
        guard let responseData = FileManager.default.contents(atPath: CacheFileWriterHelper.fileURL(for: responseFileName).path) else {
            return nil
        }

        guard let responseHeaderData = FileManager.default.contents(atPath: CacheFileWriterHelper.fileURL(for: responseHeaderFileName).path) else {
            
            return nil
        }
    
        var responseHeaders: [String: String]?
        do {
            if let unarchivedHeaders = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(responseHeaderData) as? [String: String] {
                responseHeaders = unarchivedHeaders
            }
        } catch {
            
        }
        
        if let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: responseHeaders) {
            return CachedURLResponse(response: httpResponse, data: responseData)
        }
        
        return nil
    }
    
    func fallbackPersistedResponse(urlRequest: URLRequest, moc: NSManagedObjectContext) -> CachedURLResponse? {
        
        guard let url = urlRequest.url,
            let typeRaw = urlRequest.allHTTPHeaderFields?[Header.persistentCacheItemType],
            let type = Header.PersistItemType(rawValue: typeRaw),
            let itemKey = itemKeyForURL(url, type: type) else {
                return nil
        }
        
        //lookup fallback itemKey/variant in DB (language fallback logic for article item type, size fallback logic for image item type)

        var response: CachedURLResponse? = nil
        moc.performAndWait {
            var allVariantItems = CacheDBWriterHelper.allDownloadedVariantItems(itemKey: itemKey, in: moc)
            
            switch type {
            case .image:
                allVariantItems.sortAsImageCacheItems()
            case .article, .imageInfo:
                break
            }
            
            if let fallbackItemKey = allVariantItems.first?.key {
                
                let fallbackVariant = allVariantItems.first?.variant
                
                //migrated images do not have urls. defaulting to url passed in here.
                let fallbackURL = allVariantItems.first?.url ?? url
                
                //first see if URLCache has the fallback
                let quickCheckRequest = URLRequest(url: fallbackURL)
                if let systemCachedResponse = URLCache.shared.cachedResponse(for: quickCheckRequest) {
                    response = systemCachedResponse
                }
                
                //then see if persistent cache has the fallback
                let request = PersistedResponseRequest.fallbackItemKeyAndVariant(url: fallbackURL, itemKey: fallbackItemKey, variant: fallbackVariant)
                response = persistedResponseWithRequest(request)
            }
        }
        
        return response
    }
}

public extension HTTPURLResponse {
    static let etagHeaderKey = "Etag"
    static let varyHeaderKey = "Vary"
    static let acceptLanguageHeaderValue = "Accept-Language"
}

public extension URLRequest {
    static let ifNoneMatchHeaderKey = "If-None-Match"
    static let customCachePolicyHeaderKey = "Custom-Cache-Policy"
    static let customCacheUpdatingURL = "Custom-Cache-Updating-URL"
    
    var prefersPersistentCacheOverError: Bool {
        get {
            if let customCachePolicyValue = allHTTPHeaderFields?[URLRequest.customCachePolicyHeaderKey],
                let intCustomCachePolicyValue = UInt(customCachePolicyValue),
                intCustomCachePolicyValue == WMFCachePolicy.noPersistentCacheOnError.rawValue {
                return false
            }
            
            return true
        }
        set {
            let value = newValue ? nil : String(WMFCachePolicy.noPersistentCacheOnError.rawValue)
            setValue(value, forHTTPHeaderField: URLRequest.customCachePolicyHeaderKey)
        }
        
    }
    
    //if you need the response to this request written to the cache stored at a different url, set this value
    var customCacheUpdatingURL: URL? {
        get {
            guard let urlString = allHTTPHeaderFields?[URLRequest.customCacheUpdatingURL] else {
                return nil
            }
            return URL(string: urlString)
        }
        set {
            setValue(newValue?.absoluteString, forHTTPHeaderField: URLRequest.customCacheUpdatingURL)
        }
    }
}

public extension Array where Element == CacheController.ItemKeyAndVariant {
    mutating func sortAsImageItemKeyAndVariants() {
        sort { (lhs, rhs) -> Bool in

            guard let lhsVariant = lhs.variant,
                let lhsSize = Int64(lhsVariant),
                let rhsVariant = rhs.variant,
                let rhsSize = Int64(rhsVariant) else {
                    return true
            }
            // 0 is original so treat it as larger than others
            if rhsSize == 0 {
                return true
            } else if lhsSize == 0 {
                return false
            }
            return lhsSize < rhsSize
        }
    }
}

public extension Array where Element: CacheItem {
    mutating func sortAsImageCacheItems() {
        sort { (lhs, rhs) -> Bool in

            guard let lhsVariant = lhs.variant,
                let lhsSize = Int64(lhsVariant),
                let rhsVariant = rhs.variant,
                let rhsSize = Int64(rhsVariant) else {
                    return true
            }
            // 0 is original so treat it as larger than others
            if rhsSize == 0 {
                return true
            } else if lhsSize == 0 {
                return false
            }
            return lhsSize < rhsSize
        }
    }
}
