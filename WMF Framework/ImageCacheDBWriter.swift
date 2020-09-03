
import Foundation

enum ImageCacheDBWriterError: Error {
    case batchURLInsertFailure
    case missingExpectedItemsOutOfRequestHeader
    case unableToDetermineURLRequest
}

final class ImageCacheDBWriter: CacheDBWriting {

    private let cacheBackgroundContext: NSManagedObjectContext
    private let imageFetcher: ImageFetcher
    
    var fetcher: CacheFetching {
        return imageFetcher
    }
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(imageFetcher: ImageFetcher, cacheBackgroundContext: NSManagedObjectContext) {
        self.imageFetcher = imageFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithURLRequests) -> Void) {
        
        guard let urlRequest = imageFetcher.urlRequestFromPersistence(with: url, persistType: .image) else {
            completion(.failure(ImageCacheDBWriterError.unableToDetermineURLRequest))
            return
        }
        
        cacheImages(groupKey: groupKey, urlRequests: [urlRequest], completion: completion)
    }
    
    func add(urls: [URL], groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithURLRequests) -> Void) {
        
        let urlRequests = urls.compactMap { imageFetcher.urlRequestFromPersistence(with: $0, persistType: .image) }
        
        cacheImages(groupKey: groupKey, urlRequests: urlRequests, completion: completion)
    }
    
    func markDownloaded(urlRequest: URLRequest, response: HTTPURLResponse?, completion: @escaping (CacheDBWritingResult) -> Void) {
        
        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.missingMOC))
            return
        }
        
        guard let itemKey = fetcher.itemKeyForURLRequest(urlRequest) else {
            completion(.failure(CacheDBWritingMarkDownloadedError.unableToDetermineItemKey))
            return
        }
        
        let variant = fetcher.variantForURLRequest(urlRequest)
    
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, variant: variant, in: context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            cacheItem.isDownloaded = true
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func shouldDownloadVariant(itemKey: CacheController.ItemKey, variant: String?) -> Bool {
        
        guard let variant = variant else {
            return true
        }
        
        let context = self.cacheBackgroundContext

        var result: Bool = false
        context.performAndWait {
        
            let allVariantCacheItems = CacheDBWriterHelper.allVariantItems(itemKey: itemKey, in: context)
                let allVariantItems = allVariantCacheItems.compactMap { return CacheController.ItemKeyAndVariant(itemKey: $0.key, variant: $0.variant) }
                
                result = shouldDownloadVariantForAllVariantItems(variant: variant, allVariantItems)
        }

        return result
    }
    
    func shouldDownloadVariantForAllVariantItems(variant: String?, _ allVariantItems: [CacheController.ItemKeyAndVariant]) -> Bool {
        
        guard let variant = variant else {
            return true
        }
        
        var sortableVariantItems = allVariantItems
            
        sortableVariantItems.sortAsImageItemKeyAndVariants()
        
        switch (UIScreen.main.scale, sortableVariantItems.count) {
        case (1.0, _), (_, 1):
            guard let firstVariant = sortableVariantItems.first?.variant else {
                return true
            }
            return variant == firstVariant
        case (2.0, _):
            guard let secondVariant = sortableVariantItems[safeIndex: 1]?.variant else {
                return true
            }
            return variant == secondVariant
        case (3.0, _):
            guard let lastVariant = sortableVariantItems.last?.variant else {
                return true
            }
            return variant == lastVariant
        default:
            return false
        }
    }
}


private extension ImageCacheDBWriter {
    func cacheImages(groupKey: String, urlRequests: [URLRequest], completion: @escaping (CacheDBWritingResultWithURLRequests) -> Void) {
        
        let context = self.cacheBackgroundContext
        context.perform {
        
            let dispatchGroup = DispatchGroup()
            var successRequests: [URLRequest] = []
            var errorRequests: [URLRequest] = []
            
            for urlRequest in urlRequests {
                
                dispatchGroup.enter()
                
                guard let url = urlRequest.url,
                    let itemKey = self.imageFetcher.itemKeyForURLRequest(urlRequest) else {
                        errorRequests.append(urlRequest)
                        dispatchGroup.leave()
                        continue
                }
                
                let variant = self.imageFetcher.variantForURLRequest(urlRequest)
                    
                guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                    errorRequests.append(urlRequest)
                    dispatchGroup.leave()
                    continue
                }
                
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: url, itemKey: itemKey, variant: variant, in: context) else {
                    errorRequests.append(urlRequest)
                    dispatchGroup.leave()
                    continue
                }
                
                item.variant = variant
                group.addToCacheItems(item)
                
                CacheDBWriterHelper.save(moc: context) { (result) in
                    
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    switch result {
                    case .success:
                        successRequests.append(urlRequest)
                    case .failure:
                        errorRequests.append(urlRequest)
                    }
                }
            }
            
            dispatchGroup.notify(queue: DispatchQueue.global(qos: .userInitiated)) {

                if errorRequests.count > 0 && successRequests.count == 0 {
                    completion(.failure(ImageCacheDBWriterError.batchURLInsertFailure))
                    return
                }

                completion(.success(successRequests))
            }
        }
    }
}
