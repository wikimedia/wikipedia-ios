
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
    
    struct ArticleCacheDBWriterResultItem {
        let itemKey: CacheController.ItemKey
        let url: URL
        let variantGroupKey: String?
    }

    init(articleFetcher: ArticleFetcher, cacheBackgroundContext: NSManagedObjectContext, imageController: ImageCacheController) {
        
        self.articleFetcher = articleFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.imageController = imageController
   }
    
    func add(url: URL, groupKey: String, itemKey: String, completion: CacheDBWritingCompletionWithItems) {
        assertionFailure("ArticleCacheDBWriter is a grouped cacher that determines it's own itemKeys internally. Do not pass in itemKey.")
    }
    
    func add(urls: [URL], groupKey: String, completion: CacheDBWritingCompletionWithItems) {
        assertionFailure("ArticleCacheDBWriter not setup for batch url inserts.")
    }
    
    func add(url: URL, groupKey: CacheController.ItemKey, completion: @escaping CacheDBWritingCompletionWithItems) {
        
        guard let siteURL = url.wmf_site,
            let articleTitle = url.wmf_title,
            let mobileHtmlUrl = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mobileHTML) else {
                completion(.failure(ArticleCacheDBWriterError.unableToDetermineSiteURLOrArticleTitle))
                return
        }
        
        let mobileHtmlItemKey = groupKey.appendingLanguageVariantIfNecessary(host: url.host)
        let mobileHtmlItem = ArticleCacheDBWriterResultItem(itemKey: mobileHtmlItemKey, url: mobileHtmlUrl, variantGroupKey: groupKey)
        
        guard let mediaListUrl = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mediaList),
            let mediaListKeyWithoutVariant = mediaListUrl.wmf_databaseKey else {
            completion(.failure(ArticleCacheDBWriterError.unableToDetermineMediaListKey))
            return
        }
        
        let mediaListKeyWithVariant = mediaListKeyWithoutVariant.appendingLanguageVariantIfNecessary(host: url.host)
        let mediaListItem = ArticleCacheDBWriterResultItem(itemKey: mediaListKeyWithVariant, url: mediaListUrl, variantGroupKey: mediaListKeyWithoutVariant)
        
        var mobileHtmlOfflineResourceItems: [ArticleCacheDBWriterResultItem] = []
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
                    
                    let resultItem = ArticleCacheDBWriterResultItem(itemKey: itemKey, url: url, variantGroupKey: nil)
                    mobileHtmlOfflineResourceItems.append(resultItem)
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
                
                self.imageController.add(urls: urls, groupKey: groupKey, itemCompletion: { (result) in
                    //tonitodo: don't think we need this. if not make it optional
                }) { (result) in
                    //tonitodo: don't think we need this. if not make it optional
                }
                
            case .failure(let error):
                mediaListError = error
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            
            if let mediaListError = mediaListError {
                let result = CacheDBWritingResultWithItems.failure(mediaListError)
                completion(result)
                return
            }
            
            if let mobileHtmlOfflineResourceError = mobileHtmlOfflineResourceError {
                let result = CacheDBWritingResultWithItems.failure(mobileHtmlOfflineResourceError)
                completion(result)
                return
            }
            
            //append language variant to relevant item keys here
            
            
            let mustHaveItems = [[mobileHtmlItem], [mediaListItem], mobileHtmlOfflineResourceItems].flatMap { $0 }
            
            self.cacheURLs(groupKey: groupKey, mustHaveItems: mustHaveItems, niceToHaveItems: []) { (result) in
                switch result {
                case .success:
                    let resultItems = mustHaveItems.map { CacheDBWritingResultItem(itemKey: $0.itemKey, url: $0.url) }
                    let result = CacheDBWritingResultWithItems.success(resultItems)
                    completion(result)
                case .failure(let error):
                    let result = CacheDBWritingResultWithItems.failure(error)
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
    
    func shouldDownloadVariant(itemKey: CacheController.ItemKey) -> Bool {
        //maybe tonitodo: if we reach a point where we add all language variation keys to db, we should limit this based on their NSLocale language preferences.
        return true
    }
}

//Migration

extension ArticleCacheDBWriter {
    
    func cacheMobileHtmlFromMigration(desktopArticleURL: URL, success: @escaping (CacheController.ItemKey) -> Void, failure: @escaping (Error) -> Void) { //articleURL should be desktopURL
        guard let keyWithoutVariant = desktopArticleURL.wmf_databaseKey,
            let mobileHtmlUrl = ArticleURLConverter.mobileHTMLURL(desktopURL: desktopArticleURL, endpointType: .mobileHTML) else {
            failure(ArticleCacheDBWriterError.unableToDetermineMobileHtmlDatabaseKey)
            return
        }
        
        let keyWithVariant = keyWithoutVariant.appendingLanguageVariantIfNecessary(host: desktopArticleURL.host)
        
        let item = ArticleCacheDBWriterResultItem(itemKey: keyWithVariant, url: mobileHtmlUrl, variantGroupKey: keyWithoutVariant)
        cacheURLs(groupKey: keyWithoutVariant, mustHaveItems: [item], niceToHaveItems: []) { (result) in
            switch result {
            case .success:
                success(keyWithoutVariant)
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
    
    func cacheURLs(groupKey: String, mustHaveItems: [ArticleCacheDBWriterResultItem], niceToHaveItems: [ArticleCacheDBWriterResultItem], completion: @escaping ((SaveResult) -> Void)) {


        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for mustHaveItem in mustHaveItems {
                guard let cacheItem = CacheDBWriterHelper.fetchOrCreateCacheItem(with: mustHaveItem.itemKey, in: context) else {
                    completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateMustHaveCacheItem))
                    return
                }
                
                cacheItem.variantGroupKey = mustHaveItem.variantGroupKey
                cacheItem.url = mustHaveItem.url
                
                group.addToCacheItems(cacheItem)
                group.addToMustHaveCacheItems(cacheItem)
            }
            
            for niceToHaveItem in niceToHaveItems {
                guard let cacheItem = CacheDBWriterHelper.fetchOrCreateCacheItem(with: niceToHaveItem.itemKey, in: context) else {
                    continue
                }
                
                cacheItem.variantGroupKey = niceToHaveItem.variantGroupKey
                cacheItem.url = niceToHaveItem.url
                
                group.addToCacheItems(cacheItem)
            }
            
            CacheDBWriterHelper.save(moc: context, completion: completion)
        }
    }
}
