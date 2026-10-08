import Foundation
import WMFData

extension WMFNotificationsController {
    @objc func updatePushNotificationsCacheWithNewPrimaryAppLanguage(_ primaryAppLanguage: MWKLanguageLink) {
        let sharedCache = WMFSharedContainerCache(fileName: SharedContainerCacheCommonNames.pushNotificationsCache)
        var cache = sharedCache.loadCache() ?? PushNotificationsCache(settings: .default, notifications: [])
        cache.settings = PushNotificationsSettings(primaryLanguageCode: primaryAppLanguage.languageCode, primaryLocalizedName: primaryAppLanguage.localizedName, primaryLanguageVariantCode: primaryAppLanguage.languageVariantCode)
        sharedCache.saveCache(cache)
    }
}
