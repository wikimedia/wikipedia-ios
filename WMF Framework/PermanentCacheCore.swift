import Foundation
import CocoaLumberjackSwift

/** The PermanentCacheCore is the lowest layer of the permanent cache.
 *  It serves as a fallback for standard URLCache behavior for PermanentlyPersistableURLCache.
 *  The article and image cache controller subsystems both sit on top of PermanentCacheCore.
 */
class PermanentCacheCore {
    let cacheManagedObjectContext: NSManagedObjectContext
    weak var urlCache: URLCache!

    init(moc: NSManagedObjectContext) {
        cacheManagedObjectContext = moc
    }
    
}

//MARK: Public - Permanent Cache Writing

extension PermanentCacheCore {
    
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
    
    internal func updateCacheWithCachedResponse(_ cachedResponse: CachedURLResponse, request: URLRequest) {
        
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
                urlCache.removeCachedResponse(for: updatingRequest)
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

extension PermanentCacheCore {
    
    internal func permanentlyCachedHeaders(for request: URLRequest) -> [String: String]? {
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
    
    internal func permanentlyCachedResponse(for request: URLRequest) -> CachedURLResponse? {
        
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
    
    private func persistedResponseWithURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? {
        
        guard let url = urlRequest.url,
            let typeRaw = urlRequest.allHTTPHeaderFields?[Header.persistentCacheItemType],
            let type = Header.PersistItemType(rawValue: typeRaw) else {
                return nil
        }
        
        let request = PersistedResponseRequest.urlAndType(url: url, type: type)
        return persistedResponseWithRequest(request)
    }
    
    private func persistedResponseWithRequest(_ request: PersistedResponseRequest) -> CachedURLResponse? {
        
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
    
    private func fallbackPersistedResponse(urlRequest: URLRequest, moc: NSManagedObjectContext) -> CachedURLResponse? {
        
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

//MARK: File Name Uniquing Utilities
// These utilities do not seem to have any dependencies beyond other methods in the class
// They all could potentially be split out into a utility class
// They do depend on the CacheController.ItemKey and Header.PersistItemType types

extension PermanentCacheCore {
    
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

//MARK: Database key and variant creation
// These utilities do not seem to have any dependencies beyond other methods in the class
// They all could potentially be split out into a utility class
// They do depend on the CacheController.ItemKey and Header.PersistItemType types

extension PermanentCacheCore {
    
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

//MARK: Database key and variant support methods
// These utilities do not seem to have any dependencies beyond other methods in the class
// They all could potentially be split out into a utility class
// They do depend on the CacheController.ItemKey and Header.PersistItemType types


private extension PermanentCacheCore {

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
        return url.wmf_languageVariantCode
    }

    func imageInfoVariantForURL(_ url: URL) -> String? {
        return nil
    }
}

//MARK: Private - Helpers
// This utility does not seem to have any dependencies
// It could potentially be split out into a utility class
// It does depend on theHeader.PersistItemType type


private extension PermanentCacheCore {
    func typeFromURLRequest(urlRequest: URLRequest) -> Header.PersistItemType? {
        guard let typeRaw = urlRequest.allHTTPHeaderFields?[Header.persistentCacheItemType],
            let type = Header.PersistItemType(rawValue: typeRaw) else {
                return nil
        }
        
        return type
    }
}

