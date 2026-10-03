import Foundation
import WMF
import WMFData

@objc public class SharedContainerCacheHousekeeping: NSObject {
    /// Persist only the last 50 cached items, or none for `.high`
    @objc public static func deleteStaleCachedItems(in subdirectoryPathComponent: String, cleanupLevel: WMFCleanupLevel) {
        let maxItemCount = cleanupLevel == .high ? 0 : 50
        WMFSharedContainerCache.deleteStaleCachedItems(in: subdirectoryPathComponent, keepingMostRecent: maxItemCount)
    }
}
