
import Foundation

final class ImageCacheController: CacheController {
    
    override public func toggleCache(url: URL) {
        guard let key = url.wmf_databaseKey else {
            return
        }
        
        if isCached(url: url) {
            dbWriter.remove(groupKey: key, itemKey: key)
        } else {
            add(url: url, groupKey: key, itemKey: key)
        }
    }
    
}
