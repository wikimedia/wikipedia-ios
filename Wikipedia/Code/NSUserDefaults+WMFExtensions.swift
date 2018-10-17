let WMFAppBecomeActiveDateKey = "WMFAppBecomeActiveDateKey"
let WMFAppResignActiveDateKey = "WMFAppResignActiveDateKey"
let WMFOpenArticleURLKey = "WMFOpenArticleURLKey"
let WMFAppSiteKey = "Domain"
let WMFSearchURLKey = "WMFSearchURLKey"
let WMFMigrateHistoryListKey = "WMFMigrateHistoryListKey"
let WMFMigrateToSharedContainerKey = "WMFMigrateToSharedContainerKey"
let WMFMigrateSavedPageListKey = "WMFMigrateSavedPageListKey"
let WMFMigrateBlackListKey = "WMFMigrateBlackListKey"
let WMFMigrateToFixArticleCacheKey = "WMFMigrateToFixArticleCacheKey3"
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
let WMFAppThemeName = "WMFAppThemeName"
let WMFIsImageDimmingEnabled = "WMFIsImageDimmingEnabled"
let WMFIsAutomaticTableOpeningEnabled = "WMFIsAutomaticTableOpeningEnabled"
let WMFDidShowThemeCardInFeed = "WMFDidShowThemeCardInFeed"
let WMFDidShowReadingListCardInFeed = "WMFDidShowReadingListCardInFeed"
let WMFDidShowEnableReadingListSyncPanelKey = "WMFDidShowEnableReadingListSyncPanelKey"
let WMFDidShowLoginToSyncSavedArticlesToReadingListPanelKey = "WMFDidShowLoginToSyncSavedArticlesToReadingListPanelKey"
let WMFDidShowLimitHitForUnsortedArticlesPanel = "WMFDidShowLimitHitForUnsortedArticlesPanel"
let WMFDidShowSyncDisabledPanel = "WMFDidShowSyncDisabledPanel"
let WMFDidShowSyncEnabledPanel = "WMFDidShowSyncEnabledPanel"
let WMFDidSplitExistingReadingLists = "WMFDidSplitExistingReadingLists"
let WMFDidShowTitleDescriptionEditingIntro = "WMFDidShowTitleDescriptionEditingIntro"

//Legacy Keys
let WMFOpenArticleTitleKey = "WMFOpenArticleTitleKey"
let WMFSearchLanguageKey = "WMFSearchLanguageKey"

@objc public enum WMFAppDefaultTabType: Int {
    case explore
    case settings
}

@objc public extension UserDefaults {
    @objc(WMFUserDefaultsKey) public class Key: NSObject {
        @objc static let defaultTabType = "WMFDefaultTabTypeKey"
    }

    @objc public static let wmf: UserDefaults = {
#if WMF_NO_APP_GROUP
        return UserDefaults.standard
#else
        guard let defaults = UserDefaults(suiteName: WMFApplicationGroupIdentifier) else {
            assertionFailure("Defaults not found!")
            return UserDefaults.standard
        }
        return defaults
#endif
    }()
    
    @objc public class func wmf_migrateToWMFGroupUserDefaultsIfNecessary() {
        let newDefaults = self.wmf
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
        }
    }

    @objc public func wmf_dateForKey(_ key: String) -> Date? {
        return self.object(forKey: key) as? Date
    }
    
    @objc public func wmf_appBecomeActiveDate() -> Date? {
        return self.wmf_dateForKey(WMFAppBecomeActiveDateKey)
    }
    
    @objc public func wmf_setAppBecomeActiveDate(_ date: Date?) {
        if let date = date {
            self.set(date, forKey: WMFAppBecomeActiveDateKey)
        }else{
            self.removeObject(forKey: WMFAppBecomeActiveDateKey)
        }
    }
    
    @objc public func wmf_appResignActiveDate() -> Date? {
        return self.wmf_dateForKey(WMFAppResignActiveDateKey)
    }
    
    @objc public func wmf_setAppResignActiveDate(_ date: Date?) {
        if let date = date {
            self.set(date, forKey: WMFAppResignActiveDateKey)
        }else{
            self.removeObject(forKey: WMFAppResignActiveDateKey)
        }
    }

    @objc public var wmf_lastAppVersion: String? {
        get {
            return string(forKey: "WMFLastAppVersion")
        }
        set {
            set(newValue, forKey: "WMFLastAppVersion")
        }
    }
    
    @objc public func wmf_setFeedRefreshDate(_ date: Date) {
        self.set(date, forKey: WMFFeedRefreshDateKey)
    }
    
    @objc public func wmf_feedRefreshDate() -> Date? {
        return self.wmf_dateForKey(WMFFeedRefreshDateKey)
    }
    
    @objc public func wmf_setLocationAuthorized(_ authorized: Bool) {
        self.set(authorized, forKey: WMFLocationAuthorizedKey)
    }
    
    @objc public var wmf_appTheme: Theme {
        return Theme.withName(string(forKey: WMFAppThemeName)) ?? Theme.standard
    }
    
    @objc public func wmf_setAppTheme(_ theme: Theme) {
        set(theme.name, forKey: WMFAppThemeName)
    }
    
    @objc public var wmf_isImageDimmingEnabled: Bool {
        get {
             return bool(forKey: WMFIsImageDimmingEnabled)
        }
        set {
            set(newValue, forKey: WMFIsImageDimmingEnabled)
        }
    }
    
    @objc public var wmf_isAutomaticTableOpeningEnabled: Bool {
        get {
            return bool(forKey: WMFIsAutomaticTableOpeningEnabled)
        }
        set {
            set(newValue, forKey: WMFIsAutomaticTableOpeningEnabled)
        }
    }
    
    @objc public var wmf_didShowThemeCardInFeed: Bool {
        get {
            return bool(forKey: WMFDidShowThemeCardInFeed)
        }
        set {
            set(newValue, forKey: WMFDidShowThemeCardInFeed)
        }
    }

    @objc public var wmf_didShowReadingListCardInFeed: Bool {
        get {
            return bool(forKey: WMFDidShowReadingListCardInFeed)
        }
        set {
            set(newValue, forKey: WMFDidShowReadingListCardInFeed)
        }
    }
    
    @objc public func wmf_locationAuthorized() -> Bool {
        return self.bool(forKey: WMFLocationAuthorizedKey)
    }
    
    
    @objc public func wmf_setPlacesHasAppeared(_ hasAppeared: Bool) {
        self.set(hasAppeared, forKey: WMFPlacesHasAppeared)
    }
    
    @objc public func wmf_placesHasAppeared() -> Bool {
        return self.bool(forKey: WMFPlacesHasAppeared)
    }
    
    @objc public func wmf_setPlacesDidPromptForLocationAuthorization(_ didPrompt: Bool) {
        self.set(didPrompt, forKey: WMFPlacesDidPromptForLocationAuthorization)
    }
    
    @objc public func wmf_placesDidPromptForLocationAuthorization() -> Bool {
        return self.bool(forKey: WMFPlacesDidPromptForLocationAuthorization)
    }
    
    @objc public func wmf_setExploreDidPromptForLocationAuthorization(_ didPrompt: Bool) {
        self.set(didPrompt, forKey: WMFExploreDidPromptForLocationAuthorization)
    }
    
    
    @objc public func wmf_exploreDidPromptForLocationAuthorization() -> Bool {
        return self.bool(forKey: WMFExploreDidPromptForLocationAuthorization)
    }
    
    
    @objc public func wmf_openArticleURL() -> URL? {
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
    
    @objc public func wmf_setOpenArticleURL(_ url: URL?) {
        guard let url = url else{
            self.removeObject(forKey: WMFOpenArticleURLKey)
            self.removeObject(forKey: WMFOpenArticleTitleKey)
            return
        }
        guard !url.wmf_isNonStandardURL else{
            return;
        }
        
        self.set(url, forKey: WMFOpenArticleURLKey)
    }

    @objc public func wmf_setShowSearchLanguageBar(_ enabled: Bool) {
        self.set(NSNumber(value: enabled as Bool), forKey: "ShowLanguageBar")
    }
    
    @objc public func wmf_showSearchLanguageBar() -> Bool {
        if let enabled = self.object(forKey: "ShowLanguageBar") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }

    @objc public var wmf_openAppOnSearchTab: Bool {
        get {
            return bool(forKey: "WMFOpenAppOnSearchTab")
        }
        set {
            set(newValue, forKey: "WMFOpenAppOnSearchTab")
        }
    }
    
    @objc public func wmf_currentSearchLanguageDomain() -> URL? {
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
    
    @objc public func wmf_setCurrentSearchLanguageDomain(_ url: URL?) {
        guard let url = url else{
            self.removeObject(forKey: WMFSearchURLKey)
            return
        }
        guard !url.wmf_isNonStandardURL else{
            return;
        }
        
        self.set(url, forKey: WMFSearchURLKey)
    }
    
    @objc public func wmf_setDidShowWIconPopover(_ shown: Bool) {
        self.set(NSNumber(value: shown as Bool), forKey: "ShowWIconPopover")
    }
    
    @objc public func wmf_didShowWIconPopover() -> Bool {
        if let enabled = self.object(forKey: "ShowWIconPopover") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }
    
    @objc public func wmf_setDidShowMoreLanguagesTooltip(_ shown: Bool) {
        self.set(NSNumber(value: shown as Bool), forKey: "ShowMoreLanguagesTooltip")
    }
    
    @objc public func wmf_didShowMoreLanguagesTooltip() -> Bool {
        if let enabled = self.object(forKey: "ShowMoreLanguagesTooltip") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }

    @objc public func wmf_setTableOfContentsIsVisibleInline(_ visibleInline: Bool) {
        self.set(NSNumber(value: visibleInline as Bool), forKey: "TableOfContentsIsVisibleInline")
    }
    
    @objc public func wmf_isTableOfContentsVisibleInline() -> Bool {
        if let enabled = self.object(forKey: "TableOfContentsIsVisibleInline") as? NSNumber {
            return enabled.boolValue
        }else{
            return true
        }
    }
    
    @objc public func wmf_setDidFinishLegacySavedArticleImageMigration(_ didFinish: Bool) {
        self.set(didFinish, forKey: "DidFinishLegacySavedArticleImageMigration2")
    }
    
    @objc public func wmf_didFinishLegacySavedArticleImageMigration() -> Bool {
        return self.bool(forKey: "DidFinishLegacySavedArticleImageMigration2")
    }
    
    @objc public func wmf_setDidMigrateHistoryList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateHistoryListKey)
    }
    
    @objc public func wmf_didMigrateHistoryList() -> Bool {
        return self.bool(forKey: WMFMigrateHistoryListKey)
    }

    @objc public func wmf_setDidMigrateSavedPageList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateSavedPageListKey)
    }
    
    @objc public func wmf_didMigrateSavedPageList() -> Bool {
        return self.bool(forKey: WMFMigrateSavedPageListKey)
    }

    @objc public func wmf_setDidMigrateBlackList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateBlackListKey)
    }
    
    @objc public func wmf_didMigrateBlackList() -> Bool {
        return self.bool(forKey: WMFMigrateBlackListKey)
    }
    
    @objc public func wmf_setDidMigrateToFixArticleCache(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateToFixArticleCacheKey)
    }
    
    @objc public func wmf_didMigrateToFixArticleCache() -> Bool {
        return self.bool(forKey: WMFMigrateToFixArticleCacheKey)
    }
    
    @objc public func wmf_setDidMigrateToSharedContainer(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateToSharedContainerKey)
    }
    
    @objc public func wmf_didMigrateToSharedContainer() -> Bool {
        return self.bool(forKey: WMFMigrateToSharedContainerKey)
    }

    @objc public func wmf_setDidMigrateToNewFeed(_ didMigrate: Bool) {
        self.set(didMigrate, forKey: WMFDidMigrateToCoreDataFeedKey)
    }
    
    @objc public func wmf_didMigrateToNewFeed() -> Bool {
        return self.bool(forKey: WMFDidMigrateToCoreDataFeedKey)
    }
    
    @objc public func wmf_mostRecentInTheNewsNotificationDate() -> Date? {
        return self.wmf_dateForKey(WMFMostRecentInTheNewsNotificationDateKey)
    }
    
    @objc public func wmf_setMostRecentInTheNewsNotificationDate(_ date: Date) {
        self.set(date, forKey: WMFMostRecentInTheNewsNotificationDateKey)
    }
    
    @objc public func wmf_inTheNewsMostRecentDateNotificationCount() -> Int {
        return self.integer(forKey: WMFInTheNewsMostRecentDateNotificationCountKey)
    }
    
    @objc public func wmf_setInTheNewsMostRecentDateNotificationCount(_ count: Int) {
        self.set(count, forKey: WMFInTheNewsMostRecentDateNotificationCountKey)
    }
    
    @objc public func wmf_inTheNewsNotificationsEnabled() -> Bool {
        return self.bool(forKey: WMFInTheNewsNotificationsEnabled)
    }
    
    @objc public func wmf_setInTheNewsNotificationsEnabled(_ enabled: Bool) {
        self.set(enabled, forKey: WMFInTheNewsNotificationsEnabled)
    }

    @objc public func wmf_setDidShowNewsNotificationCardInFeed(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowNewsNotificatonInFeedKey)
    }
    
    @objc public func wmf_didShowNewsNotificationCardInFeed() -> Bool {
        return self.bool(forKey: WMFDidShowNewsNotificatonInFeedKey)
    }

    @objc public func wmf_setDidShowEnableReadingListSyncPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowEnableReadingListSyncPanelKey)
    }
    
    @objc public func wmf_didShowEnableReadingListSyncPanel() -> Bool {
        return self.bool(forKey: WMFDidShowEnableReadingListSyncPanelKey)
    }
    
    @objc public func wmf_setDidShowLoginToSyncSavedArticlesToReadingListPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowLoginToSyncSavedArticlesToReadingListPanelKey)
    }
    
    @objc public func wmf_didShowLoginToSyncSavedArticlesToReadingListPanel() -> Bool {
        return self.bool(forKey: WMFDidShowLoginToSyncSavedArticlesToReadingListPanelKey)
    }
    
    @objc public func wmf_didShowLimitHitForUnsortedArticlesPanel() -> Bool {
        return self.bool(forKey: WMFDidShowLimitHitForUnsortedArticlesPanel)
    }
    
    @objc public func wmf_setDidShowLimitHitForUnsortedArticlesPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowLimitHitForUnsortedArticlesPanel)
    }
    
    @objc public func wmf_didShowSyncDisabledPanel() -> Bool {
        return self.bool(forKey: WMFDidShowSyncDisabledPanel)
    }
    
    @objc public func wmf_setDidShowSyncDisabledPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowSyncDisabledPanel)
    }
    
    @objc public func wmf_didShowSyncEnabledPanel() -> Bool {
        return self.bool(forKey: WMFDidShowSyncEnabledPanel)
    }
    
    @objc public func wmf_setDidShowSyncEnabledPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowSyncEnabledPanel)
    }
    
    @objc public func wmf_didSplitExistingReadingLists() -> Bool {
        return self.bool(forKey: WMFDidSplitExistingReadingLists)
    }
    
    @objc public func wmf_setDidSplitExistingReadingLists(_ didSplit: Bool) {
        self.set(didSplit, forKey: WMFDidSplitExistingReadingLists)
    }

    @objc public var defaultTabType: WMFAppDefaultTabType {
        get {
            guard let defaultTabType = WMFAppDefaultTabType(rawValue: integer(forKey: UserDefaults.Key.defaultTabType)) else {
                let explore = WMFAppDefaultTabType.explore
                set(explore.rawValue, forKey: UserDefaults.Key.defaultTabType)
                return explore
            }
            return defaultTabType
        }
        set {
            set(newValue.rawValue, forKey: UserDefaults.Key.defaultTabType)
            wmf_openAppOnSearchTab = newValue == .settings
        }
    }
    
    @objc public func wmf_didShowTitleDescriptionEditingIntro() -> Bool {
        return self.bool(forKey: WMFDidShowTitleDescriptionEditingIntro)
    }
    
    @objc public func wmf_setDidShowTitleDescriptionEditingIntro(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowTitleDescriptionEditingIntro)
    }
}
