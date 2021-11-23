
import Foundation

extension WMFNotificationsController {
    @objc func updatePushNotificationsCacheWithNewPrimaryAppLanguage(_ primaryAppLanguage: MWKLanguageLink) {
        let sharedCache = SharedContainerCache<PushNotificationsCache>.init(pathComponent: .pushNotificationsCache, defaultCache: { PushNotificationsCache(settings: .default, notifications: []) })
        var cache = sharedCache.loadCache()
        cache.settings = PushNotificationsSettings(primaryLanguageCode: primaryAppLanguage.languageCode, primaryLanguageVariantCode: primaryAppLanguage.languageVariantCode)
        sharedCache.saveCache(cache)
    }
}
