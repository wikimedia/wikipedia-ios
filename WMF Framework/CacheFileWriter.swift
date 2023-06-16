import Foundation
import CocoaLumberjackSwift

enum CacheFileWriterError: Error {
    case missingTemporaryFileURL
    case missingHeaderItemKey
    case missingHTTPResponse
    case unableToDetermineSiteURLFromMigration
    case unexpectedFetcherTypeForBundledMigration
    case unableToDetermineBundledOfflineURLS
    case failureToSaveBundledFiles
    case unableToPullCachedDataFromNotModified
    case missingURLInRequest
    case unableToGenerateHTTPURLResponse
    case unableToDetermineFileNames
}

enum CacheFileWriterAddResult {
    case success(response: HTTPURLResponse, data: Data)
    case failure(Error)
}

enum CacheFileWriterRemoveResult {
    case success
    case failure(Error)
}

final class CacheFileWriter: CacheTaskTracking {

    private let fetcher: CacheFetching
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(fetcher: CacheFetching) {
        self.fetcher = fetcher
        
        do {
            try FileManager.default.createDirectory(at: CacheController.cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogError("Error creating permanent cache: \(error)")
        }
    }
    
    func add(groupKey: String, urlRequest: URLRequest, completion: @escaping (CacheFileWriterAddResult) -> Void) {
        
        let untrackKey = UUID().uuidString
        let task = fetcher.dataForURLRequest(urlRequest) { [weak self] (response) in
            guard let self = self else {
                return
            }
            
            defer {
                self.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            switch response {
            case .success(let result):
                
                guard let httpUrlResponse = result.response as? HTTPURLResponse else {
                    completion(.failure(CacheFileWriterError.missingHTTPResponse))
                    return
                }
                
                self.fetcher.cacheResponse(httpUrlResponse: httpUrlResponse, content: .data(result.data), urlRequest: urlRequest, success: {
                    completion(.success(response: httpUrlResponse, data: result.data))
                }) { (error) in
                    completion(.failure(error))
                }
                
            case .failure(let error):
                DDLogError("Error downloading data for offline: \(error)\n\(String(describing: response))")
                completion(.failure(error))
                return
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func remove(itemKey: String, variant: String?, completion: @escaping (CacheFileWriterRemoveResult) -> Void) {
        
        guard let fileName = self.fetcher.uniqueFileNameForItemKey(itemKey, variant: variant),
            let headerFileName = self.fetcher.uniqueHeaderFileNameForItemKey(itemKey, variant: variant) else {
                completion(.failure(CacheFileWriterError.unableToDetermineFileNames))
                return
        }
        
        var responseHeaderRemoveError: Error? = nil
        var responseRemoveError: Error? = nil

        // remove response from file system
        let responseCachedFileURL = CacheFileWriterHelper.fileURL(for: fileName)
        do {
            try FileManager.default.removeItem(at: responseCachedFileURL)
        } catch let error as NSError {
            if !(error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError) {
               responseRemoveError = error
            }
        }
        
        // remove response header from file system
        let responseHeaderCachedFileURL = CacheFileWriterHelper.fileURL(for: headerFileName)
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
    
    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        return fetcher.uniqueFileNameForItemKey(itemKey, variant: variant)
    }
    
    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String? {
        return fetcher.uniqueFileNameForURLRequest(urlRequest)
    }
    
}
