
import Foundation

enum ArticleCacheNewResourceDBWriterError: Error {
    case missingMOC
    case cannotFindCacheGroup
    case cannotFindCacheItem
    case unableToDetermineItemKey
    case failureFetchOrCreatCacheItem
}

final class ArticleCacheNewResourceDBWriter: ArticleCacheResourceDBWriting {
    let articleFetcher: ArticleFetcher
    let imageInfoFetcher: MWKImageInfoFetcher
    let imageFetcher: ImageFetcher
    let cacheBackgroundContext: NSManagedObjectContext
    private let imageController: ImageCacheController
    
    var fetcher: CacheFetching {
        return articleFetcher
    }
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    struct Item {
        let itemKeyAndVariant: CacheController.ItemKeyAndVariant
        let url: URL
        let urlRequest: URLRequest
    }
    
    init(articleFetcher: ArticleFetcher, imageFetcher: ImageFetcher, imageInfoFetcher: MWKImageInfoFetcher, cacheBackgroundContext: NSManagedObjectContext, imageController: ImageCacheController) {
        
        self.articleFetcher = articleFetcher
        self.imageFetcher = imageFetcher
        self.imageInfoFetcher = imageInfoFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.imageController = imageController
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests) {
        
        fetchImageAndResourceURLsForArticleURL(url, groupKey: groupKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let urls):
                
                //get itemKey and variant of each url, filter urls only by those that are not already cached.
                let offlineResourceItems = urls.offlineResourcesURLs.compactMap { (url) -> Item? in
                    guard let itemKey = self.articleFetcher.itemKeyForURL(url, type: .article) else {
                        return nil
                    }
                    
                    let variant = self.articleFetcher.variantForURL(url, type: .article)
                    
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.articleFetcher.urlRequestFromURL(url, type: .article) else {
                        return nil
                    }
                    
                    return Item(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest)
                }
                
                let mediaListItems = urls.mediaListURLs.compactMap { (url) -> Item? in
                    guard let itemKey = self.imageFetcher.itemKeyForURL(url, type: .image) else {
                        return nil
                    }
                    
                    let variant = self.imageFetcher.variantForURL(url, type: .image)
                    
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.imageFetcher.urlRequestFromURL(url, type: .image) else {
                        return nil
                    }
                    
                    return Item(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest)
                }
                
                //combine items to one set
                let allItems = offlineResourceItems + mediaListItems
                
                //get set of CacheItems under groupKey
                guard let context = CacheController.backgroundCacheContext else {
                    completion(.failure(ArticleCacheNewResourceDBWriterError.missingMOC))
                    return
                }
                
                context.perform {
                    guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                        completion(.failure(ArticleCacheNewResourceDBWriterError.cannotFindCacheGroup))
                        return
                    }
                    guard let cacheItems = group.cacheItems as? Set<CacheItem> else {
                        completion(.failure(ArticleCacheNewResourceDBWriterError.cannotFindCacheItem))
                        return
                    }
                    
                    //filter items down by those not contained in cacheItems
                    //tonitodo: prefer Sets for this
                    let nonCachedItems = allItems.filter { (allItem) -> Bool in
                        return !cacheItems.contains { (cacheItem) -> Bool in
                            return allItem.itemKeyAndVariant.itemKey == cacheItem.key && allItem.itemKeyAndVariant.variant == cacheItem.variant && cacheItem.isDownloaded == true
                        }
                    }
                    
                    //cache nonCached urls
                    
                    self.cacheItems(groupKey: groupKey, items: nonCachedItems) { (result) in
                        switch result {
                        case .success:
                            let requests = nonCachedItems.map { $0.urlRequest }
                            let result = CacheDBWritingResultWithURLRequests.success(requests)
                            completion(result)
                        case .failure(let error):
                            let result = CacheDBWritingResultWithURLRequests.failure(error)
                            completion(result)
                        }
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
                return
            }
        }
    }
    
    func cacheItems(groupKey: String, items: [Item], completion: @escaping ((SaveResult) -> Void)) {

        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for item in items {
                
                let itemKey = item.itemKeyAndVariant.itemKey
                let variant = item.itemKeyAndVariant.variant
                let url = item.url
                
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: url, itemKey: itemKey, variant: variant, in: context) else {
                    completion(.failure(ArticleCacheNewResourceDBWriterError.failureFetchOrCreatCacheItem))
                    return
                }
                
                group.addToCacheItems(item)
            }
            
            CacheDBWriterHelper.save(moc: context, completion: completion)
        }
    }
    
    func add(urls: [URL], groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests) {
        assertionFailure("ArticleCacheNewResourceDBWriter not setup for batch url inserts.")
    }
    
    func shouldDownloadVariant(itemKey: CacheController.ItemKey, variant: String?) -> Bool {
        return true
    }
    
}
