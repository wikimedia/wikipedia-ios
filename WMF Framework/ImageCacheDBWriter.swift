
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
        
        guard let urlRequest = imageFetcher.urlRequestFromURL(url, type: .image) else {
            completion(.failure(ImageCacheDBWriterError.unableToDetermineURLRequest))
            return
        }
        
        cacheImages(groupKey: groupKey, urlRequests: [urlRequest], completion: completion)
    }
    
    func add(urls: [URL], groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithURLRequests) -> Void) {
        
        let urlRequests = urls.compactMap { imageFetcher.urlRequestFromURL($0, type: .image) }
        
        cacheImages(groupKey: groupKey, urlRequests: urlRequests, completion: completion)
    }
    
    func shouldDownloadVariant(itemKey: CacheController.ItemKey, variant: String?) -> Bool {
        
        guard let variant = variant else {
            return true
        }
        
        let context = self.cacheBackgroundContext

        var result: Bool = false
        context.performAndWait {

            var allVariantItems = CacheDBWriterHelper.allVariantItems(itemKey: itemKey, in: context)

            allVariantItems.sortAsImageCacheItems()

            switch (UIScreen.main.scale, allVariantItems.count) {
            case (1.0, _), (_, 1):
                guard let firstVariant = allVariantItems.first?.variant else {
                    result = true
                    return
                }
                result = variant == firstVariant
            case (2.0, _):
                guard let secondVariant = allVariantItems[safeIndex: 1]?.variant else {
                    result = true
                    return
                }
                result = variant == secondVariant
            case (3.0, _):
                guard let lastVariant = allVariantItems.last?.variant else {
                    result = true
                    return
                }
                result = variant == lastVariant
            default:
                result = false
            }
        }

        return result
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
