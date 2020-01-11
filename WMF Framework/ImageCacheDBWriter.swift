
import Foundation

final class ImageCacheDBWriter: CacheDBWriting {
    
    weak var delegate: CacheDBWritingDelegate?
    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(cacheBackgroundContext: NSManagedObjectContext, delegate: CacheDBWritingDelegate? = nil) {
        self.cacheBackgroundContext = cacheBackgroundContext
        self.delegate = delegate
    }
    
    func add(url: URL, groupKey: String, itemKey: String) {

        cacheImage(groupKey: groupKey, itemKey: itemKey)
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
}

private extension ImageCacheDBWriter {
    
    func cacheImage(groupKey: String, itemKey: String) {
        
        if delegate?.shouldQueue(groupKey: groupKey, itemKey: itemKey) ?? false {
            delegate?.queue(groupKey: groupKey, itemKey: itemKey)
            return
        }
        
        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                return
            }
            
            guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                return
            }
            
            group.addToCacheItems(item)
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    self.delegate?.dbWriterDidAdd(groupKey: groupKey, itemKey: itemKey)
                case .failure:
                    self.delegate?.dbWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                }
            }
        }
    }
}
