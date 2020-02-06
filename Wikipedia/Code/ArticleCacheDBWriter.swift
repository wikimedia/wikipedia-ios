
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
        let mobileHtmlItem = CacheDBWritingResultItem(itemKey: mobileHtmlItemKey, url: mobileHtmlUrl)
        
        guard let mediaListUrl = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mediaList),
            let mediaListItemKey = mediaListUrl.wmf_databaseKey?.appendingLanguageVariantIfNecessary(host: url.host) else {
            completion(.failure(ArticleCacheDBWriterError.unableToDetermineMediaListKey))
            return
        }
        
        let mediaListItem = CacheDBWritingResultItem(itemKey: mediaListItemKey, url: mediaListUrl)
        
        var mobileHtmlOfflineResourceItems: [CacheDBWritingResultItem] = []
        var mediaListError: Error?
        var mobileHtmlOfflineResourceError: Error?
        
        //tonitodo: surely this can be cleaned up
        let group = DispatchGroup()
        
        group.enter()
        fetchURLsFromListEndpoint(siteURL: siteURL, articleTitle: articleTitle, groupKey: groupKey, endpointType: .mobileHtmlOfflineResources) { (result) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let urls):
                
                for url in urls {
                    guard let itemKey = url.wmf_databaseKey else {
                        continue
                    }
                    
                    let resultItem = CacheDBWritingResultItem(itemKey: itemKey, url: url)
                    mobileHtmlOfflineResourceItems.append(resultItem)
                }
                
                
            case .failure(let error):
                mobileHtmlOfflineResourceError = error
            }
        }
        
        group.enter()
        fetchURLsFromListEndpoint(siteURL: siteURL, articleTitle: articleTitle, groupKey: groupKey, endpointType: .mediaList) { (result) in
            
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
                    let result = CacheDBWritingResultWithItems.success(mustHaveItems)
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
        guard let key = desktopArticleURL.wmf_databaseKey,
            let mobileHtmlUrl = ArticleURLConverter.mobileHTMLURL(desktopURL: desktopArticleURL, endpointType: .mobileHTML) else {
            failure(ArticleCacheDBWriterError.unableToDetermineMobileHtmlDatabaseKey)
            return
        }
        
        let item = CacheDBWritingResultItem(itemKey: key, url: mobileHtmlUrl)
        cacheURLs(groupKey: key, mustHaveItems: [item], niceToHaveItems: []) { (result) in
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
    
    func fetchURLsFromListEndpoint(siteURL: URL, articleTitle: String, groupKey: String, endpointType: ArticleFetcher.EndpointType, completion: @escaping (Result<[URL], ArticleCacheDBWriterError>) -> Void) {
        
        guard endpointType == .mediaList ||
            endpointType == .mobileHtmlOfflineResources else {
                completion(.failure(.invalidListEndpointType))
                return
        }
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchResourceList(siteURL: siteURL, articleTitle: articleTitle, endpointType: endpointType) { [weak self] (result) in
            
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
    
    func cacheURLs(groupKey: String, mustHaveItems: [CacheDBWritingResultItem], niceToHaveItems: [CacheDBWritingResultItem], completion: @escaping ((SaveResult) -> Void)) {


        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for item in mustHaveItems {
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: item.itemKey, in: context) else {
                    completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateMustHaveCacheItem))
                    return
                }
                
                group.addToCacheItems(item)
                group.addToMustHaveCacheItems(item)
            }
            
            for item in niceToHaveItems {
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: item.itemKey, in: context) else {
                    continue
                }
                
                group.addToCacheItems(item)
            }
            
            CacheDBWriterHelper.save(moc: context, completion: completion)
        }
    }
}
