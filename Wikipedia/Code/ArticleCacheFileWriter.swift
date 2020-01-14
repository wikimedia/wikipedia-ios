
import Foundation

enum ArticleCacheFileWriterError: Error {
    case expectingCacheItemToFlagFromMigration
    case missingItemKey
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
    
    func add(groupKey: String, itemKey: String) {
        
        guard let url = URL(string: itemKey) else {
            self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
            return
        }
        
        let urlToDownload = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mobileHTML, scheme: Configuration.Scheme.https) ?? url
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.downloadData(url: urlToDownload) { (error, _, temporaryFileURL, mimeType) in
            
            defer {
                self.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            if let _ = error {
                self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                return
            }
            
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: itemKey, mimeType: mimeType) { (result) in
                switch result {
                case .success, .exists:
                    self.delegate?.fileWriterDidAdd(groupKey: groupKey, itemKey: itemKey)
                case .failure:
                    self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
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
    
    func migrateCachedContent(content: String, cacheItem: PersistentCacheItem, mimeType: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        guard cacheItem.fromMigration else {
            failure(ArticleCacheFileWriterError.expectingCacheItemToFlagFromMigration)
            return
        }
        
        guard let key = cacheItem.key else {
            failure(ArticleCacheFileWriterError.missingItemKey)
            return
        }

        //key will be desktop articleURL.wmf_databaseKey format
        CacheFileWriterHelper.saveContent(content, toNewFileWithKey: key, mimeType: mimeType) { (result) in
            switch result {
            case .success, .exists:
                success()
            case .failure(let error):
                failure(error)
            }
        }
    }
}


