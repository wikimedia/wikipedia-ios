
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

    enum ArticleCacheControllerError: Error {
        case invalidDBWriterType
    }
    
    //syncs already cached resources with mobile-html-offline-resources and media-list endpoints (caches new urls, removes old urls)
    public func syncCachedResources(url: URL, groupKey: CacheController.GroupKey, groupCompletion: @escaping GroupCompletionBlock) {
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            groupCompletion(.failure(error: ArticleCacheControllerError.invalidDBWriterType))
            return
        }
        
        articleDBWriter.syncResources(url: url, groupKey: groupKey) { (result) in
            switch result {
            case .success(let syncResult):
            
                let group = DispatchGroup()
                
                var successfulAddKeys: [CacheController.UniqueKey] = []
                var failedAddKeys: [(CacheController.UniqueKey, Error)] = []
                var successfulRemoveKeys: [CacheController.UniqueKey] = []
                var failedRemoveKeys: [(CacheController.UniqueKey, Error)] = []
                
                //add new urls in file system
                for urlRequest in syncResult.addURLRequests {
                    
                    guard let uniqueKey = self.fileWriter.uniqueFileNameForURLRequest(urlRequest),
                        let url = urlRequest.url else {
                        continue
                    }
                    
                    group.enter()
                    
                    self.fileWriter.add(groupKey: groupKey, urlRequest: urlRequest) { (fileWriterResult) in
                        switch fileWriterResult {
                        case .success(let response, let data):
                            
                            self.dbWriter.markDownloaded(urlRequest: urlRequest, response: response) { (dbWriterResult) in
                            
                                defer {
                                    group.leave()
                                }
                                    
                                switch dbWriterResult {
                                case .success:
                                    successfulAddKeys.append(uniqueKey)
                                case .failure(let error):
                                    failedAddKeys.append((uniqueKey, error))
                                }
                            }
                        case .failure(let error):
                            
                            defer {
                                group.leave()
                            }
                            
                            failedAddKeys.append((uniqueKey, error))
                        }
                    }
                }
                
                //remove old urls in file system
                for key in syncResult.removeItemKeyAndVariants {
                    
                    guard let uniqueKey = self.fileWriter.uniqueFileNameForItemKey(key.itemKey, variant: key.variant) else {
                        continue
                    }
                    
                    group.enter()
                    
                    self.fileWriter.remove(itemKey: key.itemKey, variant: key.variant) { (fileWriterResult) in
                    
                        switch fileWriterResult {
                        case .success:
                            
                            self.dbWriter.remove(itemAndVariantKey: key) { (dbWriterResult) in
                                
                                defer {
                                    group.leave()
                                }
                                
                                switch dbWriterResult {
                                case .success:
                                    successfulRemoveKeys.append(uniqueKey)
                                case .failure(let error):
                                    failedRemoveKeys.append((uniqueKey, error))
                                }
                            }
                        case .failure(let error):
                            defer {
                                group.leave()
                            }
                            
                            failedRemoveKeys.append((uniqueKey, error))
                        }
                    }
                }
                
                group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                    if let error = failedAddKeys.first?.1 ?? failedRemoveKeys.first?.1 {
                        groupCompletion(.failure(error: CacheControllerError.atLeastOneItemFailedInSync(error)))
                        return
                    }
                    
                    let successKeys = successfulAddKeys + successfulRemoveKeys
                    groupCompletion(.success(uniqueKeys: successKeys))
                }
                
            case .failure(let error):
                groupCompletion(.failure(error: error))
            }
        }
    }
    
    public func cacheFromMigration(desktopArticleURL: URL, content: String, mimeType: String, completionHandler: @escaping ((Error?) -> Void)) { //articleURL should be desktopURL
        
        guard let articleDBWriter = dbWriter as? ArticleCacheDBWriter else {
            completionHandler(ArticleCacheControllerError.invalidDBWriterType)
            return
        }
        
        cacheBundledResourcesIfNeeded(desktopArticleURL: desktopArticleURL) { (cacheBundledError) in
            
            articleDBWriter.addMobileHtmlURLForMigration(desktopArticleURL: desktopArticleURL, success: { urlRequest in
                
                self.fileWriter.addMobileHtmlContentForMigration(content: content, urlRequest: urlRequest, mimeType: mimeType, success: {

                    articleDBWriter.markDownloaded(urlRequest: urlRequest, response: nil) { (result) in
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
            completionHandler(ArticleCacheControllerError.invalidDBWriterType)
            return
        }
        
        if !articleDBWriter.bundledResourcesAreCached() {
            articleDBWriter.addBundledResourcesForMigration(desktopArticleURL: desktopArticleURL) { (result) in
                
                switch result {
                case .success(let requests):
                    
                    self.fileWriter.addBundledResourcesForMigration(urlRequests: requests, success: { (_) in
                        
                        let bulkRequests = requests.map { ArticleCacheDBWriter.BulkMarkDownloadRequest(urlRequest: $0, response: nil) }
                        articleDBWriter.markDownloaded(requests: bulkRequests) { (result) in
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
