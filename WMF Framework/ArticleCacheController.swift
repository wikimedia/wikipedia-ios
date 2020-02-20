
import Foundation

public final class ArticleCacheController: CacheController {

#if DEBUG
    override public func add(url: URL, groupKey: CacheController.GroupKey, individualCompletion: @escaping CacheController.IndividualCompletionBlock, groupCompletion: @escaping CacheController.GroupCompletionBlock) {
        super.add(url: url, groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.dbWriter.fetchAndPrintEachItem()
            self.dbWriter.fetchAndPrintEachGroup()
        }
    }
    
    public override func remove(groupKey: CacheController.GroupKey, individualCompletion: @escaping CacheController.IndividualCompletionBlock, groupCompletion: @escaping CacheController.GroupCompletionBlock) {
        super.remove(groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.dbWriter.fetchAndPrintEachItem()
            self.dbWriter.fetchAndPrintEachGroup()
        }
    }
#endif

    enum CacheFromMigrationError: Error {
        case invalidDBWriterType
    }
    
    public func cacheFromMigration(desktopArticleURL: URL, itemKey: String? = nil, content: String, mimeType: String, completionHandler: @escaping ((Error?) -> Void)) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            completionHandler(CacheFromMigrationError.invalidDBWriterType)
            return
        }
        
        articleDBWriter.cacheMobileHtmlFromMigration(desktopArticleURL: desktopArticleURL, success: { urlRequest in
            
            self.fileWriter.migrateCachedContent(content: content, urlRequest: urlRequest, mimeType: mimeType, success: {

                articleDBWriter.migratedCacheItemFile(urlRequest: urlRequest, success: {

                    DDLogDebug("successfully migrated")
                    completionHandler(nil)

                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10) {
                        self.dbWriter.fetchAndPrintEachItem()
                        self.dbWriter.fetchAndPrintEachGroup()
                    }
                    
                }) { (error) in
                    completionHandler(error)
                    //tonitodo: broadcast migration error
                }
            }) { (error) in
                completionHandler(error)
                //tonitodo: broadcast migration error
            }
        }) { (error) in
            completionHandler(error)
            //tonitodo: broadcast migration error
        }
    }
}
