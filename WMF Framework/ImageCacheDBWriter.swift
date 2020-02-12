
import Foundation

enum ImageCacheDBWriterError: Error {
    case failureFetchOrCreateCacheGroup
    case failureFetchOrCreateCacheItem
    case missingExpectedItemsOutOfRequestHeader
}

final class ImageCacheDBWriter: CacheDBWriting {

    private let cacheBackgroundContext: NSManagedObjectContext
    private let imageFetcher: ImageFetcher
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(imageFetcher: ImageFetcher, cacheBackgroundContext: NSManagedObjectContext) {
        self.imageFetcher = imageFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithURLRequests) -> Void) {
        
        let urlRequest = imageFetcher.request(for: url, forceCache: false)
        
        cacheImage(groupKey: groupKey, urlRequest: urlRequest, completion: completion)
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
}


private extension ImageCacheDBWriter {
    func cacheImage(groupKey: String, urlRequest: URLRequest, completion: @escaping (CacheDBWritingResultWithURLRequests) -> Void) {
        
        guard let itemKey = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey],
            let variant = urlRequest.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant] else {
                completion(.failure(ImageCacheDBWriterError.missingExpectedItemsOutOfRequestHeader))
                return
        }
        
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
            
            item.variant = variant
            group.addToCacheItems(item)
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    let result = CacheDBWritingResultWithURLRequests.success([urlRequest])
                    completion(result)
                case .failure(let error):
                    let result = CacheDBWritingResultWithURLRequests.failure(error)
                    completion(result)
                }
            }
        }
    }
}
