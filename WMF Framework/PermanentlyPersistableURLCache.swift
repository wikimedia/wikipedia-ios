import Foundation

public struct Header {
    public static let persistentCacheItemType = "Persistent-Cache-Item-Type"
    //public static let persistentCacheETag = "Persistent-Cache-ETag"
    
    //existence of a PersistItemType in a URLRequest header indicates to the system that we want to reference the persistent cache for the use of passing through Etags (If-None-Match) and falling back on a cached response (or other variant of) in the case of an urlSession error.
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
    private let cacheManagedObjectContext = CacheController.backgroundCacheContext
    
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
        return permanentlyCachedResponse(for: request)
    }
    
    
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        super.storeCachedResponse(cachedResponse, for: request)
    }
    
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
        super.storeCachedResponse(cachedResponse, for: dataTask)
    }
}

//MARK: Public - URL Creation

extension PermanentlyPersistableURLCache {
    func urlRequestFromURL(_ url: URL, type: Header.PersistItemType) -> URLRequest {
        
        var request = URLRequest(url: url)
        request.setValue(type.rawValue, forHTTPHeaderField: Header.persistentCacheItemType)
        
        addAdditionalHeadersToURLRequest(&request, type: type)
        
        return request
    }
}

//MARK: Private - URLRequest header creation

private extension PermanentlyPersistableURLCache {
    func addAdditionalHeadersToURLRequest(_ urlRequest: inout URLRequest, type: Header.PersistItemType) {
        
        switch type {
        case .article, .imageInfo:
            addEtagHeaderToURLRequest(&urlRequest, type: type)
        case .image:
            break
        }
    }
    
    func addEtagHeaderToURLRequest(_ urlRequest: inout URLRequest, type: Header.PersistItemType) {

        if let cachedUrlResponse = self.cachedResponse(for: urlRequest)?.response as? HTTPURLResponse {
            for (key, value) in cachedUrlResponse.allHeaderFields {
                if let keyString = key as? String,
                    let valueString = value as? String,
                    keyString == HTTPURLResponse.etagHeaderKey {
                    urlRequest.setValue(valueString, forHTTPHeaderField: HTTPURLResponse.ifNoneMatchHeaderKey)
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
}

private extension PermanentlyPersistableURLCache {
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
        return sizePrefix == NSNotFound ? nil : String(sizePrefix)
    }
    
    func articleVariantForURL(_ url: URL) -> String? {
        #if WMF_APPS_LABS_MOBILE_HTML
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
    
    func imageInfoVariantForURL(_ url: URL) -> String? {
        return nil
    }
}

//MARK: Unique file name and header file name creation

private extension PermanentlyPersistableURLCache {

    func uniqueHeaderFileNameForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        
        guard let itemKey = itemKeyForURL(url, type: type) else {
            return nil
        }
        
        let variant = variantForURL(url, type: type)
        
        return uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
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
    
    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, mimeType: String?, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
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
            CacheFileWriterHelper.saveData(data: data, toNewFileWithKey: contentFileName, mimeType: mimeType) { (result) in
                
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
            CacheFileWriterHelper.saveContent(string, toNewFileName: contentFileName, mimeType: mimeType) { (result) in
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
    func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Bool, Error>) -> Void) {
        
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
        
        CacheFileWriterHelper.copyFile(from: bundledFileURL, toNewFileWithKey: contentFileName, mimeType: mimeType) { (result) in
            switch result {
            case .success, .exists:
                 CacheFileWriterHelper.saveResponseHeader(headerFields: ["Content-Type": mimeType], toNewFileName: headerFileName) { (result) in
                    switch result {
                    case .success, .exists:
                        completion(.success(true))
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
            DDLogDebug("Error removing file: \(error)")
        }
        
        completion()
    }
}

//MARK: Private - Permanent Cache Fetching

private extension PermanentlyPersistableURLCache {
    
    func permanentlyCachedResponse(for request: URLRequest) -> CachedURLResponse? {
        
        //2. else try pulling from Persistent Cache
        if let persistedCachedResponse = persistedResponseWithURLRequest(request) {
            return persistedCachedResponse
        //3. else try pulling a fallback from Persistent Cache
        } else if let moc = cacheManagedObjectContext,
            let fallbackCachedResponse = fallbackPersistedResponse(urlRequest: request, moc: moc) {
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
        
        var allVariantItems = CacheDBWriterHelper.allDownloadedVariantItems(itemKey: itemKey, in: moc)
        
        switch type {
        case .image:
            allVariantItems.sort { (lhs, rhs) -> Bool in

                guard let lhsVariant = lhs.variant,
                    let lhsSize = Int64(lhsVariant),
                    let rhsVariant = rhs.variant,
                    let rhsSize = Int64(rhsVariant) else {
                        return true
                }

                return lhsSize < rhsSize
            }
        case .article, .imageInfo:

            break
        }
        
        if let fallbackItemKey = allVariantItems.first?.key {
            
            let fallbackVariant = allVariantItems.first?.variant
            
            //migrated images do not have urls. defaulting to url passed in here.
            let fallbackURL = allVariantItems.first?.url ?? url
            
            //first see if URLCache has the fallback
            let quickCheckRequest = URLRequest(url: fallbackURL)
            if let response = URLCache.shared.cachedResponse(for: quickCheckRequest) {
                return response
            }
            
            //then see if persistent cache has the fallback
            let request = PersistedResponseRequest.fallbackItemKeyAndVariant(url: fallbackURL, itemKey: fallbackItemKey, variant: fallbackVariant)
            return persistedResponseWithRequest(request)
        }
        
        return nil
    }
}

private extension HTTPURLResponse {
    static let etagHeaderKey = "Etag"
    static let ifNoneMatchHeaderKey = "If-None-Match"
}
