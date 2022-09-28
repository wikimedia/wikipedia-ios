import Foundation
import WMF

@objc public class SharedContainerCacheHousekeeping: NSObject {
    @objc public var housekeeping: SharedContainerCacheHousekeepingProtocol {
        let talkPageCache = SharedContainerCache<TalkPageCache>.init(pathComponent: .talkPageCache) {
            TalkPageCache(talkPages: [])}
        return talkPageCache
    }
}
