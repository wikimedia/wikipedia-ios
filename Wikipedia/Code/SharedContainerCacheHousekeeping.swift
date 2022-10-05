import Foundation
import WMF

@objc public class SharedContainerCacheHousekeeping: NSObject {
    @objc public var housekeeping: SharedContainerCacheHousekeepingProtocol {
        let talkPageCache = SharedContainerCache<TalkPageCache>.init(fileName: String(), subdirectoryPathComponent: "Talk Page Cache", defaultCache: {
            TalkPageCache(talkPages: [])
        })
        return talkPageCache
    }
}
