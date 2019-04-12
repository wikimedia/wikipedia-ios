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
let WMFDidShowFirstEditPublishedPanelKey = "WMFDidShowFirstEditPublishedPanelKey"
let WMFIsSyntaxHighlightingEnabled = "WMFIsSyntaxHighlightingEnabled"

//Legacy Keys
let WMFOpenArticleTitleKey = "WMFOpenArticleTitleKey"
let WMFSearchLanguageKey = "WMFSearchLanguageKey"

@objc public enum WMFAppDefaultTabType: Int {
    case explore
    case settings
}

@objc public extension UserDefaults {
    @objc(WMFUserDefaultsKey) class Key: NSObject {
        @objc static let defaultTabType = "WMFDefaultTabTypeKey"
        static let isUserUnawareOfLogout = "WMFIsUserUnawareOfLogout"
        static let didShowDescriptionPublishedPanel = "WMFDidShowDescriptionPublishedPanel"
        static let didShowEditingOnboarding = "WMFDidShowEditingOnboarding"
    }

    @objc static let wmf: UserDefaults = {
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
    
    @objc class func wmf_migrateToWMFGroupUserDefaultsIfNecessary() {
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

    @objc func wmf_dateForKey(_ key: String) -> Date? {
        return self.object(forKey: key) as? Date
    }
    
    @objc func wmf_appBecomeActiveDate() -> Date? {
        return self.wmf_dateForKey(WMFAppBecomeActiveDateKey)
    }
    
    @objc func wmf_setAppBecomeActiveDate(_ date: Date?) {
        if let date = date {
            self.set(date, forKey: WMFAppBecomeActiveDateKey)
        }else{
            self.removeObject(forKey: WMFAppBecomeActiveDateKey)
        }
    }
    
    @objc func wmf_appResignActiveDate() -> Date? {
        return self.wmf_dateForKey(WMFAppResignActiveDateKey)
    }
    
    @objc func wmf_setAppResignActiveDate(_ date: Date?) {
        if let date = date {
            self.set(date, forKey: WMFAppResignActiveDateKey)
        }else{
            self.removeObject(forKey: WMFAppResignActiveDateKey)
        }
    }

    @objc var wmf_lastAppVersion: String? {
        get {
            return string(forKey: "WMFLastAppVersion")
        }
        set {
            set(newValue, forKey: "WMFLastAppVersion")
        }
    }
    
    @objc func wmf_setFeedRefreshDate(_ date: Date) {
        self.set(date, forKey: WMFFeedRefreshDateKey)
    }
    
    @objc func wmf_feedRefreshDate() -> Date? {
        return self.wmf_dateForKey(WMFFeedRefreshDateKey)
    }
    
    @objc func wmf_setLocationAuthorized(_ authorized: Bool) {
        self.set(authorized, forKey: WMFLocationAuthorizedKey)
    }
    
    @objc var wmf_appTheme: Theme {
        return Theme.withName(string(forKey: WMFAppThemeName)) ?? Theme.standard
    }
    
    @objc func wmf_setAppTheme(_ theme: Theme) {
        set(theme.name, forKey: WMFAppThemeName)
    }
    
    @objc var wmf_isImageDimmingEnabled: Bool {
        get {
             return bool(forKey: WMFIsImageDimmingEnabled)
        }
        set {
            set(newValue, forKey: WMFIsImageDimmingEnabled)
        }
    }
    
    @objc var wmf_IsSyntaxHighlightingEnabled: Bool {
        get {
            if object(forKey: WMFIsSyntaxHighlightingEnabled) == nil {
                return true //default to highlighting enabled
            }
            
            return bool(forKey: WMFIsSyntaxHighlightingEnabled)
        }
        set {
            set(newValue, forKey: WMFIsSyntaxHighlightingEnabled)
        }
    }
    
    @objc var wmf_isAutomaticTableOpeningEnabled: Bool {
        get {
            return bool(forKey: WMFIsAutomaticTableOpeningEnabled)
        }
        set {
            set(newValue, forKey: WMFIsAutomaticTableOpeningEnabled)
        }
    }
    
    @objc var wmf_didShowThemeCardInFeed: Bool {
        get {
            return bool(forKey: WMFDidShowThemeCardInFeed)
        }
        set {
            set(newValue, forKey: WMFDidShowThemeCardInFeed)
        }
    }

    @objc var wmf_didShowReadingListCardInFeed: Bool {
        get {
            return bool(forKey: WMFDidShowReadingListCardInFeed)
        }
        set {
            set(newValue, forKey: WMFDidShowReadingListCardInFeed)
        }
    }
    
    @objc func wmf_locationAuthorized() -> Bool {
        return self.bool(forKey: WMFLocationAuthorizedKey)
    }
    
    
    @objc func wmf_setPlacesHasAppeared(_ hasAppeared: Bool) {
        self.set(hasAppeared, forKey: WMFPlacesHasAppeared)
    }
    
    @objc func wmf_placesHasAppeared() -> Bool {
        return self.bool(forKey: WMFPlacesHasAppeared)
    }
    
    @objc func wmf_setPlacesDidPromptForLocationAuthorization(_ didPrompt: Bool) {
        self.set(didPrompt, forKey: WMFPlacesDidPromptForLocationAuthorization)
    }
    
    @objc func wmf_placesDidPromptForLocationAuthorization() -> Bool {
        return self.bool(forKey: WMFPlacesDidPromptForLocationAuthorization)
    }
    
    @objc func wmf_setExploreDidPromptForLocationAuthorization(_ didPrompt: Bool) {
        self.set(didPrompt, forKey: WMFExploreDidPromptForLocationAuthorization)
    }
    
    
    @objc func wmf_exploreDidPromptForLocationAuthorization() -> Bool {
        return self.bool(forKey: WMFExploreDidPromptForLocationAuthorization)
    }
    
    
    @objc func wmf_openArticleURL() -> URL? {
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
    
    @objc func wmf_setOpenArticleURL(_ url: URL?) {
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

    @objc func wmf_setShowSearchLanguageBar(_ enabled: Bool) {
        self.set(NSNumber(value: enabled as Bool), forKey: "ShowLanguageBar")
    }
    
    @objc func wmf_showSearchLanguageBar() -> Bool {
        if let enabled = self.object(forKey: "ShowLanguageBar") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }

    @objc var wmf_openAppOnSearchTab: Bool {
        get {
            return bool(forKey: "WMFOpenAppOnSearchTab")
        }
        set {
            set(newValue, forKey: "WMFOpenAppOnSearchTab")
        }
    }
    
    @objc func wmf_currentSearchLanguageDomain() -> URL? {
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
    
    @objc func wmf_setCurrentSearchLanguageDomain(_ url: URL?) {
        guard let url = url else{
            self.removeObject(forKey: WMFSearchURLKey)
            return
        }
        guard !url.wmf_isNonStandardURL else{
            return;
        }
        
        self.set(url, forKey: WMFSearchURLKey)
    }
    
    @objc func wmf_setDidShowWIconPopover(_ shown: Bool) {
        self.set(NSNumber(value: shown as Bool), forKey: "ShowWIconPopover")
    }
    
    @objc func wmf_didShowWIconPopover() -> Bool {
        if let enabled = self.object(forKey: "ShowWIconPopover") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }
    
    @objc func wmf_setDidShowMoreLanguagesTooltip(_ shown: Bool) {
        self.set(NSNumber(value: shown as Bool), forKey: "ShowMoreLanguagesTooltip")
    }
    
    @objc func wmf_didShowMoreLanguagesTooltip() -> Bool {
        if let enabled = self.object(forKey: "ShowMoreLanguagesTooltip") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }

    @objc func wmf_setTableOfContentsIsVisibleInline(_ visibleInline: Bool) {
        self.set(NSNumber(value: visibleInline as Bool), forKey: "TableOfContentsIsVisibleInline")
    }
    
    @objc func wmf_isTableOfContentsVisibleInline() -> Bool {
        if let enabled = self.object(forKey: "TableOfContentsIsVisibleInline") as? NSNumber {
            return enabled.boolValue
        }else{
            return true
        }
    }
    
    @objc func wmf_setDidFinishLegacySavedArticleImageMigration(_ didFinish: Bool) {
        self.set(didFinish, forKey: "DidFinishLegacySavedArticleImageMigration2")
    }
    
    @objc func wmf_didFinishLegacySavedArticleImageMigration() -> Bool {
        return self.bool(forKey: "DidFinishLegacySavedArticleImageMigration2")
    }
    
    @objc func wmf_setDidMigrateHistoryList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateHistoryListKey)
    }
    
    @objc func wmf_didMigrateHistoryList() -> Bool {
        return self.bool(forKey: WMFMigrateHistoryListKey)
    }

    @objc func wmf_setDidMigrateSavedPageList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateSavedPageListKey)
    }
    
    @objc func wmf_didMigrateSavedPageList() -> Bool {
        return self.bool(forKey: WMFMigrateSavedPageListKey)
    }

    @objc func wmf_setDidMigrateBlackList(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateBlackListKey)
    }
    
    @objc func wmf_didMigrateBlackList() -> Bool {
        return self.bool(forKey: WMFMigrateBlackListKey)
    }
    
    @objc func wmf_setDidMigrateToFixArticleCache(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateToFixArticleCacheKey)
    }
    
    @objc func wmf_didMigrateToFixArticleCache() -> Bool {
        return self.bool(forKey: WMFMigrateToFixArticleCacheKey)
    }
    
    @objc func wmf_setDidMigrateToSharedContainer(_ didFinish: Bool) {
        self.set(didFinish, forKey: WMFMigrateToSharedContainerKey)
    }
    
    @objc func wmf_didMigrateToSharedContainer() -> Bool {
        return self.bool(forKey: WMFMigrateToSharedContainerKey)
    }

    @objc func wmf_setDidMigrateToNewFeed(_ didMigrate: Bool) {
        self.set(didMigrate, forKey: WMFDidMigrateToCoreDataFeedKey)
    }
    
    @objc func wmf_didMigrateToNewFeed() -> Bool {
        return self.bool(forKey: WMFDidMigrateToCoreDataFeedKey)
    }
    
    @objc func wmf_mostRecentInTheNewsNotificationDate() -> Date? {
        return self.wmf_dateForKey(WMFMostRecentInTheNewsNotificationDateKey)
    }
    
    @objc func wmf_setMostRecentInTheNewsNotificationDate(_ date: Date) {
        self.set(date, forKey: WMFMostRecentInTheNewsNotificationDateKey)
    }
    
    @objc func wmf_inTheNewsMostRecentDateNotificationCount() -> Int {
        return self.integer(forKey: WMFInTheNewsMostRecentDateNotificationCountKey)
    }
    
    @objc func wmf_setInTheNewsMostRecentDateNotificationCount(_ count: Int) {
        self.set(count, forKey: WMFInTheNewsMostRecentDateNotificationCountKey)
    }
    
    @objc func wmf_inTheNewsNotificationsEnabled() -> Bool {
        return self.bool(forKey: WMFInTheNewsNotificationsEnabled)
    }
    
    @objc func wmf_setInTheNewsNotificationsEnabled(_ enabled: Bool) {
        self.set(enabled, forKey: WMFInTheNewsNotificationsEnabled)
    }

    @objc func wmf_setDidShowNewsNotificationCardInFeed(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowNewsNotificatonInFeedKey)
    }
    
    @objc func wmf_didShowNewsNotificationCardInFeed() -> Bool {
        return self.bool(forKey: WMFDidShowNewsNotificatonInFeedKey)
    }

    @objc func wmf_setDidShowEnableReadingListSyncPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowEnableReadingListSyncPanelKey)
    }
    
    @objc func wmf_didShowEnableReadingListSyncPanel() -> Bool {
        return self.bool(forKey: WMFDidShowEnableReadingListSyncPanelKey)
    }
    
    @objc func wmf_setDidShowLoginToSyncSavedArticlesToReadingListPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowLoginToSyncSavedArticlesToReadingListPanelKey)
    }
    
    @objc func wmf_didShowLoginToSyncSavedArticlesToReadingListPanel() -> Bool {
        return self.bool(forKey: WMFDidShowLoginToSyncSavedArticlesToReadingListPanelKey)
    }

    @objc func wmf_setDidShowFirstEditPublishedPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowFirstEditPublishedPanelKey)
    }
    
    @objc func wmf_didShowFirstEditPublishedPanel() -> Bool {
        return self.bool(forKey: WMFDidShowFirstEditPublishedPanelKey)
    }
    
    @objc func wmf_didShowLimitHitForUnsortedArticlesPanel() -> Bool {
        return self.bool(forKey: WMFDidShowLimitHitForUnsortedArticlesPanel)
    }
    
    @objc func wmf_setDidShowLimitHitForUnsortedArticlesPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowLimitHitForUnsortedArticlesPanel)
    }
    
    @objc func wmf_didShowSyncDisabledPanel() -> Bool {
        return self.bool(forKey: WMFDidShowSyncDisabledPanel)
    }
    
    @objc func wmf_setDidShowSyncDisabledPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowSyncDisabledPanel)
    }
    
    @objc func wmf_didShowSyncEnabledPanel() -> Bool {
        return self.bool(forKey: WMFDidShowSyncEnabledPanel)
    }
    
    @objc func wmf_setDidShowSyncEnabledPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowSyncEnabledPanel)
    }
    
    @objc func wmf_didSplitExistingReadingLists() -> Bool {
        return self.bool(forKey: WMFDidSplitExistingReadingLists)
    }
    
    @objc func wmf_setDidSplitExistingReadingLists(_ didSplit: Bool) {
        self.set(didSplit, forKey: WMFDidSplitExistingReadingLists)
    }

    @objc var defaultTabType: WMFAppDefaultTabType {
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
    
    @objc func wmf_didShowTitleDescriptionEditingIntro() -> Bool {
        return self.bool(forKey: WMFDidShowTitleDescriptionEditingIntro)
    }
    
    @objc func wmf_setDidShowTitleDescriptionEditingIntro(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowTitleDescriptionEditingIntro)
    }

    var isUserUnawareOfLogout: Bool {
        get {
            return bool(forKey: UserDefaults.Key.isUserUnawareOfLogout)
        }
        set {
            set(newValue, forKey: UserDefaults.Key.isUserUnawareOfLogout)
        }
    }

    var didShowDescriptionPublishedPanel: Bool {
        get {
            return bool(forKey: UserDefaults.Key.didShowDescriptionPublishedPanel)
        }
        set {
            set(newValue, forKey: UserDefaults.Key.didShowDescriptionPublishedPanel)
        }
    }

    @objc var didShowEditingOnboarding: Bool {
        get {
            return bool(forKey: UserDefaults.Key.didShowEditingOnboarding)
        }
        set {
            set(newValue, forKey: UserDefaults.Key.didShowEditingOnboarding)
        }
    }
#if UI_TEST
    @objc func wmf_isFastlaneSnapshotInProgress() -> Bool {
        return bool(forKey: "FASTLANE_SNAPSHOT")
    }
#endif
}
