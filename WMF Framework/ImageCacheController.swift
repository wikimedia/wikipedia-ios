
import Foundation

final class ImageCacheController: CacheController {

    override public func add(url: URL, groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {
        
        //note: We're avoiding gatekeeper logic here for now. As this is called from ArticleDBWriter, there will be multiple different URLs trying to cache from the same groupKey (desktop article url), which confuses gatekeeper.
        dbWriter.add(url: url, groupKey: groupKey) { [weak self] (result) in
            self?.finishDBAdd(groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion, result: result)
        }
    }
}
