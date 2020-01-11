
import Foundation

final public class ArticleCacheFileWriter: NSObject, CacheFileWriting {
    
    weak var delegate: CacheFileWritingDelegate?
    private let articleFetcher: ArticleFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    public static let didChangeNotification = NSNotification.Name("ArticleCacheFileWriterDidChangeNotification")
    public static let didChangeNotificationUserInfoDBKey = ["dbKey"]
    public static let didChangeNotificationUserInfoIsDownloadedKey = ["isDownloaded"]
    
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
            return
        }
        
        let urlToDownload = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mobileHTML, scheme: Configuration.Scheme.https) ?? url
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.downloadData(url: urlToDownload) { (error, _, temporaryFileURL, mimeType) in
            if let _ = error {
                //tonitodo: better error handling here
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                return
            }
            
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: itemKey, mimeType: mimeType) { (result) in
                switch result {
                case .success:
                    self.delegate?.fileWriterDidAdd(groupKey: groupKey, itemKey: itemKey)
                    NotificationCenter.default.post(name: ArticleCacheFileWriter.didChangeNotification, object: nil, userInfo: [ArticleCacheFileWriter.didChangeNotificationUserInfoDBKey: itemKey,
                    ArticleCacheFileWriter.didChangeNotificationUserInfoIsDownloadedKey: true])
                default:
                    self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                    break
                }
            }
            
            self.untrackTask(untrackKey: untrackKey, from: groupKey)
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func remove(groupKey: String, itemKey: String) {
        
        cancelTasks(for: groupKey)
        let pathComponent = itemKey.sha256 ?? itemKey
        
        let cachedFileURL = CacheController.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try FileManager.default.removeItem(at: cachedFileURL)
            delegate?.fileWriterDidRemove(groupKey: groupKey, itemKey: itemKey)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                delegate?.fileWriterDidRemove(groupKey: groupKey, itemKey: itemKey)
            } else {
                delegate?.fileWriterDidFailRemove(groupKey: groupKey, itemKey: itemKey)
            }
        }
    }
}

//Migration

extension ArticleCacheFileWriter {
    
    func migrateCachedContent(content: String, cacheItem: PersistentCacheItem, mimeType: String, successCompletion: @escaping () -> Void) {
        
        guard cacheItem.fromMigration else {
            return
        }
        
        guard let key = cacheItem.key else {
            return
        }

        //key will be desktop articleURL.wmf_databaseKey format.
        //Monte: if your local mobile-html is in some sort of temporary file location, you can try calling this here:
        CacheFileWriterHelper.saveContent(content, toNewFileWithKey: key, mimeType: mimeType) { (result) in
            switch result {
            case .success:
                successCompletion()
            default:
                break
            }
        }
    }
}


