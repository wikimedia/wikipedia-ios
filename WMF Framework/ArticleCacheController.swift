
import Foundation

public final class ArticleCacheController: CacheController {
    
    public static let shared: ArticleCacheController = {
        
        let imageCacheController = ImageCacheController.shared
        
        let articleFetcher = ArticleFetcher()
        let imageInfoFetcher = MWKImageInfoFetcher()
        let articleCacheKeyGenerator = ArticleCacheKeyGenerator.self
        
        let cacheBackgroundContext = CacheController.backgroundCacheContext
        let cacheFileWriter = CacheFileWriter(fetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext, cacheKeyGenerator: articleCacheKeyGenerator)
        
        let articleDBWriter = ArticleCacheDBWriter(articleFetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext, imageController: imageCacheController, imageInfoFetcher: imageInfoFetcher)
        
        return ArticleCacheController(dbWriter: articleDBWriter, fileWriter: cacheFileWriter, cacheKeyGenerator: articleCacheKeyGenerator)
    }()

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
    
    public func cacheFromMigration(desktopArticleURL: URL, content: String, mimeType: String, completionHandler: @escaping ((Error?) -> Void)) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            completionHandler(CacheFromMigrationError.invalidDBWriterType)
            return
        }
        
        cacheBundledResourcesIfNeeded(desktopArticleURL: desktopArticleURL) { (cacheBundledError) in
            
            articleDBWriter.addMobileHtmlURLForMigration(desktopArticleURL: desktopArticleURL, success: { urlRequest in
                
                self.fileWriter.addMobileHtmlContentForMigration(content: content, urlRequest: urlRequest, mimeType: mimeType, success: {

                    articleDBWriter.markDownloaded(urlRequest: urlRequest) { (result) in
                        switch result {
                        case .success:
                            DDLogDebug("successfully migrated")
                            
                            if cacheBundledError == nil {
                                completionHandler(nil)
                            } else {
                                completionHandler(cacheBundledError)
                            }
                            
                        case .failure(let error):
                            completionHandler(error)
                            //tonitodo: broadcast migration error
                        }
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
    
    private func bundledResourcesAreCached(desktopArticleURL: URL) -> Bool {
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            return false
        }
        
        return articleDBWriter.bundledResourcesAreCached(desktopArticleURL: desktopArticleURL)
    }
    
    private func cacheBundledResourcesIfNeeded(desktopArticleURL: URL, completionHandler: @escaping ((Error?) -> Void)) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            completionHandler(CacheFromMigrationError.invalidDBWriterType)
            return
        }
        
        //tonitodo: this will bundle those shared across siteURLs over and over again. need to bundle shared resources first as a separate thing, then bundle site-specific resource.
        if !articleDBWriter.bundledResourcesAreCached(desktopArticleURL: desktopArticleURL) {
            articleDBWriter.addBundledResourcesForMigration(desktopArticleURL: desktopArticleURL) { (result) in
                
                switch result {
                case .success(let requests):
                    
                    self.fileWriter.addBundledResourcesForMigration(desktopArticleURL: desktopArticleURL, urlRequests: requests, success: { (_) in
                        
                        articleDBWriter.markDownloaded(urlRequests: requests) { (result) in
                            switch result {
                            case .success:
                                completionHandler(nil)
                            case .failure(let error):
                                completionHandler(error)
                            }
                        }
                        
                    }) { (error) in
                        completionHandler(error)
                    }
                case .failure(let error):
                    completionHandler(error)
                }
            }
        } else {
            completionHandler(nil)
        }
    }
}
