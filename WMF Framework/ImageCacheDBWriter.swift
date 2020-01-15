
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
    
    func add(url: URL, groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey, completion: @escaping (CacheDBWritingResult) -> Void) {
        cacheImage(groupKey: groupKey, itemKey: itemKey, completion: completion)
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: (CacheDBWritingResult) -> Void) {
        
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
}

private extension ImageCacheDBWriter {
    
    func cacheImage(groupKey: String, itemKey: String, completion: @escaping (CacheDBWritingResult) -> Void) {
        
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
                    let result = CacheDBWritingResult.success([itemKey])
                    completion(result)
                case .failure(let error):
                    let result = CacheDBWritingResult.failure(error)
                    completion(result)
                }
            }
        }
    }
}
