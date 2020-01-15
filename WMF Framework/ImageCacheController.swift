
import Foundation

final class ImageCacheController: CacheController {
    
    override func notifyAllDownloaded(groupKey: String, itemKey: String) {
        super.notifyAllDownloaded(groupKey: groupKey, itemKey: itemKey)
    }
    
    override func notifyAllRemoved(groupKey: String) {
        super.notifyAllRemoved(groupKey: groupKey)
    }
    
}
