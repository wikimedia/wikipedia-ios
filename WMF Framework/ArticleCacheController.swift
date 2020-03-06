
import Foundation

public final class ArticleCacheController: CacheController {
    
    //use to cache entire article and all dependent resources and images
    public static let shared: ArticleCacheController? = {
        
        guard let cacheBackgroundContext = CacheController.backgroundCacheContext,
        let imageCacheController = ImageCacheController.shared else {
            return nil
        }
        
        let articleFetcher = ArticleFetcher()
        let imageInfoFetcher = MWKImageInfoFetcher()
        
        let cacheFileWriter = CacheFileWriter(fetcher: articleFetcher)
        
        let articleDBWriter = ArticleCacheDBWriter(articleFetcher: articleFetcher, cacheBackgroundContext: cacheBackgroundContext, imageController: imageCacheController, imageInfoFetcher: imageInfoFetcher)
        
        return ArticleCacheController(dbWriter: articleDBWriter, fileWriter: cacheFileWriter)
    }()
    
    public static func newResourceCacheController() -> ArticleCacheController? {
        
        guard let cacheBackgroundContext = CacheController.backgroundCacheContext,
        let imageCacheController = ImageCacheController.shared else {
            return nil
        }
        
        let articleFetcher = ArticleFetcher()
        let imageInfoFetcher = MWKImageInfoFetcher()
        let imageFetcher = ImageFetcher()
        
        let cacheFileWriter = CacheFileWriter(fetcher: articleFetcher)
        let newResourceDBWriter = ArticleCacheNewResourceDBWriter(articleFetcher: articleFetcher, imageFetcher: imageFetcher, imageInfoFetcher: imageInfoFetcher, cacheBackgroundContext: cacheBackgroundContext, imageController: imageCacheController)
        
        return ArticleCacheController(dbWriter: newResourceDBWriter, fileWriter: cacheFileWriter)
    }

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
                            
                            if cacheBundledError == nil {
                                completionHandler(nil)
                            } else {
                                completionHandler(cacheBundledError)
                            }
                            
                        case .failure(let error):
                            completionHandler(error)
                        }
                    }
                }) { (error) in
                    completionHandler(error)
                }
            }) { (error) in
                completionHandler(error)
            }
        }
    }
    
    private func bundledResourcesAreCached() -> Bool {
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            return false
        }
        
        return articleDBWriter.bundledResourcesAreCached()
    }
    
    private func cacheBundledResourcesIfNeeded(desktopArticleURL: URL, completionHandler: @escaping ((Error?) -> Void)) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            completionHandler(CacheFromMigrationError.invalidDBWriterType)
            return
        }
        
        if !articleDBWriter.bundledResourcesAreCached() {
            articleDBWriter.addBundledResourcesForMigration(desktopArticleURL: desktopArticleURL) { (result) in
                
                switch result {
                case .success(let requests):
                    
                    self.fileWriter.addBundledResourcesForMigration(urlRequests: requests, success: { (_) in
                        
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
