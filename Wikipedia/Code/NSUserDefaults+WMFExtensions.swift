
import Foundation

let WMFAppLaunchDateKey = "WMFAppLaunchDateKey"
let WMFAppBecomeActiveDateKey = "WMFAppBecomeActiveDateKey"
let WMFAppResignActiveDateKey = "WMFAppResignActiveDateKey"
let WMFOpenArticleURLKey = "WMFOpenArticleURLKey"
let WMFAppSiteKey = "Domain"
let WMFSearchURLKey = "WMFSearchURLKey"
let WMFMigrateHistoryListKey = "WMFMigrateHistoryListKey"
let WMFMigrateSavedPageListKey = "WMFMigrateSavedPageListKey"
let WMFMigrateBlackListKey = "WMFMigrateBlackListKey"

//Legacy Keys
let WMFOpenArticleTitleKey = "WMFOpenArticleTitleKey"
let WMFSearchLanguageKey = "WMFSearchLanguageKey"


extension UserDefaults {

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
    
    public func wmf_openArticleURL() -> URL? {
        if let url = self.url(forKey: WMFOpenArticleURLKey) {
            return url
        }else if let data = self.data(forKey: WMFOpenArticleTitleKey){
            if let title = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MWKTitle {
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
            self.removeObject(forKey: WMFOpenArticleTitleKey)
            self.synchronize()
            return
        }
        guard !(url as NSURL).wmf_isNonStandardURL else{
            return;
        }
        
        self.set(url, forKey: WMFOpenArticleTitleKey)
        self.synchronize()
    }

    public func wmf_setSendUsageReports(_ enabled: Bool) {
        self.set(NSNumber(value: enabled), forKey: "SendUsageReports")
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
    
    public func wmf_setDateLastDailyLoggingStatsSent(_ date: Date) {
        self.set(date, forKey: "DailyLoggingStatsDate")
        self.synchronize()
    }

    public func wmf_dateLastDailyLoggingStatsSent() -> Date? {
        if let date = self.object(forKey: "DailyLoggingStatsDate") as? Date {
            return date
        }else{
            return nil
        }
    }

    public func wmf_setShowSearchLanguageBar(_ enabled: Bool) {
        self.set(NSNumber(value: enabled), forKey: "ShowLanguageBar")
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
            let url = URL.wmf_URL(withDefaultSiteAndlanguage: language)
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

    public func wmf_setReadingFontSize(_ fontSize: NSNumber) {
        self.set(fontSize, forKey: "ReadingFontSize")
        self.synchronize()
        
    }
    
    public func wmf_readingFontSize() -> NSNumber {
        if let fontSize = self.object(forKey: "ReadingFontSize") as? NSNumber {
            return fontSize
        }else{
            return NSNumber(value:100) //default is 100%
        }
    }
    
    public func wmf_setDidPeekTableOfContents(_ peeked: Bool) {
        self.set(NSNumber(value: peeked), forKey: "PeekTableOfContents")
        self.synchronize()
        
    }
    
    public func wmf_didPeekTableOfContents() -> Bool {
        if let enabled = self.object(forKey: "PeekTableOfContents") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }

    public func wmf_setDidFinishLegacySavedArticleImageMigration(_ didFinish: Bool) {
        self.set(didFinish, forKey: "DidFinishLegacySavedArticleImageMigration")
        self.synchronize()
    }
    
    public func wmf_didFinishLegacySavedArticleImageMigration() -> Bool {
        return self.bool(forKey: "DidFinishLegacySavedArticleImageMigration")
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

}
