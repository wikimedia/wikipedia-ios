
import Foundation

final class ImageCacheController: CacheController {
    
    func cache(url: URL, groupKey: String) {
        guard let imageDBWriter = dbWriter as? ImageCacheDBWriter else {
            return
        }
        
        imageDBWriter.cache(url: url, groupKey: groupKey)
    }
}
