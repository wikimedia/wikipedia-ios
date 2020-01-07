
import Foundation

final public class ArticleCacheFileWriter: NSObject, CacheFileWriting {
    
    weak var delegate: CacheFileWritingDelegate?
    private let articleFetcher: ArticleFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    
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
    
    func download(cacheItem: PersistentCacheItem) {
        
        if cacheItem.fromMigration {
            assertionFailure("Not expecting cache item to come through this path. ")
            return
        } else if cacheItem.isDownloaded == true {
            return
        }
        
        guard let key = cacheItem.key,
            let url = URL(string: key) else {
                return
        }
        
        let urlToDownload = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mobileHTML, scheme: Configuration.Scheme.https) ?? url
        
        articleFetcher.downloadData(url: urlToDownload) { (error, _, temporaryFileURL, mimeType) in
            if let _ = error {
                //tonitodo: better error handling here
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                return
            }
            
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: key, mimeType: mimeType) { (result) in
                switch result {
                case .success:
                    self.delegate?.fileWriterDidDownload(cacheItem: cacheItem)
                    NotificationCenter.default.post(name: ArticleCacheFileWriter.didChangeNotification, object: nil, userInfo: [ArticleCacheFileWriter.didChangeNotificationUserInfoDBKey: key,
                    ArticleCacheFileWriter.didChangeNotificationUserInfoIsDownloadedKey: true])
                default:
                    //tonitodo: better error handling
                    break
                }
            }
        }
    }
    
    func delete(cacheItem: PersistentCacheItem) {

        guard let key = cacheItem.key else {
            assertionFailure("cacheItem has no key")
            return
        }
        
        let pathComponent = key.sha256 ?? key
        
        let cachedFileURL = CacheController.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try FileManager.default.removeItem(at: cachedFileURL)
            delegate?.fileWriterDidDelete(cacheItem: cacheItem)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                delegate?.fileWriterDidDelete(cacheItem: cacheItem)
            } else {
                delegate?.fileWriterDidFailToDelete(cacheItem: cacheItem, error: error)
            }
        }
    }
}

//Migration

extension ArticleCacheFileWriter {
    
    func migrateCachedContent(content: String, cacheItem: PersistentCacheItem, successCompletion: @escaping () -> Void) {
        
        guard cacheItem.fromMigration else {
            return
        }
        
        guard let key = cacheItem.key else {
            return
        }

        //key will be desktop articleURL.wmf_databaseKey format.
        //Monte: if your local mobile-html is in some sort of temporary file location, you can try calling this here:
        CacheFileWriterHelper.saveContent(content, toNewFileWithKey: key, mimeType: nil) { (result) in
            switch result {
            case .success:
                successCompletion()
            default:
                break
            }
        }
    }
}


