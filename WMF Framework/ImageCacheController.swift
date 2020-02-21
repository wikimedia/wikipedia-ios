
import Foundation

final class ImageCacheController: CacheController {
    
    //batch inserts to db and selectively decides which file variant to download. Used when inserting multiple image urls from media-list endpoint via ArticleCacheController.
    func add(urls: [URL], groupKey: GroupKey, individualCompletion: @escaping IndividualCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {

        //note: We're avoiding gatekeeper logic here for now. As this is called from ArticleDBWriter, there will be multiple different URLs trying to cache from the same groupKey (desktop article url), which confuses gatekeeper.
        dbWriter.add(urls: urls, groupKey: groupKey) { [weak self] (result) in
            self?.finishDBAdd(groupKey: groupKey, individualCompletion: individualCompletion, groupCompletion: groupCompletion, result: result)
        }
    }
}
