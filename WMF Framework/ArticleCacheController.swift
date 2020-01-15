
import Foundation

public final class ArticleCacheController: CacheController {

    public func cacheFromMigration(desktopArticleURL: URL, itemKey: String? = nil, content: String, mimeType: String) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter,
        let articleFileWriter = fileWriter as? ArticleCacheFileWriter else {
            return
        }
        
        articleDBWriter.cacheMobileHtmlFromMigration(desktopArticleURL: desktopArticleURL, success: { itemKey in
            
            articleFileWriter.migrateCachedContent(content: content, itemKey: itemKey, mimeType: mimeType, success: {
                
                articleDBWriter.migratedCacheItemFile(itemKey: itemKey, success: {
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
