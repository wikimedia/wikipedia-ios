
import Foundation

enum ImageCacheDBWriterError: Error {
    case batchURLInsertFailure
}

final class ImageCacheDBWriter: CacheDBWriting {

    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init(cacheBackgroundContext: NSManagedObjectContext) {
        self.cacheBackgroundContext = cacheBackgroundContext
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey, completion: @escaping CacheDBWritingCompletionWithItems) {
        assertionFailure("ImageCacheDBWriter determines it's own itemKeys (with variants) internally, do not pass one in.")
    }
    
    func add(urls: [URL], groupKey: String, completion: @escaping CacheDBWritingCompletionWithItems) {
        cacheImages(urls: urls, groupKey: groupKey, completion: completion)
    }
    
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithItems) {

        cacheImages(urls: [url], groupKey: groupKey, completion: completion)
    }
    
    func shouldDownloadVariant(itemKey: CacheController.ItemKey) -> Bool {
        let context = self.cacheBackgroundContext
        
        var result: Bool = false
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
                guard let secondKey = allVariantItems[safeIndex: 1]?.key else {
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
                result = false
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
    
    func cacheImages(urls: [URL], groupKey: String, completion: @escaping (CacheDBWritingResultWithItems) -> Void) {
        
        
        let context = self.cacheBackgroundContext
        context.perform {
            
            let dispatchGroup = DispatchGroup()
            
            var successItems: [CacheDBWritingResultItem] = []
            var errorURLs: [URL] = []
            
            for url in urls {
                
                dispatchGroup.enter()
                
                let itemKey = ImageCacheDBWriter.identifierForURL(url)
                let variant = String(ImageCacheDBWriter.variantForURL(url))
                let variantGroupKey = ImageCacheDBWriter.cacheKeyForURL(url)
                
                guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                    
                    errorURLs.append(url)
                    dispatchGroup.leave()
                    return
                }
                
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                    
                    errorURLs.append(url)
                    dispatchGroup.leave()
                    return
                }
                
                item.url = url
                item.variant = variant
                item.variantGroupKey = variantGroupKey
                
                group.addToCacheItems(item)
                
                CacheDBWriterHelper.save(moc: context) { (result) in
                    
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    switch result {
                    case .success:
                        let resultItem = CacheDBWritingResultItem(itemKey: itemKey, url: url)
                        successItems.append(resultItem)
                    case .failure:
                        errorURLs.append(url)
                    }
                }
            }
            
            dispatchGroup.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                
                if errorURLs.count > 0 && successItems.count == 0 {
                    completion(.failure(ImageCacheDBWriterError.batchURLInsertFailure))
                    return
                }
                
                completion(.success(successItems))
            }
        }
    }
}
