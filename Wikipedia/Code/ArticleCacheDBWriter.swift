
import Foundation

enum ArticleCacheDBWriterError: Error {
    case passedInItemKeyOrVariantInfo
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
    
    struct SaveItem {
        let itemKey: CacheController.ItemKey
        let variantId: String?
        let variantGroupKey: String
    }

    init(articleFetcher: ArticleFetcher, cacheBackgroundContext: NSManagedObjectContext, imageController: ImageCacheController) {
        
        self.articleFetcher = articleFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.imageController = imageController
   }
    
    func add(url: URL, groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey? = nil, variantId: String? = nil, variantGroupKey: String? = nil, completion: @escaping CacheDBWritingCompletion) {
        
        guard itemKey == nil && variantId == nil && variantGroupKey == nil else {
            assertionFailure("ArticleCacheDBWriter is a grouped cacher that determines it's own itemKeys, variantIds and variantGroupKeys internally. Do not pass in these.")
            completion(.failure(ArticleCacheDBWriterError.passedInItemKeyOrVariantInfo))
            return
        }
        
        guard let siteURL = url.wmf_site,
            let articleTitle = url.wmf_title else {
                completion(.failure(ArticleCacheDBWriterError.unableToDetermineSiteURLOrArticleTitle))
                return
        }
        
        let mobileHtmlItemKey = groupKey
        let variantId = NSLocale.wmf_acceptLanguageHeaderForPreferredLanguages
        let mobileHtmlSaveItem = SaveItem(itemKey: mobileHtmlItemKey, variantId: variantId, variantGroupKey: mobileHtmlItemKey)
        
        guard let mediaListItemKey = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mediaList)?.wmf_databaseKey else {
            completion(.failure(ArticleCacheDBWriterError.unableToDetermineMediaListKey))
            return
        }
        
        let mediaListSaveItem = SaveItem(itemKey: mediaListItemKey, variantId: variantId, variantGroupKey: mediaListItemKey)
        
        var mobileHtmlOfflineResourceItems: [SaveItem] = []
        var mediaListError: Error?
        var mobileHtmlOfflineResourceError: Error?
        
        //tonitodo: surely this can be cleaned up
        let group = DispatchGroup()
        
        group.enter()
        
        fetchOfflineResourcesEndpoint(siteURL: siteURL, articleTitle: articleTitle, groupKey: groupKey) { (result) in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let urls):
                
                for url in urls {
                    guard let itemKey = url.wmf_databaseKey else {
                        continue
                    }
                    
                    let saveItem = SaveItem(itemKey: itemKey, variantId: variantId, variantGroupKey: itemKey)
                    
                    mobileHtmlOfflineResourceItems.append(saveItem)
                }
                
                
            case .failure(let error):
                mobileHtmlOfflineResourceError = error
            }
        }
        
        group.enter()
        fetchMediaListEndpoint(siteURL: siteURL, articleTitle: articleTitle, groupKey: groupKey) { (result) in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let results):
                
                for result in results {
                    guard let itemKey = result.url.wmf_databaseKey else {
                        continue
                    }
                    
                    //image controller's responsibility to take it from here and cache
                    self.imageController.add(url: url, groupKey: groupKey, itemKey: itemKey, variantId: result.variantId, variantGroupKey: result.variantGroupKey, bypassGroupDeduping: true, itemCompletion: { (result) in
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
            
            let mustHaveItems = [[mobileHtmlSaveItem], [mediaListSaveItem], mobileHtmlOfflineResourceItems].flatMap { $0 }
            
            self.cacheURLs(groupKey: groupKey, mustHaveItems: mustHaveItems, niceToHaveItems: []) { (result) in
                switch result {
                case .success:
                    let result = CacheDBWritingResultWithItemKeys.success(mustHaveItems.map { $0.itemKey })
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
        
        guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
            return false
        }
        guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
            return false
        }
        
        return context.performWaitAndReturn {
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
        
        //tonitodo: migration variants?
        let saveItem = SaveItem(itemKey: key, variantId: nil, variantGroupKey: key)
        cacheURLs(groupKey: key, mustHaveItems: [saveItem], niceToHaveItems: []) { (result) in
            switch result {
            case .success:
                success(key)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    func migratedCacheItemFile(itemKey: CacheController.ItemKey, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: cacheBackgroundContext) else {
            failure(ArticleCacheDBWriterError.failureFetchOrCreateMustHaveCacheItem)
            return
        }
        
        cacheBackgroundContext.perform {
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
    
    func fetchOfflineResourcesEndpoint(siteURL: URL, articleTitle: String, groupKey: String, completion: @escaping (Result<[URL], ArticleCacheDBWriterError>) -> Void) {
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchOfflineResourceURLs(siteURL: siteURL, articleTitle: articleTitle) { [weak self] (result) in
            defer {
                self?.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            switch result {
            case .success(let urls):
                completion(.success(urls))
            case .failure(let error):
                completion(.failure(.failureFetchingList(.mobileHtmlOfflineResources, error)))
            }
        }
            
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func fetchMediaListEndpoint(siteURL: URL, articleTitle: String, groupKey: String, completion: @escaping (Result<[ArticleFetcher.ImageResult], ArticleCacheDBWriterError>) -> Void) {
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchMediaListURLs(siteURL: siteURL, articleTitle: articleTitle) { [weak self] (result) in
            defer {
                self?.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            switch result {
            case .success(let results):
                completion(.success(results))
            case .failure(let error):
                completion(.failure(.failureFetchingList(.mediaList, error)))
            }
        }
            
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func cacheURLs(groupKey: String, mustHaveItems: [SaveItem], niceToHaveItems: [SaveItem], completion: @escaping ((SaveResult) -> Void)) {


        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for item in mustHaveItems {
                guard let cacheItem = CacheDBWriterHelper.fetchOrCreateCacheItem(with: item.itemKey, in: context) else {
                    completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateMustHaveCacheItem))
                    return
                }
                
                cacheItem.variantId = item.variantId
                
                if let variantGroup = CacheDBWriterHelper.fetchOrCreateVariantCacheGroup(with: item.variantGroupKey, in: context) {
                    variantGroup.addToCacheItems(cacheItem)
                }
                
                group.addToCacheItems(cacheItem)
                group.addToMustHaveCacheItems(cacheItem)
            }
            
            for item in niceToHaveItems {
                guard let cacheItem = CacheDBWriterHelper.fetchOrCreateCacheItem(with: item.itemKey, in: context) else {
                    continue
                }
                
                cacheItem.variantId = item.variantId
                
                if let variantGroup = CacheDBWriterHelper.fetchOrCreateVariantCacheGroup(with: item.variantGroupKey, in: context) {
                    variantGroup.addToCacheItems(cacheItem)
                }
                
                group.addToCacheItems(cacheItem)
            }
            
            CacheDBWriterHelper.save(moc: context, completion: completion)
        }
    }
}
