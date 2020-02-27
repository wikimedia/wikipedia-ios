
import Foundation

final class ImageCacheController: CacheController {
    
    //batch inserts to db and selectively decides which file variant to download. Used when inserting multiple image urls from media-list endpoint via ArticleCacheController.
    func add(urls: [URL], groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {

        //tonitodo: DRY gatekeeper logic with superclass
        if gatekeeper.shouldQueueAddCompletion(groupKey: groupKey) {
            gatekeeper.queueAddCompletion(groupKey: groupKey) {
                self.add(urls: urls, groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion)
                return
            }
        } else {
            gatekeeper.addCurrentlyAddingGroupKey(groupKey)
        }
        
        if gatekeeper.numberOfQueuedGroupCompletions(for: groupKey) > 0 {
            gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
            return
        }
        
        gatekeeper.queueGroupCompletion(groupKey: groupKey, groupCompletion: groupCompletion)
        
        dbWriter.add(urls: urls, groupKey: groupKey) { [weak self] (result) in
            self?.finishDBAdd(groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion, result: result)
        }
    }
}
