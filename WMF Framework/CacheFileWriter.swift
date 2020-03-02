
import Foundation

enum CacheFileWriterError: Error {
    case missingTemporaryFileURL
    case missingHeaderItemKey
    case missingHTTPResponse
    case unableToDetermineSiteURLFromMigration
    case unexpectedFetcherTypeForBundledMigration
    case unableToDetermineBundledOfflineURLS
    case failureToSaveBundledFiles
    case unableToPullCachedDataFromNotModified
}

enum CacheFileWriterAddResult {
    case success(data: Data, mimeType: String?)
    case failure(Error)
}

enum CacheFileWriterRemoveResult {
    case success
    case failure(Error)
}

final class CacheFileWriter: CacheTaskTracking {

    private let fetcher: CacheFetching
    private let cacheKeyGenerator: CacheKeyGenerating.Type
    private let cacheBackgroundContext: NSManagedObjectContext
    
    lazy private var baseCSSFileURL: URL = {
        URL(fileURLWithPath: WikipediaAppUtils.assetsPath())
            .appendingPathComponent("pcs-html-converter", isDirectory: true)
            .appendingPathComponent("baseCSS.css", isDirectory: false)
    }()

    lazy private var pcsCSSFileURL: URL = {
        URL(fileURLWithPath: WikipediaAppUtils.assetsPath())
            .appendingPathComponent("pcs-html-converter", isDirectory: true)
            .appendingPathComponent("pcsCSS.css", isDirectory: false)
    }()

    lazy private var pcsJSFileURL: URL = {
        URL(fileURLWithPath: WikipediaAppUtils.assetsPath())
            .appendingPathComponent("pcs-html-converter", isDirectory: true)
            .appendingPathComponent("pcsJS.js", isDirectory: false)
    }()
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(fetcher: CacheFetching,
                       cacheBackgroundContext: NSManagedObjectContext,
                       cacheKeyGenerator: CacheKeyGenerating.Type) {
        self.fetcher = fetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.cacheKeyGenerator = cacheKeyGenerator
        
        do {
            try FileManager.default.createDirectory(at: CacheController.cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogError("Error creating permanent cache: \(error)")
        }
    }
    
    func add(groupKey: String, urlRequest: URLRequest, completion: @escaping (CacheFileWriterAddResult) -> Void) {
        
        guard let url = urlRequest.url,
            let itemKey = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey] else {
            completion(.failure(CacheFileWriterError.missingHeaderItemKey))
            return
        }
        
        let variant = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant]
        let fileName = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant)
        let headerFileName = cacheKeyGenerator.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
        
        let untrackKey = UUID().uuidString
        let task = fetcher.data(for: urlRequest) { (response) in
            
            defer {
                self.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            switch response {
            case .success(let result):
                
                guard let httpUrlResponse = result.response as? HTTPURLResponse else {
                    completion(.failure(CacheFileWriterError.missingHTTPResponse))
                    return
                }
                
                let dispatchGroup = DispatchGroup()
                
                dispatchGroup.enter()
                var responseHeaderSaveError: Error? = nil
                var responseSaveError: Error? = nil
                
                CacheFileWriterHelper.saveResponseHeader(httpUrlResponse: httpUrlResponse, toNewFileName: headerFileName) { (result) in
                    
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    switch result {
                    case .success, .exists:
                        break
                    case .failure(let error):
                        responseHeaderSaveError = error
                    }
                }
                
                dispatchGroup.enter()
                CacheFileWriterHelper.saveData(data: result.data, toNewFileWithKey: fileName, mimeType: result.response.mimeType) { (result) in
                    
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    switch result {
                    case .success, .exists:
                        break
                    case .failure(let error):
                        responseSaveError = error
                    }
                }
                
                dispatchGroup.notify(queue: DispatchQueue.global(qos: .default)) { [responseHeaderSaveError, responseSaveError] in
                    
                    if let responseSaveError = responseSaveError {
                        self.remove(fileName: fileName) { (_) in
                            completion(.failure(responseSaveError))
                        }
                        return
                    }
                    
                    if let responseHeaderSaveError = responseHeaderSaveError {
                        self.remove(fileName: fileName) { (_) in
                            completion(.failure(responseHeaderSaveError))
                        }
                        return
                    }
                    
                    completion(.success(data: result.data, mimeType: result.response.mimeType))
                }
                
                
            case .failure(let error):
                switch error as? RequestError {
                case .notModified:
                    //pull cached data to return
                    let response = URLCache.shared.cachedResponse(for: urlRequest) ?? CacheProviderHelper.persistedCacheResponse(url: url, itemKey: itemKey, variant: variant, cacheKeyGenerator: self.cacheKeyGenerator)
                    if let data = response?.data {
                        let mimeType = response?.response.mimeType
                        completion(.success(data: data, mimeType: mimeType))
                    } else {
                        completion(.failure(CacheFileWriterError.unableToPullCachedDataFromNotModified))
                    }
                    
                default:
                    DDLogError("Error downloading data for offline: \(error)\n\(String(describing: response))")
                    completion(.failure(error))
                }
                return
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func remove(fileName: String, completion: @escaping (CacheFileWriterRemoveResult) -> Void) {
        
        var responseHeaderRemoveError: Error? = nil
        var responseRemoveError: Error? = nil

        //remove response from file system
        let responseCachedFileURL = CacheFileWriterHelper.fileURL(for: fileName)
        do {
            try FileManager.default.removeItem(at: responseCachedFileURL)
        } catch let error as NSError {
            if !(error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError) {
               responseRemoveError = error
            }
        }
        
        //remove response header from file system
        let responseHeaderCachedFileURL = CacheFileWriterHelper.fileURL(for: fileName)
        do {
            try FileManager.default.removeItem(at: responseHeaderCachedFileURL)
        } catch let error as NSError {
            if !(error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError) {
               responseHeaderRemoveError = error
            }
        }
        
        if let responseHeaderRemoveError = responseHeaderRemoveError {
            completion(.failure(responseHeaderRemoveError))
            return
        }
        
        if let responseRemoveError = responseRemoveError {
            completion(.failure(responseRemoveError))
            return
        }
        
        completion(.success)
    }
}

//MARK: Migration

extension CacheFileWriter {
    
    func addMobileHtmlContentForMigration(content: String, urlRequest: URLRequest, mimeType: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        guard let itemKey =  urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey] else {
                failure(CacheFileWriterError.missingHeaderItemKey)
                return
        }
        
        let variant = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant]
        let fileName = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant)
        
        //artificially create and save mobile-html header
        let headerFileName = cacheKeyGenerator.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
        
        var responseHeaderError: Error?
        var contentError: Error?
        let group = DispatchGroup()
        
        group.enter()
        CacheFileWriterHelper.saveResponseHeader(headerFields: ["Content-Type": "text/html"], toNewFileName: headerFileName) { (result) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success, .exists:
                break
            case .failure(let error):
                responseHeaderError = error
            }
        }

        group.enter()
        CacheFileWriterHelper.saveContent(content, toNewFileName: fileName, mimeType: mimeType) { (result) in
            
            defer {
                group.leave()
            }
            switch result {
            case .success, .exists:
                break
            case .failure(let error):
                contentError = error
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
            if let contentError = contentError {
                failure(contentError)
                return
            }
            
            if let responseHeaderError = responseHeaderError {
                failure(responseHeaderError)
            }
            
            success()
        }
    }
    
    func addBundledResourcesForMigration(urlRequests:[URLRequest], success: @escaping ([URLRequest]) -> Void, failure: @escaping (Error) -> Void) {
        
        guard let articleFetcher = fetcher as? ArticleFetcher else {
            failure(CacheFileWriterError.unexpectedFetcherTypeForBundledMigration)
            return
        }
        
        guard let bundledOfflineResources = articleFetcher.bundledOfflineResourceURLs() else {
            failure(CacheFileWriterError.unableToDetermineBundledOfflineURLS)
            return
        }
        
        var failedURLRequests: [URLRequest] = []
        var succeededURLRequests: [URLRequest] = []
        
        func writeBundledFilesBlock(mimeType: String, bundledFileURL: URL, fileName: String, headerFileName: String, completion: @escaping (Result<Bool, Error>) -> Void) {
            CacheFileWriterHelper.copyFile(from: bundledFileURL, toNewFileWithKey: fileName, mimeType: mimeType) { (result) in
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
        
        for urlRequest in urlRequests {
            
            guard let itemKey = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey] else {
                continue
            }
            
            let fileName = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: nil)
            let headerFileName = cacheKeyGenerator.uniqueHeaderFileNameForItemKey(itemKey, variant: nil)
            
            switch itemKey {
            case bundledOfflineResources.baseCSS.absoluteString:
                
                writeBundledFilesBlock(mimeType: "text/css", bundledFileURL: baseCSSFileURL, fileName: fileName, headerFileName: headerFileName) { (result) in
                    switch result {
                    case .success(let resultFlag):
                        if resultFlag == true {
                            succeededURLRequests.append(urlRequest)
                        } else {
                            failedURLRequests.append(urlRequest)
                        }
                    case .failure:
                        failedURLRequests.append(urlRequest)
                    }
                }
                
            case bundledOfflineResources.pcsCSS.absoluteString:
                
                writeBundledFilesBlock(mimeType: "text/css", bundledFileURL: pcsCSSFileURL, fileName: fileName, headerFileName: headerFileName) { (result) in
                    switch result {
                    case .success(let resultFlag):
                        if resultFlag == true {
                            succeededURLRequests.append(urlRequest)
                        } else {
                            failedURLRequests.append(urlRequest)
                        }
                    case .failure:
                        failedURLRequests.append(urlRequest)
                    }
                }
                
            case bundledOfflineResources.pcsJS.absoluteString:
                
                writeBundledFilesBlock(mimeType: "application/javascript", bundledFileURL: pcsJSFileURL, fileName: fileName, headerFileName: headerFileName) { (result) in
                    switch result {
                    case .success(let resultFlag):
                        if resultFlag == true {
                            succeededURLRequests.append(urlRequest)
                        } else {
                            failedURLRequests.append(urlRequest)
                        }
                    case .failure:
                        failedURLRequests.append(urlRequest)
                    }
                }
                
            default:
                failedURLRequests.append(urlRequest)
            }
        }
        
        if succeededURLRequests.count == 0 {
            failure(CacheFileWriterError.failureToSaveBundledFiles)
            return
        }

        success(succeededURLRequests)
    }
}
