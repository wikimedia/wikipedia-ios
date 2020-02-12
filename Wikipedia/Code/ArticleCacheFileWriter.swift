
import Foundation

enum ArticleCacheFileWriterError: Error {
    case failureToGenerateURLFromItemKey
    case missingTemporaryFileURL
    case missingExpectedItemsOutOfRequestHeader
}

final public class ArticleCacheFileWriter: NSObject, CacheFileWriting {
    
    weak var delegate: CacheFileWritingDelegate?
    private let articleFetcher: ArticleFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init?(articleFetcher: ArticleFetcher,
                       cacheBackgroundContext: NSManagedObjectContext, delegate: CacheFileWritingDelegate? = nil) {
        self.articleFetcher = articleFetcher
        self.delegate = delegate
        self.cacheBackgroundContext = cacheBackgroundContext
        
        do {
            try FileManager.default.createDirectory(at: CacheController.cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Failure to create article cache directory")
            return nil
        }
    }
    
    func add(groupKey: String, itemKey: String, completion: @escaping (CacheFileWritingResult) -> Void) {
        
        guard let url = URL(string: itemKey) else {
            completion(.failure(ArticleCacheFileWriterError.failureToGenerateURLFromItemKey))
            return
        }
        
        let urlToDownload = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mobileHTML, scheme: Configuration.Scheme.https) ?? url
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.downloadData(url: urlToDownload) { (error, _, response, temporaryFileURL, mimeType) in
            
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
    
    func migrateCachedContent(content: String, urlRequest: URLRequest, mimeType: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        guard let itemKey = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey],
            let variant = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant] else {
                failure(ArticleCacheDBWriterError.missingExpectedItemsOutOfRequestHeader)
                return
        }

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


