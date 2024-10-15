import Foundation
import WMF

@objc public class SharedContainerCacheHousekeeping: NSObject, SharedContainerCacheHousekeepingProtocol {
    public static func deleteStaleCachedItems(in subdirectoryPathComponent: String, cleanupLevel: WMFCleanupLevel) {
        SharedContainerCache.deleteStaleCachedItems(in: subdirectoryPathComponent, cleanupLevel: cleanupLevel)
    }
}
