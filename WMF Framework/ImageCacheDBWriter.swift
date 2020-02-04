
import Foundation

enum ImageCacheDBWriterError: Error {
    case missingItemKey
    case failureFetchOrCreateCacheGroup
    case failureFetchOrCreateCacheItem
}

final class ImageCacheDBWriter: CacheDBWriting {

    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(cacheBackgroundContext: NSManagedObjectContext) {
        self.cacheBackgroundContext = cacheBackgroundContext
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey?, variantId: String?, variantGroupKey: String? = nil, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        
        guard let itemKey = itemKey else {
            assertionFailure("ImageCacheDBWriter missing itemKey.")
            completion(.failure(ImageCacheDBWriterError.missingItemKey))
            return
        }
        
        cacheImage(groupKey: groupKey, itemKey: itemKey, variantId: variantId, variantGroupKey: variantGroupKey, completion: completion)
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
}

private extension ImageCacheDBWriter {
    
    func cacheImage(groupKey: String, itemKey: String, variantId: String?, variantGroupKey: String?, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        
        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                completion(.failure(ImageCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                completion(.failure(ImageCacheDBWriterError.failureFetchOrCreateCacheItem))
                return
            }
            
            if let variantGroupKey = variantGroupKey,
                let variantGroup = CacheDBWriterHelper.fetchOrCreateVariantCacheGroup(with: variantGroupKey, in: context) {
                item.variantId = variantId
                variantGroup.addToCacheItems(item)
            }
            
            group.addToCacheItems(item)
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    let result = CacheDBWritingResultWithItemKeys.success([itemKey])
                    completion(result)
                case .failure(let error):
                    let result = CacheDBWritingResultWithItemKeys.failure(error)
                    completion(result)
                }
            }
        }
    }
}
