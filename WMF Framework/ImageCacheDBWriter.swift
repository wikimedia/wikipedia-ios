
import Foundation

enum ImageCacheDBWriterError: Error {
    case failureFetchOrCreateCacheGroup
    case failureFetchOrCreateCacheItem
}

final class ImageCacheDBWriter: CacheDBWriting {

    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(cacheBackgroundContext: NSManagedObjectContext) {
        self.cacheBackgroundContext = cacheBackgroundContext
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        cacheImage(groupKey: groupKey, itemKey: itemKey, completion: completion)
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
}

private extension ImageCacheDBWriter {
    
    func cacheImage(groupKey: String, itemKey: String, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        
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
