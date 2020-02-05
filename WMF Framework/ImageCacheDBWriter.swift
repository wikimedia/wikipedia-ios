
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
        assertionFailure("ImageCacheDBWriter determines it's own itemKey (with variants) internally, do not pass one in.")
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        
        let itemKey = ImageCacheDBWriter.identifierForURL(url)
        let variant = String(ImageCacheDBWriter.variantForURL(url))
        let variantGroupKey = ImageCacheDBWriter.cacheKeyForURL(url)
        cacheImage(groupKey: groupKey, itemKey: itemKey, variant: variant, variantGroupKey: variantGroupKey, completion: completion)
    }
    
    func shouldDownloadVariant(itemKey: CacheController.ItemKey) -> Bool {
        let context = self.cacheBackgroundContext
        
        var result: Bool = true
        context.performAndWait {
            
            var allVariantItems = CacheDBWriterHelper.allVariantItems(for: itemKey, in: context)
            
            allVariantItems.sort { (lhs, rhs) -> Bool in
                
                guard let lhsVariant = lhs.variant,
                    let lhsSize = Int64(lhsVariant),
                    let rhsVariant = rhs.variant,
                    let rhsSize = Int64(rhsVariant) else {
                        return true
                }
                
                return lhsSize < rhsSize
            }
            
            switch (UIScreen.main.scale, allVariantItems.count) {
            case (1.0, _), (_, 1):
                guard let firstKey = allVariantItems.first?.key else {
                    result = true
                    return
                }
                result = itemKey == firstKey
            case (2.0, _):
                guard let secondKey = allVariantItems[safeIndex: 2]?.key else {
                    result = true
                    return
                }
                result = itemKey == secondKey
            case (3.0, _):
                guard let lastKey = allVariantItems.last?.key else {
                    result = true
                    return
                }
                result = itemKey == lastKey
            default:
                result = true
            }
        }
        
        return result
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        //tonitodo
    }
    
    static func cacheKeyForURL(_ url: URL) -> String {
        guard let host = url.host, let imageName = WMFParseImageNameFromSourceURL(url) else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
        return (host + "__" + imageName).precomposedStringWithCanonicalMapping
    }
    
    static func variantForURL(_ url: URL) -> Int64 { // A return value of 0 indicates the original size
        let sizePrefix = WMFParseSizePrefixFromSourceURL(url)
        return Int64(sizePrefix == NSNotFound ? 0 : sizePrefix)
    }
    
    static func identifierForURL(_ url: URL) -> String {
        let key = cacheKeyForURL(url)
        let variant = variantForURL(url)
        return "\(key)__\(variant)".precomposedStringWithCanonicalMapping
    }
    
    static func identifierForKey(_ key: String, variant: Int64) -> String {
        return "\(key)__\(variant)".precomposedStringWithCanonicalMapping
    }
}

private extension ImageCacheDBWriter {
    
    func cacheImage(groupKey: String, itemKey: String, variant: String, variantGroupKey: String, completion: @escaping (CacheDBWritingResultWithItemKeys) -> Void) {
        
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
            item.variantGroupKey = variantGroupKey
            
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
