
import Foundation

enum CacheFileWriterError: Error {
    case missingTemporaryFileURL
    case missingHeaderItemKey
    case missingHTTPResponse
}

enum CacheFileWriterResult {
    case success
    case failure(Error)
}

final class CacheFileWriter: CacheTaskTracking {

    private let fetcher: CacheFetching
    private let cacheKeyGenerator: CacheKeyGenerating.Type
    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init?(fetcher: CacheFetching,
                       cacheBackgroundContext: NSManagedObjectContext,
                       cacheKeyGenerator: CacheKeyGenerating.Type) {
        self.fetcher = fetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.cacheKeyGenerator = cacheKeyGenerator
        
        do {
            try FileManager.default.createDirectory(at: CacheController.cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Failure to create article cache directory")
            return nil
        }
    }
    
    func add(groupKey: String, urlRequest: URLRequest, completion: @escaping (CacheFileWriterResult) -> Void) {
        
        guard let url = urlRequest.url,
            let itemKey = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey] else {
            completion(.failure(CacheFileWriterError.missingHeaderItemKey))
            return
        }
        
        let variant = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant]
        let fileName = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant)
        let headerFileName = cacheKeyGenerator.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
        
        let untrackKey = UUID().uuidString
        let task = fetcher.downloadData(urlRequest: urlRequest) { (error, _, response, temporaryFileURL, mimeType) in
            
            defer {
                self.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            if let error = error {
                switch error as? RequestError {
                case .notModified:
                    completion(.success)
                default:
                    DDLogError("Error downloading data for offline: \(error)\n\(String(describing: response))")
                    completion(.failure(error))
                }
                return
            }
            
            guard let responseHeader = response as? HTTPURLResponse else {
                completion(.failure(CacheFileWriterError.missingHTTPResponse))
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            var responseHeaderSaveError: Error? = nil
            var responseSaveError: Error? = nil
            
            CacheFileWriterHelper.saveResponseHeader(urlResponse: responseHeader, toNewFileName: headerFileName) { (result) in
                
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
            
            if let temporaryFileURL = temporaryFileURL {
                //file needs to be moved
                dispatchGroup.enter()
                CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: fileName, mimeType: mimeType) { (result) in
                    
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
                
                completion(.success)
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func remove(fileName: String, completion: @escaping (CacheFileWriterResult) -> Void) {
        
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

//Migration

extension CacheFileWriter {
    
    func migrateCachedContent(content: String, urlRequest: URLRequest, mimeType: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        guard let itemKey =  urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey] else {
                failure(CacheFileWriterError.missingHeaderItemKey)
                return
        }
        
        let variant = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant]
        let fileName = cacheKeyGenerator.uniqueFileNameForItemKey(itemKey, variant: variant)

        CacheFileWriterHelper.saveContent(content, toNewFileName: fileName, mimeType: mimeType) { (result) in
            switch result {
            case .success, .exists:
                success()
            case .failure(let error):
                failure(error)
            }
        }
    }
}
