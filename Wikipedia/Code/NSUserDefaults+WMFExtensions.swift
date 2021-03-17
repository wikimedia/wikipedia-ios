let WMFAppResignActiveDateKey = "WMFAppResignActiveDateKey"
let WMFShouldRestoreNavigationStackOnResume = "WMFShouldRestoreNavigationStackOnResume"
let WMFAppSiteKey = "Domain"
let WMFSearchURLKey = "WMFSearchURLKey"
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
let WMFDidShowThankRevisionAuthorEducationPanelKey = "WMFDidShowThankRevisionAuthorEducationPanelKey"
let WMFDidShowLimitHitForUnsortedArticlesPanel = "WMFDidShowLimitHitForUnsortedArticlesPanel"
let WMFDidShowSyncDisabledPanel = "WMFDidShowSyncDisabledPanel"
let WMFDidShowSyncEnabledPanel = "WMFDidShowSyncEnabledPanel"
let WMFDidSplitExistingReadingLists = "WMFDidSplitExistingReadingLists"
let WMFDidShowTitleDescriptionEditingIntro = "WMFDidShowTitleDescriptionEditingIntro"
let WMFDidShowFirstEditPublishedPanelKey = "WMFDidShowFirstEditPublishedPanelKey"
let WMFIsSyntaxHighlightingEnabled = "WMFIsSyntaxHighlightingEnabled"
let WMFSearchLanguageKey = "WMFSearchLanguageKey"
let WMFAppInstallId = "WMFAppInstallId"
let WMFSendUsageReports = "WMFSendUsageReports"

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
        static let autoSignTalkPageDiscussions = "WMFAutoSignTalkPageDiscussions"
    }

    @objc func wmf_dateForKey(_ key: String) -> Date? {
        return self.object(forKey: key) as? Date
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

    @objc var shouldRestoreNavigationStackOnResume: Bool {
        get {
            return bool(forKey: WMFShouldRestoreNavigationStackOnResume)
        }
        set {
            set(newValue, forKey: WMFShouldRestoreNavigationStackOnResume)
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
    
    @objc var wmf_appInstallId: String? {
        get {
            var appInstallId = string(forKey: WMFAppInstallId)
            if appInstallId == nil {
                appInstallId = UUID().uuidString
                set(appInstallId, forKey: WMFAppInstallId)
            }
            return appInstallId
        }
        set {
            set(newValue, forKey: WMFAppInstallId)
        }
    }

    @objc var wmf_sendUsageReports: Bool {
        get {
            return bool(forKey: WMFSendUsageReports)
        }
        set {
            set(newValue, forKey: WMFSendUsageReports)
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
    
    @objc var themeAnalyticsName: String {
        let name = string(forKey: WMFAppThemeName)
        guard name != nil, name != Theme.defaultThemeName else {
            return Theme.defaultAnalyticsThemeName
        }
        return Theme.withName(name)?.name ?? Theme.light.name
    }
    
    @objc var themeDisplayName: String {
        let name = string(forKey: WMFAppThemeName)
        guard name != nil, name != Theme.defaultThemeName else {
            return CommonStrings.defaultThemeDisplayName
        }
        return Theme.withName(name)?.displayName ?? Theme.light.displayName
    }
    
    @objc(themeCompatibleWith:)
    func theme(compatibleWith traitCollection: UITraitCollection) -> Theme {
        let name = string(forKey: WMFAppThemeName)
        guard name != nil, name != Theme.defaultThemeName else {
            if #available(iOSApplicationExtension 13.0, *) {
                return traitCollection.userInterfaceStyle == .dark ? Theme.black.withDimmingEnabled(wmf_isImageDimmingEnabled) : .light
            } else {
                return .light
            }
        }
        let theme = Theme.withName(name) ?? Theme.light
        return theme.isDark ? theme.withDimmingEnabled(wmf_isImageDimmingEnabled) : theme
    }
    
    @objc var themeName: String {
        get {
            string(forKey: WMFAppThemeName) ?? Theme.defaultThemeName
        }
        set {
            set(newValue, forKey: WMFAppThemeName)
        }
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
    
    @objc func wmf_currentSearchContentLanguageCode() -> String? {
        self.string(forKey: WMFSearchLanguageKey)
    }
    
    @objc func wmf_setCurrentSearchContentLanguageCode(_ code: String?) {
        if let code = code { set(code, forKey: WMFSearchLanguageKey) }
        else { removeObject(forKey: WMFSearchLanguageKey) }
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

    @objc func wmf_setDidShowThankRevisionAuthorEducationPanel(_ didShow: Bool) {
        self.set(didShow, forKey: WMFDidShowThankRevisionAuthorEducationPanelKey)
    }
    
    @objc func wmf_didShowThankRevisionAuthorEducationPanel() -> Bool {
        return self.bool(forKey: WMFDidShowThankRevisionAuthorEducationPanelKey)
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

    var autoSignTalkPageDiscussions: Bool {
        get {
            return bool(forKey: UserDefaults.Key.autoSignTalkPageDiscussions)
        }
        set {
            set(newValue, forKey: UserDefaults.Key.autoSignTalkPageDiscussions)
        }
    }
#if UI_TEST
    @objc func wmf_isFastlaneSnapshotInProgress() -> Bool {
        return bool(forKey: "FASTLANE_SNAPSHOT")
    }
#endif
}
