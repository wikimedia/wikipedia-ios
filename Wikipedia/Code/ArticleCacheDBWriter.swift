
import Foundation

enum ArticleCacheDBWriterError: Error {
    case unableToDetermineMobileHtmlDatabaseKey
    case unableToDetermineSiteURLOrArticleTitle
    case unableToDetermineMediaListKey
    case invalidListEndpointType
    case failureFetchingList(ArticleFetcher.EndpointType, Error)
    case failureFetchOrCreateCacheGroup
    case failureFetchOrCreateMustHaveCacheItem
}

final class ArticleCacheDBWriter: NSObject, CacheDBWriting {
    
    private let articleFetcher: ArticleFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    private let imageController: ImageCacheController
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]

    init(articleFetcher: ArticleFetcher, cacheBackgroundContext: NSManagedObjectContext, imageController: ImageCacheController) {
        
        self.articleFetcher = articleFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.imageController = imageController
   }
    
    func add(url: URL, groupKey: String, itemKey: String, completion: CacheDBWritingCompletion) {
        assertionFailure("ArticleCacheDBWriter is a grouped cacher that determines it's own itemKeys internally. Do not pass in itemKey.")
    }
    
    func add(url: URL, groupKey: CacheController.ItemKey, completion: @escaping CacheDBWritingCompletion) {
        let mobileHtmlItemKey = groupKey
        
        guard let mediaListItemKey = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mediaList)?.wmf_databaseKey else {
            completion(.failure(ArticleCacheDBWriterError.unableToDetermineMediaListKey))
            return
        }
        
        var mobileHtmlOfflineResourceItemKeys: [CacheController.ItemKey] = []
        var mediaListError: Error?
        var mobileHtmlOfflineResourceError: Error?
        
        //tonitodo: surely this can be cleaned up
        let group = DispatchGroup()
        
        group.enter()
        fetchURLsFromListEndpoint(with: url, groupKey: groupKey, endpointType: .mobileHtmlOfflineResources) { (result) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let urls):
                
                for url in urls {
                    guard let itemKey = url.wmf_databaseKey else {
                        continue
                    }
                    
                    mobileHtmlOfflineResourceItemKeys.append(itemKey)
                }
                
                
            case .failure(let error):
                mobileHtmlOfflineResourceError = error
            }
        }
        
        group.enter()
        fetchURLsFromListEndpoint(with: url, groupKey: groupKey, endpointType: .mediaList) { (result) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let urls):
                
                for url in urls {
                    guard let itemKey = url.wmf_databaseKey else {
                        continue
                    }
                    
                    //image controller's responsibility to take it from here and cache
                    self.imageController.add(url: url, groupKey: groupKey, itemKey: itemKey, bypassGroupDeduping: true, itemCompletion: { (result) in
                        //tonitodo: don't think we need this. if not make it optional
                    }) { (result) in
                        //tonitodo: don't think we need this. if not make it optional
                    }
                }
                
                
            case .failure(let error):
                mediaListError = error
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            
            if let mediaListError = mediaListError {
                let result = CacheDBWritingResultWithItemKeys.failure(mediaListError)
                completion(result)
                return
            }
            
            if let mobileHtmlOfflineResourceError = mobileHtmlOfflineResourceError {
                let result = CacheDBWritingResultWithItemKeys.failure(mobileHtmlOfflineResourceError)
                completion(result)
                return
            }
            
            let mustHaveKeys = [[mobileHtmlItemKey], [mediaListItemKey], mobileHtmlOfflineResourceItemKeys].flatMap { $0 }
            
            self.cacheURLs(groupKey: groupKey, mustHaveItemKeys: mustHaveKeys, niceToHaveItemKeys: []) { (result) in
                switch result {
                case .success:
                    let result = CacheDBWritingResultWithItemKeys.success(mustHaveKeys)
                    completion(result)
                case .failure(let error):
                    let result = CacheDBWritingResultWithItemKeys.failure(error)
                    completion(result)
                }
            }
        }
    }
    
    func allDownloaded(groupKey: String) -> Bool {
        guard let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        return context.performWaitAndReturn {
            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                return false
            }
            guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
                return false
            }
            for item in cacheItems {
                if !item.isDownloaded && group.mustHaveCacheItems?.contains(item) ?? false {
                    return false
                }
            }
            
            return true
        } ?? false
    }
}

//Migration

extension ArticleCacheDBWriter {
    
    func cacheMobileHtmlFromMigration(desktopArticleURL: URL, success: @escaping (CacheController.ItemKey) -> Void, failure: @escaping (Error) -> Void) { //articleURL should be desktopURL
        guard let key = desktopArticleURL.wmf_databaseKey else {
            failure(ArticleCacheDBWriterError.unableToDetermineMobileHtmlDatabaseKey)
            return
        }
        
        //tonitodo: remove fromMigration flag
        cacheURLs(groupKey: key, mustHaveItemKeys: [key], niceToHaveItemKeys: []) { (result) in
            switch result {
            case .success:
                success(key)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    func migratedCacheItemFile(itemKey: CacheController.ItemKey, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        cacheBackgroundContext.perform {
            guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: self.cacheBackgroundContext) else {
                failure(ArticleCacheDBWriterError.failureFetchOrCreateMustHaveCacheItem)
                return
            }
            item.isDownloaded = true
            CacheDBWriterHelper.save(moc: self.cacheBackgroundContext) { (result) in
                switch result {
                case .success:
                    success()
                case .failure(let error):
                    failure(error)
                }
            }
        }
    }
}

private extension ArticleCacheDBWriter {
    
    func fetchURLsFromListEndpoint(with articleURL: URL, groupKey: String, endpointType: ArticleFetcher.EndpointType, completion: @escaping (Result<[URL], ArticleCacheDBWriterError>) -> Void) {
        
        guard endpointType == .mediaList ||
            endpointType == .mobileHtmlOfflineResources else {
                completion(.failure(.invalidListEndpointType))
                return
        }
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchResourceList(with: articleURL, endpointType: endpointType) { [weak self] (result) in
            
            defer {
                self?.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            switch result {
            case .success(let urls):
                completion(.success(urls))
            case .failure(let error):
                completion(.failure(.failureFetchingList(endpointType, error)))
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func cacheURLs(groupKey: String, mustHaveItemKeys: [CacheController.ItemKey], niceToHaveItemKeys: [CacheController.ItemKey], completion: @escaping ((SaveResult) -> Void)) {


        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for itemKey in mustHaveItemKeys {
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                    completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateMustHaveCacheItem))
                    return
                }
                
                group.addToCacheItems(item)
                group.addToMustHaveCacheItems(item)
            }
            
            for itemKey in niceToHaveItemKeys {
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                    continue
                }
                
                group.addToCacheItems(item)
            }
            
            CacheDBWriterHelper.save(moc: context, completion: completion)
        }
    }
}
