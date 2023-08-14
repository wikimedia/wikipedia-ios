import Foundation

public final class ArticleCacheController: CacheController {
    
    init(moc: NSManagedObjectContext, imageCacheController: ImageCacheController, session: Session, configuration: Configuration, preferredLanguageDelegate: WMFPreferredLanguageInfoProvider) {
        let articleFetcher = ArticleFetcher(session: session, configuration: configuration)
        let imageInfoFetcher = MWKImageInfoFetcher(session: session, configuration: configuration)
        imageInfoFetcher.preferredLanguageDelegate = preferredLanguageDelegate
        let cacheFileWriter = CacheFileWriter(fetcher: articleFetcher)
        
        let articleDBWriter = ArticleCacheDBWriter(articleFetcher: articleFetcher, cacheBackgroundContext: moc, imageController: imageCacheController, imageInfoFetcher: imageInfoFetcher)
        super.init(dbWriter: articleDBWriter, fileWriter: cacheFileWriter)
    }

    enum ArticleCacheControllerError: Error {
        case invalidDBWriterType
    }
    
    // syncs already cached resources with mobile-html-offline-resources and media-list endpoints (caches new urls, removes old urls)
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
                
                // add new urls in file system
                for urlRequest in syncResult.addURLRequests {
                    
                    guard let uniqueKey = self.fileWriter.uniqueFileNameForURLRequest(urlRequest), urlRequest.url != nil else {
                        continue
                    }
                    
                    group.enter()
                    
                    self.fileWriter.add(groupKey: groupKey, urlRequest: urlRequest) { (fileWriterResult) in
                        switch fileWriterResult {
                        case .success(let response, _):
                            
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
                
                // remove old urls in file system
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
}
