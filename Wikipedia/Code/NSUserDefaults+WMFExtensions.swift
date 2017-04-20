let WMFAppLaunchDateKey = "WMFAppLaunchDateKey"
let WMFAppBecomeActiveDateKey = "WMFAppBecomeActiveDateKey"
let WMFAppResignActiveDateKey = "WMFAppResignActiveDateKey"
let WMFOpenArticleURLKey = "WMFOpenArticleURLKey"
let WMFAppSiteKey = "Domain"
let WMFSearchURLKey = "WMFSearchURLKey"
let WMFMigrateHistoryListKey = "WMFMigrateHistoryListKey"
let WMFMigrateToSharedContainerKey = "WMFMigrateToSharedContainerKey"
let WMFMigrateSavedPageListKey = "WMFMigrateSavedPageListKey"
let WMFMigrateBlackListKey = "WMFMigrateBlackListKey"
let WMFMigrateToFixArticleCacheKey = "WMFMigrateToFixArticleCacheKey2"
let WMFDidMigrateToGroupKey = "WMFDidMigrateToGroup"
let WMFDidMigrateToCoreDataFeedKey = "WMFDidMigrateToCoreDataFeedKey"
let WMFMostRecentInTheNewsNotificationDateKey = "WMFMostRecentInTheNewsNotificationDate"
let WMFInTheNewsMostRecentDateNotificationCountKey = "WMFInTheNewsMostRecentDateNotificationCount"
let WMFDidShowNewsNotificatonInFeedKey = "WMFDidShowNewsNotificatonInFeedKey"
let WMFInTheNewsNotificationsEnabled = "WMFInTheNewsNotificationsEnabled"
let WMFFeedRefreshDateKey = "WMFFeedRefreshDateKey"
let WMFLocationAuthorizedKey = "WMFLocationAuthorizedKey"
let WMFPlacesDidPromptForLocationAuthorization = "WMFPlacesDidPromptForLocationAuthorization"
let WMFExploreDidPromptForLocationAuthorization = "WMFExploreDidPromptForLocationAuthorization"
let WMFPlacesHasAppeared = "WMFPlacesHasAppeared"

//Legacy Keys
let WMFOpenArticleTitleKey = "WMFOpenArticleTitleKey"
let WMFSearchLanguageKey = "WMFSearchLanguageKey"


public extension UserDefaults {
    
    public class func wmf_userDefaults() -> UserDefaults {
#if WMF_NO_APP_GROUP
        return UserDefaults.standard
#else
        guard let defaults = UserDefaults(suiteName: WMFApplicationGroupIdentifier) else {
            assert(false)
            return UserDefaults.standard
        }
        return defaults
#endif
    }
    
    public class func wmf_migrateToWMFGroupUserDefaultsIfNecessary() {
        let newDefaults = self.wmf_userDefaults()
        let didMigrate = newDefaults.bool(forKey: WMFDidMigrateToGroupKey)
        if (!didMigrate) {
            let oldDefaults = UserDefaults.standard
            let oldDefaultsDictionary = oldDefaults.dictionaryRepresentation()
            for (key, value) in oldDefaultsDictionary {
                let lowercaseKey = key.lowercased()
                if lowercaseKey.hasPrefix("apple") || lowercaseKey.hasPrefix("ns") {
                    continue
                }
                newDefaults.set(value, forKey: key)
            }
            newDefaults.set(true, forKey: WMFDidMigrateToGroupKey)
            newDefaults.synchronize()
        }
    }

    public func wmf_dateForKey(_ key: String) -> Date? {
        return self.object(forKey: key) as? Date
    }

    public func wmf_appLaunchDate() -> Date? {
        return self.wmf_dateForKey(WMFAppLaunchDateKey)
    }
    
    public func wmf_setAppLaunchDate(_ date: Date) {
        self.set(date, forKey: WMFAppLaunchDateKey)
        self.synchronize()
    }
    
    public func wmf_appBecomeActiveDate() -> Date? {
        return self.wmf_dateForKey(WMFAppBecomeActiveDateKey)
    }
    
    public func wmf_setAppBecomeActiveDate(_ date: Date?) {
        if let date = date {
            self.set(date, forKey: WMFAppBecomeActiveDateKey)
        }else{
            self.removeObject(forKey: WMFAppBecomeActiveDateKey)
        }
        self.synchronize()
    }
    
    public func wmf_appResignActiveDate() -> Date? {
        return self.wmf_dateForKey(WMFAppResignActiveDateKey)
    }
    
    public func wmf_setAppResignActiveDate(_ date: Date?) {
        if let date = date {
            self.set(date, forKey: WMFAppResignActiveDateKey)
        }else{
            self.removeObject(forKey: WMFAppResignActiveDateKey)
        }
        self.synchronize()
    }
    
    public func wmf_setFeedRefreshDate(_ date: Date) {
        self.set(date, forKey: WMFFeedRefreshDateKey)
        self.synchronize()
    }
    
    public func wmf_feedRefreshDate() -> Date? {
        return self.wmf_dateForKey(WMFFeedRefreshDateKey)
    }
    
    public func wmf_setLocationAuthorized(_ authorized: Bool) {
        self.set(authorized, forKey: WMFLocationAuthorizedKey)
        self.synchronize()
    }
    
    public func wmf_locationAuthorized() -> Bool {
        return self.bool(forKey: WMFLocationAuthorizedKey)
    }
    
    
    public func wmf_setPlacesHasAppeared(_ hasAppeared: Bool) {
        self.set(hasAppeared, forKey: WMFPlacesHasAppeared)
        self.synchronize()
    }
    
    public func wmf_placesHasAppeared() -> Bool {
        return self.bool(forKey: WMFPlacesHasAppeared)
    }
    
    public func wmf_setPlacesDidPromptForLocationAuthorization(_ didPrompt: Bool) {
        self.set(didPrompt, forKey: WMFPlacesDidPromptForLocationAuthorization)
        self.synchronize()
    }
    
    public func wmf_placesDidPromptForLocationAuthorization() -> Bool {
        return self.bool(forKey: WMFPlacesDidPromptForLocationAuthorization)
    }
    
    public func wmf_setExploreDidPromptForLocationAuthorization(_ didPrompt: Bool) {
        self.set(didPrompt, forKey: WMFExploreDidPromptForLocationAuthorization)
        self.synchronize()
    }
    
    
    public func wmf_exploreDidPromptForLocationAuthorization() -> Bool {
        return self.bool(forKey: WMFExploreDidPromptForLocationAuthorization)
    }
    
    
    public func wmf_openArticleURL() -> URL? {
        if let url = self.url(forKey: WMFOpenArticleURLKey) {
            return url
        }else if let data = self.data(forKey: WMFOpenArticleTitleKey){
            if let title = NSKeyedUnarchiver.unarchiveObject(with: data) as? MWKTitle {
                self.wmf_setOpenArticleURL(title.mobileURL)
                return title.mobileURL
            }else{
                return nil
            }
        }else{
            return nil
        }
    }
    
    public func wmf_setOpenArticleURL(_ url: URL?) {
        guard let url = url else{
            self.removeObject(forKey: WMFOpenArticleURLKey)
            self.removeObject(forKey: WMFOpenArticleTitleKey)
            self.synchronize()
            return
        }
        guard !(url as NSURL).wmf_isNonStandardURL else{
            return;
        }
        
        self.set(url, forKey: WMFOpenArticleURLKey)
        self.synchronize()
    }

    public func wmf_setSendUsageReports(_ enabled: Bool) {
        self.set(NSNumber(value: enabled as Bool), forKey: "SendUsageReports")
        self.synchronize()

    }

    public func wmf_sendUsageReports() -> Bool {
        if let enabled = self.object(forKey: "SendUsageReports") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }
    
    public func wmf_setAppInstallDateIfNil(_ date: Date) {
        let previous = self.wmf_appInstallDate()
        
        if previous == nil {
            self.set(date, forKey: "AppInstallDate")
            self.synchronize()
        }
    }
    
    public func wmf_appInstallDate() -> Date? {
        if let date = self.object(forKey: "AppInstallDate") as? Date {
            return date
        }else{
            return nil
        }
    }
    
    public func wmf_setDaysInstalled(_ daysInstalled: NSNumber) {
        self.set(daysInstalled, forKey: "DailyLoggingStatsDaysInstalled")
        self.synchronize()
    }

    public func wmf_daysInstalled() -> NSNumber? {
        return self.object(forKey: "DailyLoggingStatsDaysInstalled") as? NSNumber
    }

    public func wmf_setShowSearchLanguageBar(_ enabled: Bool) {
        self.set(NSNumber(value: enabled as Bool), forKey: "ShowLanguageBar")
        self.synchronize()
        
    }
    
    public func wmf_showSearchLanguageBar() -> Bool {
        if let enabled = self.object(forKey: "ShowLanguageBar") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }
    
    public func wmf_currentSearchLanguageDomain() -> URL? {
        if let url = self.url(forKey: WMFSearchURLKey) {
            return url
        }else if let language = self.object(forKey: WMFSearchLanguageKey) as? String {
            let url = NSURL.wmf_URL(withDefaultSiteAndlanguage: language)
            self.wmf_setCurrentSearchLanguageDomain(url)
            return url
        }else{
            return nil
        }
    }
    
    public func wmf_setCurrentSearchLanguageDomain(_ url: URL?) {
        guard let url = url else{
            self.removeObject(forKey: WMFSearchURLKey)
            self.synchronize()
            return
        }
        guard !(url as NSURL).wmf_isNonStandardURL else{
            return;
        }
        
        self.set(url, forKey: WMFSearchURLKey)
        self.synchronize()
    }
    
    public func wmf_setDidShowTableOfContentsAndFindInPageIconPopovers(_ shown: Bool) {
        self.set(NSNumber(value: shown as Bool), forKey: "ShowTableOfContentsAndFindInPageIconPopovers")
        self.synchronize()
        
    }
    
    public func wmf_didShowTableOfContentsAndFindInPageIconPopovers() -> Bool {
        if let enabled = self.object(forKey: "ShowTableOfContentsAndFindInPageIconPopovers") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }

    public func wmf_setTableOfContentsIsVisibleInline(_ visibleInline: Bool) {
        self.set(NSNumber(value: visibleInline as Bool), forKey: "TableOfContentsIsVisibleInline")
        self.synchronize()
        
    }
    
    public func wmf_isTableOfContentsVisibleInline() -> Bool {
        if let enabled = self.object(forKey: "TableOfContentsIsVisibleInline") as? NSNumber {
            return enabled.boolValue
        }else{
            return true
        }
    }
    
    public func wmf_setDidFinishLegacySavedArticleImageMigration(_ didFinish: Bool) {
        self.set(didFinish, forKey: "DidFinishLegacySavedArticleImageMigration2")
        self.synchronize()
    }
    
    public func wmf_didFinishLegacySavedArticleImageMigration() -> Bool {
        return self.bool(forKey: "DidFinishLegacySavedArticleImageMigration2")
    }
    
    public func wmf_setDidMigrateHistoryList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateHistoryListKey)
        self.synchronize()
    }
    
    public func wmf_didMigrateHistoryList() -> Bool {
        return self.bool(forKey: WMFMigrateHistoryListKey)
    }

    public func wmf_setDidMigrateSavedPageList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateSavedPageListKey)
        self.synchronize()
    }
    
    public func wmf_didMigrateSavedPageList() -> Bool {
        return self.bool(forKey: WMFMigrateSavedPageListKey)
    }

    public func wmf_setDidMigrateBlackList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateBlackListKey)
        self.synchronize()
    }
    
    public func wmf_didMigrateBlackList() -> Bool {
        return self.bool(forKey: WMFMigrateBlackListKey)
    }
    
    public func wmf_setDidMigrateToFixArticleCache(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateToFixArticleCacheKey)
        self.synchronize()
    }
    
    public func wmf_didMigrateToFixArticleCache() -> Bool {
        return self.bool(forKey: WMFMigrateToFixArticleCacheKey)
    }
    
    public func wmf_setDidMigrateToSharedContainer(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateToSharedContainerKey)
        self.synchronize()
    }
    
    public func wmf_didMigrateToSharedContainer() -> Bool {
        return self.bool(forKey: WMFMigrateToSharedContainerKey)
    }

    public func wmf_setDidMigrateToNewFeed(_ didMigrate: Bool) {
        self.set(didMigrate, forKey: WMFDidMigrateToCoreDataFeedKey)
        self.synchronize()
    }
    
    public func wmf_didMigrateToNewFeed() -> Bool {
        return self.bool(forKey: WMFDidMigrateToCoreDataFeedKey)
    }
    
    public func wmf_mostRecentInTheNewsNotificationDate() -> Date? {
        return self.wmf_dateForKey(WMFMostRecentInTheNewsNotificationDateKey)
    }
    
    public func wmf_setMostRecentInTheNewsNotificationDate(_ date: Date) {
        self.set(date, forKey: WMFMostRecentInTheNewsNotificationDateKey)
        self.synchronize()
    }
    
    public func wmf_inTheNewsMostRecentDateNotificationCount() -> Int {
        return self.integer(forKey: WMFInTheNewsMostRecentDateNotificationCountKey)
    }
    
    public func wmf_setInTheNewsMostRecentDateNotificationCount(_ count: Int) {
        self.set(count, forKey: WMFInTheNewsMostRecentDateNotificationCountKey)
        self.synchronize()
    }
    
    public func wmf_inTheNewsNotificationsEnabled() -> Bool {
        return self.bool(forKey: WMFInTheNewsNotificationsEnabled)
    }
    
    public func wmf_setInTheNewsNotificationsEnabled(_ enabled: Bool) {
        self.set(enabled, forKey: WMFInTheNewsNotificationsEnabled)
        self.synchronize()
    }

    public func wmf_setDidShowNewsNotificationCardInFeed(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowNewsNotificatonInFeedKey)
        self.synchronize()
    }
    
    public func wmf_didShowNewsNotificationCardInFeed() -> Bool {
        return self.bool(forKey: WMFDidShowNewsNotificatonInFeedKey)
    }
}
