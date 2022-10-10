import Foundation
import WMF

@objc public class SharedContainerCacheHousekeeping: NSObject, SharedContainerCacheHousekeepingProtocol {
    public static func deleteStaleCachedItems(in subdirectoryPathComponent: String) {
        SharedContainerCache<TalkPageCache>.deleteStaleCachedItems(in: SharedContainerCacheCommonNames.talkPageCache)
    }


}
