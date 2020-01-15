
import Foundation

public final class ArticleCacheController: CacheController {
    
    public static let didChangeNotification = NSNotification.Name("ArticleCacheControllerDidChangeNotification")
    public static let didChangeNotificationUserInfoDBKey = ["dbKey"]
    public static let didChangeNotificationUserInfoIsDownloadedKey = ["isDownloaded"]
    
    override public func toggleCache(url: URL) {
        guard let key = url.wmf_databaseKey else {
            return
        }
        
        if isCached(url: url) {
            remove(groupKey: key, itemKey: key)
        } else {
            add(url: url, groupKey: key, itemKey: key)
        }
    }
    
    override public func add(url: URL, groupKey: String, itemKey: String, completion: CompletionQueueBlock? = nil) {
        super.add(url: url, groupKey: groupKey, itemKey: itemKey, completion: completion)
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10) {
            self.dbWriter.fetchAndPrintEachItem()
            self.dbWriter.fetchAndPrintEachGroup()
        }
    }
    
    public func remove(key: String, completion: CompletionQueueBlock? = nil) {
        remove(groupKey: key, itemKey: key, completion: completion)
    }
    
    override public func remove(groupKey: String, itemKey: String, completion: CompletionQueueBlock? = nil) {
        super.remove(groupKey: groupKey, itemKey: itemKey, completion: completion)
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10) {
            self.dbWriter.fetchAndPrintEachItem()
            self.dbWriter.fetchAndPrintEachGroup()
        }
    }
    
    override func notifyAllDownloaded(groupKey: String, itemKey: String) {
        super.notifyAllDownloaded(groupKey: groupKey, itemKey: itemKey)
        NotificationCenter.default.post(name: ArticleCacheController.didChangeNotification, object: nil, userInfo: [ArticleCacheController.didChangeNotificationUserInfoDBKey: groupKey,
        ArticleCacheController.didChangeNotificationUserInfoIsDownloadedKey: true])
    }
    
    override func notifyAllRemoved(groupKey: String) {
        super.notifyAllRemoved(groupKey: groupKey)
        NotificationCenter.default.post(name: ArticleCacheController.didChangeNotification, object: nil, userInfo: [ArticleCacheController.didChangeNotificationUserInfoDBKey: groupKey,
        ArticleCacheController.didChangeNotificationUserInfoIsDownloadedKey: false])
    }
    
    public func cacheFromMigration(desktopArticleURL: URL, itemKey: String? = nil, content: String, mimeType: String) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter,
        let articleFileWriter = fileWriter as? ArticleCacheFileWriter else {
            return
        }
        
        articleDBWriter.cacheMobileHtmlFromMigration(desktopArticleURL: desktopArticleURL, success: { (cacheItem) in
            
            articleFileWriter.migrateCachedContent(content: content, cacheItem: cacheItem, mimeType: mimeType, success: {
                
                articleDBWriter.migratedCacheItemFile(cacheItem: cacheItem, success: {
                    print("successfully migrated")
                    
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10) {
                        self.dbWriter.fetchAndPrintEachItem()
                        self.dbWriter.fetchAndPrintEachGroup()
                    }
                    
                }) { (error) in
                    //tonitodo: broadcast migration error
                }
            }) { (error) in
                //tonitodo: broadcast migration error
            }
        }) { (error) in
            //tonitodo: broadcast migration error
        }
    }
}
