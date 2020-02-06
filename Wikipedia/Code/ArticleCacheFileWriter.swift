
import Foundation

enum ArticleCacheFileWriterError: Error {
    case failureToGenerateURLFromItemKey
    case missingTemporaryFileURL
}

final public class ArticleCacheFileWriter: NSObject, CacheFileWriting {
    
    private let articleFetcher: ArticleFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init?(articleFetcher: ArticleFetcher,
                       cacheBackgroundContext: NSManagedObjectContext) {
        self.articleFetcher = articleFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        
        do {
            try FileManager.default.createDirectory(at: CacheController.cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Failure to create article cache directory")
            return nil
        }
    }
    
    func add(url: URL, groupKey: String, itemKey: String, completion: @escaping (CacheFileWritingResult) -> Void) {
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.downloadData(url: url) { (error, _, response, temporaryFileURL, mimeType) in
            
            defer {
                self.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                completion(.failure(ArticleCacheFileWriterError.missingTemporaryFileURL))
                return
            }
            
            let etag = (response as? HTTPURLResponse)?.allHeaderFields[HTTPURLResponse.etagHeaderKey] as? String
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: itemKey, mimeType: mimeType) { (result) in
                switch result {
                case .success, .exists:
                    completion(.success(etag: etag)) //tonitodo: when do we overwrite for .exists?
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
}

//Migration

extension ArticleCacheFileWriter {
    
    func migrateCachedContent(content: String, itemKey: CacheController.ItemKey, mimeType: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {

        //key will be desktop articleURL.wmf_databaseKey format
        CacheFileWriterHelper.saveContent(content, toNewFileWithKey: itemKey, mimeType: mimeType) { (result) in
            switch result {
            case .success, .exists:
                success()
            case .failure(let error):
                failure(error)
            }
        }
    }
}


