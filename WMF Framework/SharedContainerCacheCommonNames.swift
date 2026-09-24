import Foundation
import WMFData

@objc public class SharedContainerCacheCommonNames: NSObject {
    @objc public static let pushNotificationsCache = "Push Notifications Cache"
    @objc public static let talkPageCache = "Talk Page Cache"
    public static let widgetCache = "Widget Cache"
    @objc public static let didYouKnowCache = "Did You Know Cache"
}

@objc public class SharedContainerCacheClearFeaturedArticleWrapper: NSObject {
    @objc public static func clearOutFeaturedArticleWidgetCache() {
        let sharedCache = WMFSharedContainerCache(fileName: SharedContainerCacheCommonNames.widgetCache)
        var updatedCache = sharedCache.loadCache() ?? WidgetCache(settings: .default, featuredContent: nil)
        updatedCache.featuredContent = nil
        sharedCache.saveCache(updatedCache)
    }
}
