
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
    
    private struct NetworkItem: Hashable {
        let itemKeyAndVariant: CacheController.ItemKeyAndVariant
        let url: URL?
        let urlRequest: URLRequest?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(itemKeyAndVariant)
        }
        
        static func ==(lhs: NetworkItem, rhs: NetworkItem) -> Bool {
            return lhs.itemKeyAndVariant == rhs.itemKeyAndVariant
        }
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
                
                //package urls into NetworkItems, filter out equivalent CacheItems that are already downloaded
                let offlineResourceItems = urls.offlineResourcesURLs.compactMap { (url) -> NetworkItem? in
                    guard let itemKey = self.articleFetcher.itemKeyForURL(url, type: .article) else {
                        return nil
                    }
                    
                    let variant = self.articleFetcher.variantForURL(url, type: .article)
                    
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.articleFetcher.urlRequestFromURL(url, type: .article) else {
                        return nil
                    }
                    
                    return NetworkItem(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest)
                }
                
                
                let mediaListItems = urls.mediaListURLs.compactMap { (url) -> NetworkItem? in
                    guard let itemKey = self.imageFetcher.itemKeyForURL(url, type: .image) else {
                        return nil
                    }
                    
                    let variant = self.imageFetcher.variantForURL(url, type: .image)
                    
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.imageFetcher.urlRequestFromURL(url, type: .image) else {
                        return nil
                    }
                    
                    return NetworkItem(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest)
                }
                
                //group into dictionary of the same itemKey for use in filtering out variants
                var similarItemsDictionary: [CacheController.ItemKey: [NetworkItem]] = [:]
                for item in mediaListItems {
                    if var existingItems = similarItemsDictionary[item.itemKeyAndVariant.itemKey] {
                        existingItems.append(item)
                        similarItemsDictionary[item.itemKeyAndVariant.itemKey] = existingItems
                    } else {
                        similarItemsDictionary[item.itemKeyAndVariant.itemKey] = [item]
                    }
                }
                
                //filter out any variants that image cache controller should not download (i.e. multiple sizes of the same image)
                var finalMediaListItems: [NetworkItem] = []
                for item in mediaListItems {
                    guard let similarItems = similarItemsDictionary[item.itemKeyAndVariant.itemKey] else {
                        continue
                    }
                    
                    let allVariantItems = similarItems.map { $0.itemKeyAndVariant }
                    if ImageCacheController.shared?.shouldDownloadVariantForAllVariantItems(variant: item.itemKeyAndVariant.variant, allVariantItems) ?? false {
                        finalMediaListItems.append(item)
                    }
                }
                
                let imageInfoItems = urls.imageInfoURLs.compactMap { (url) -> NetworkItem? in
                    guard let itemKey = self.imageFetcher.itemKeyForURL(url, type: .imageInfo) else {
                        return nil
                    }
                    
                    let variant = self.imageFetcher.variantForURL(url, type: .imageInfo)
                    
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.imageFetcher.urlRequestFromURL(url, type: .imageInfo) else {
                        return nil
                    }
                    
                    return NetworkItem(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest)
                }
                
                let networkItems: Set<NetworkItem> = Set(offlineResourceItems + finalMediaListItems + imageInfoItems)
                
                //pull cache items for group key
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
                    
                    let downloadedCacheItems = cacheItems.compactMap { (cacheItem) -> NetworkItem? in
                        guard let itemKey = cacheItem.key,
                        let itemKeyandVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: cacheItem.variant),
                            cacheItem.isDownloaded == true else {
                            return nil
                        }
                        
                        return NetworkItem(itemKeyAndVariant: itemKeyandVariant, url: cacheItem.url, urlRequest: nil)
                    }
                    
                    let downloadedCacheItemsSet = Set(downloadedCacheItems)
                    
                    //get final set of resources that aren't already cached
                    let filteredNewItems = networkItems.subtracting(downloadedCacheItemsSet)
                    
                    //cache nonCached urls
                    
                    self.cacheItems(groupKey: groupKey, items: filteredNewItems) { (result) in
                        switch result {
                        case .success:
                            let requests = filteredNewItems.compactMap { $0.urlRequest }
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
    
    private func cacheItems(groupKey: String, items: Set<NetworkItem>, completion: @escaping ((SaveResult) -> Void)) {

        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for item in items {
                
                guard let url = item.url,
                    let _ = item.urlRequest else {
                        assertionFailure("These need to be populated at this point. They are only optional to be able to compare cleanly with a set of converted CacheItems to NetworkItems")
                        continue
                }
                
                let itemKey = item.itemKeyAndVariant.itemKey
                let variant = item.itemKeyAndVariant.variant
                
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
    
    func shouldDownloadVariantForAllVariantItems(variant: String?, _ allVariantItems: [CacheController.ItemKeyAndVariant]) -> Bool {
        return true
    }
}
