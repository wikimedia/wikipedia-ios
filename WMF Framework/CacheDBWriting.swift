import Foundation

enum SaveResult {
    case success
    case failure(Error)
}

enum CacheDBWritingResultWithURLRequests {
    case success([URLRequest])
    case failure(Error)
}

enum CacheDBWritingResultWithItemAndVariantKeys {
    case success([CacheController.ItemKeyAndVariant])
    case failure(Error)
}

enum CacheDBWritingResult {
    case success
    case failure(Error)
}

enum CacheDBWritingMarkDownloadedError: Error {
    case cannotFindCacheGroup
    case cannotFindCacheItem
    case unableToDetermineItemKey
    case missingMOC
}

enum CacheDBWritingRemoveError: Error {
    case cannotFindCacheGroup
    case cannotFindCacheItem
    case missingMOC
}

protocol CacheDBWriting: CacheTaskTracking {
    var context: NSManagedObjectContext { get }
    
    typealias CacheDBWritingCompletionWithURLRequests = (CacheDBWritingResultWithURLRequests) -> Void
    typealias CacheDBWritingCompletionWithItemAndVariantKeys = (CacheDBWritingResultWithItemAndVariantKeys) -> Void
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests)
    func add(urls: [URL], groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests)
    func shouldDownloadVariant(itemKey: CacheController.ItemKey, variant: String?) -> Bool
    func shouldDownloadVariant(urlRequest: URLRequest) -> Bool
    func shouldDownloadVariantForAllVariantItems(variant: String?, _ allVariantItems: [CacheController.ItemKeyAndVariant]) -> Bool
    var fetcher: CacheFetching { get }

    // default implementations
    func remove(itemAndVariantKey: CacheController.ItemKeyAndVariant, completion: @escaping (CacheDBWritingResult) -> Void)
    func remove(groupKey: String, completion: @escaping (CacheDBWritingResult) -> Void)
    func fetchKeysToRemove(for groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithItemAndVariantKeys)
    func markDownloaded(urlRequest: URLRequest, response: HTTPURLResponse?, completion: @escaping (CacheDBWritingResult) -> Void)
}

extension CacheDBWriting {

    func fetchKeysToRemove(for groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithItemAndVariantKeys) {
        context.perform {
            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: self.context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheGroup))
                return
            }
            guard let cacheItems = group.cacheItems as? Set<CacheItem> else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            
            let cacheItemsToRemove = cacheItems.filter({ (cacheItem) -> Bool in
                return cacheItem.cacheGroups?.count == 1
            })

            completion(.success(cacheItemsToRemove.compactMap { CacheController.ItemKeyAndVariant(itemKey: $0.key, variant: $0.variant) }))
        }
    }
    
    func remove(itemAndVariantKey: CacheController.ItemKeyAndVariant, completion: @escaping (CacheDBWritingResult) -> Void) {
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemAndVariantKey.itemKey, variant: itemAndVariantKey.variant, in: self.context) else {
                completion(.failure(CacheDBWritingRemoveError.cannotFindCacheItem))
                return
            }
            
            self.context.delete(cacheItem)
            
            CacheDBWriterHelper.save(moc: self.context) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func remove(groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResult) -> Void) {
        context.perform {
            guard let cacheGroup = CacheDBWriterHelper.cacheGroup(with: groupKey, in: self.context) else {
                completion(.failure(CacheDBWritingRemoveError.cannotFindCacheItem))
                return
            }
            
            self.context.delete(cacheGroup)
            
            CacheDBWriterHelper.save(moc: self.context) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func shouldDownloadVariant(urlRequest: URLRequest) -> Bool {
        guard let itemKey = fetcher.itemKeyForURLRequest(urlRequest) else {
            return false
        }
        
        let variant = fetcher.variantForURLRequest(urlRequest)
        
        return shouldDownloadVariant(itemKey: itemKey, variant: variant)
    }
}
