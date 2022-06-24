import Foundation

enum ArticleCacheDBWriterSyncError: Error {
    case missingMOC
    case cannotFindCacheGroup
    case cannotFindCacheItem
    case unableToDetermineItemKey
    case failureFetchOrCreateCacheItem
    case failureToCreateNetworkItem
}

struct CacheDBWritingSyncSuccessResult {
    let addURLRequests: [URLRequest]
    let removeItemKeyAndVariants: [CacheController.ItemKeyAndVariant]
}

extension ArticleCacheDBWriter {
    
    private struct NetworkItem: Hashable {
        let itemKeyAndVariant: CacheController.ItemKeyAndVariant
        let url: URL?
        let urlRequest: URLRequest?
        let cacheItem: CacheItem?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(itemKeyAndVariant)
        }
        
        static func ==(lhs: NetworkItem, rhs: NetworkItem) -> Bool {
            return lhs.itemKeyAndVariant == rhs.itemKeyAndVariant
        }
    }
        
    // adds new resources to DB, returns old resources in completion
    func syncResources(url: URL, groupKey: CacheController.GroupKey, completion: @escaping (Result<CacheDBWritingSyncSuccessResult, Error>) -> Void) {
        
        let mobileHTMLURL: URL
        let mediaListURL: URL
        let mobileHTMLRequest: URLRequest
        let mediaListRequest: URLRequest
        do {
            mobileHTMLURL  = try articleFetcher.mobileHTMLURL(articleURL: url)
            mediaListURL  = try articleFetcher.mediaListURL(articleURL: url)
            mobileHTMLRequest = try articleFetcher.mobileHTMLRequest(articleURL: url)
            mediaListRequest = try articleFetcher.mobileHTMLMediaListRequest(articleURL: url)
        } catch let error {
           completion(.failure(error))
           return
        }

        let mobileHTMLItemKey = articleFetcher.itemKeyForURL(mobileHTMLURL, type: .article)
        let mobileHTMLVariant = articleFetcher.variantForURL(mobileHTMLURL, type: .article)
        let mediaListItemKey = articleFetcher.itemKeyForURL(mediaListURL, type: .article)
        let mediaListVariant = articleFetcher.variantForURL(mediaListURL, type: .article)
        
        guard let mobileHTMLItemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: mobileHTMLItemKey, variant: mobileHTMLVariant),
            let mediaListItemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: mediaListItemKey, variant: mediaListVariant) else {
                completion(.failure(ArticleCacheDBWriterSyncError.failureToCreateNetworkItem))
                return
        }
        
        let mobileHTMLNetworkItem = NetworkItem(itemKeyAndVariant: mobileHTMLItemKeyAndVariant, url: mobileHTMLURL, urlRequest: mobileHTMLRequest, cacheItem: nil)
        let mediaListNetworkItem = NetworkItem(itemKeyAndVariant: mediaListItemKeyAndVariant, url: mediaListURL, urlRequest: mediaListRequest, cacheItem: nil)
        
        fetchImageAndResourceURLsForArticleURL(url, groupKey: groupKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let urls):
                
                // package offline resource urls into NetworkItems
                let offlineResourceItems = urls.offlineResourcesURLs.compactMap { (url) -> NetworkItem? in
                    guard let itemKey = self.articleFetcher.itemKeyForURL(url, type: .article) else {
                        return nil
                    }
                    
                    let variant = self.articleFetcher.variantForURL(url, type: .article)
                    
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.articleFetcher.urlRequestFromPersistence(with: url, persistType: .article) else {
                        return nil
                    }
                    
                    return NetworkItem(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest, cacheItem: nil)
                }
                
                // begin package media list urls into NetworkItems
                let mediaListItems = urls.mediaListURLs.compactMap { (url) -> NetworkItem? in
                    guard let itemKey = self.articleFetcher.itemKeyForURL(url, type: .image) else {
                        return nil
                    }
                    
                    let variant = self.articleFetcher.variantForURL(url, type: .image)
                    
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.articleFetcher.urlRequestFromPersistence(with: url, persistType: .image) else {
                        return nil
                    }
                    
                    return NetworkItem(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest, cacheItem: nil)
                }
                
                // group into dictionary of the same itemKey for use in filtering out variants
                var similarItemsDictionary: [CacheController.ItemKey: [NetworkItem]] = [:]
                for item in mediaListItems {
                    if var existingItems = similarItemsDictionary[item.itemKeyAndVariant.itemKey] {
                        existingItems.append(item)
                        similarItemsDictionary[item.itemKeyAndVariant.itemKey] = existingItems
                    } else {
                        similarItemsDictionary[item.itemKeyAndVariant.itemKey] = [item]
                    }
                }
                
                // filter out any variants that image cache controller should not download (i.e. multiple sizes of the same image)
                var finalMediaListItems: [NetworkItem] = []
                for item in mediaListItems {
                    guard let similarItems = similarItemsDictionary[item.itemKeyAndVariant.itemKey] else {
                        continue
                    }
                    
                    let allVariantItems = similarItems.map { $0.itemKeyAndVariant }
                    if self.imageController.shouldDownloadVariantForAllVariantItems(variant: item.itemKeyAndVariant.variant, allVariantItems) {
                        finalMediaListItems.append(item)
                    }
                }
                // end package media list urls into NetworkItems
                
                // begin image info urls into NetworkItems
                let imageInfoItems = urls.imageInfoURLs.compactMap { (url) -> NetworkItem? in
                    guard let itemKey = self.articleFetcher.itemKeyForURL(url, type: .imageInfo) else {
                        return nil
                    }
                    
                    let variant = self.articleFetcher.variantForURL(url, type: .imageInfo)
                    guard let itemKeyAndVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: variant),
                        let urlRequest = self.articleFetcher.urlRequestFromPersistence(with: url, persistType: .imageInfo) else {
                        return nil
                    }
                    
                    return NetworkItem(itemKeyAndVariant: itemKeyAndVariant, url: url, urlRequest: urlRequest, cacheItem: nil)
                }
                
                // consolidate list of network items to compare with downloaded cached items
                // remove list also contains mobile-html & media-list urls for comparison purposes only, otherwise it will think they should be removed from cache.
                let networkItemsForAdd: Set<NetworkItem> = Set(offlineResourceItems + finalMediaListItems + imageInfoItems)
                let networkItemsForRemove: Set<NetworkItem> = Set([mobileHTMLNetworkItem] + [mediaListNetworkItem] + offlineResourceItems + finalMediaListItems + imageInfoItems)
                
                self.context.perform { [weak self] in
                    guard let self = self else {
                        return
                    }
                    guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: self.context) else {
                        completion(.failure(ArticleCacheDBWriterSyncError.cannotFindCacheGroup))
                        return
                    }
                    guard let cacheItems = group.cacheItems as? Set<CacheItem> else {
                        completion(.failure(ArticleCacheDBWriterSyncError.cannotFindCacheItem))
                        return
                    }
                    
                    let downloadedCacheItems = cacheItems.compactMap { (cacheItem) -> NetworkItem? in
                        guard let itemKey = cacheItem.key,
                        let itemKeyandVariant = CacheController.ItemKeyAndVariant(itemKey: itemKey, variant: cacheItem.variant),
                            cacheItem.isDownloaded == true else {
                            return nil
                        }
                        
                        return NetworkItem(itemKeyAndVariant: itemKeyandVariant, url: cacheItem.url, urlRequest: nil, cacheItem: cacheItem)
                    }
                    
                    let downloadedCacheItemsSet = Set(downloadedCacheItems)
                    
                    // determine final set of new items that need to be cached
                    let filteredNewItems = networkItemsForAdd.subtracting(downloadedCacheItemsSet)
                    let filteredNewURLRequests = filteredNewItems.compactMap { $0.urlRequest }
                    
                    // determine set of old items that need to be removed
                    let filteredOldItems = downloadedCacheItemsSet.subtracting(networkItemsForRemove)
                    
                    // create list of unique item key and variants (those with 1 cache group) to return to CacheController for file deletion. Otherwise delete from group.
                    var uniqueOldItemKeyAndVariants: [CacheController.ItemKeyAndVariant] = []
                    for filteredOldItem in filteredOldItems {
                        if let cacheItem = filteredOldItem.cacheItem {
                            if cacheItem.cacheGroups?.count == 1 {
                                uniqueOldItemKeyAndVariants.append(filteredOldItem.itemKeyAndVariant)
                            } else {
                                group.removeFromCacheItems(cacheItem)
                            }
                        }
                    }
                    
                    // cache nonCached urls
                    self.cacheItems(groupKey: groupKey, items: filteredNewItems) { (result) in
                        switch result {
                        case .success:
                            let result = CacheDBWritingSyncSuccessResult(addURLRequests: filteredNewURLRequests, removeItemKeyAndVariants: uniqueOldItemKeyAndVariants)
                            completion(.success(result))
                        case .failure(let error):
                            completion(.failure(error))
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
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: self.context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for item in items {
                
                guard let url = item.url,
                    item.urlRequest != nil else {
                        assertionFailure("These need to be populated at this point. They are only optional to be able to compare cleanly with a set of converted CacheItems to NetworkItems")
                        continue
                }
                
                let itemKey = item.itemKeyAndVariant.itemKey
                let variant = item.itemKeyAndVariant.variant
                
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: url, itemKey: itemKey, variant: variant, in: self.context) else {
                    completion(.failure(ArticleCacheDBWriterSyncError.failureFetchOrCreateCacheItem))
                    return
                }
                
                group.addToCacheItems(item)
            }
            
            CacheDBWriterHelper.save(moc: self.context, completion: completion)
        }
    }
}
