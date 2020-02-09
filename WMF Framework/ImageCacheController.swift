
import Foundation

enum ImageCacheControllerError: Error {
    case allItemsFailedInBatchAddDBWriter
}

final class ImageCacheController: CacheController {

    //batch inserts to db and selectively decides which file variant to download. Used when inserting multiple image urls from media-list endpoint via ArticleCacheController.
    func add(urls: [URL], groupKey: GroupKey, itemCompletion: @escaping ItemCompletionBlock, groupCompletion: @escaping GroupCompletionBlock) {
        
        dbWriter.add(urls: urls, groupKey: groupKey) { [weak self] (result) in
            self?.finishDBAdd(groupKey: groupKey, itemCompletion: itemCompletion, groupCompletion: groupCompletion, result: result)
        }
    }
}
