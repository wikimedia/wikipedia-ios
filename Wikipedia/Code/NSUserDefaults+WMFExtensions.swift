
import Foundation

let WMFAppLaunchDateKey = "WMFAppLaunchDateKey"
let WMFAppBecomeActiveDateKey = "WMFAppBecomeActiveDateKey"
let WMFAppResignActiveDateKey = "WMFAppResignActiveDateKey"
let WMFOpenArticleTitleKey = "WMFOpenArticleTitleKey"
let WMFAppSiteKey = "Domain"
let WMFSearchLanguageKey = "WMFSearchLanguageKey"


extension NSUserDefaults {

    @objc public class func WMFSearchLanguageDidChangeNotification() -> String {
        return "WMFSearchLanguageDidChangeNotification"
    }

    public func wmf_dateForKey(key: String) -> NSDate? {
        return self.objectForKey(key) as? NSDate
    }

    public func wmf_appLaunchDate() -> NSDate? {
        return self.wmf_dateForKey(WMFAppLaunchDateKey)
    }
    
    public func wmf_setAppLaunchDate(date: NSDate) {
        self.setObject(date, forKey: WMFAppLaunchDateKey)
        self.synchronize()
    }
    
    public func wmf_appBecomeActiveDate() -> NSDate? {
        return self.wmf_dateForKey(WMFAppBecomeActiveDateKey)
    }
    
    public func wmf_setAppBecomeActiveDate(date: NSDate?) {
        if let date = date {
            self.setObject(date, forKey: WMFAppBecomeActiveDateKey)
        }else{
            self.removeObjectForKey(WMFAppBecomeActiveDateKey)
        }
        self.synchronize()
    }
    
    public func wmf_appResignActiveDate() -> NSDate? {
        return self.wmf_dateForKey(WMFAppResignActiveDateKey)
    }
    
    public func wmf_setAppResignActiveDate(date: NSDate?) {
        if let date = date {
            self.setObject(date, forKey: WMFAppResignActiveDateKey)
        }else{
            self.removeObjectForKey(WMFAppResignActiveDateKey)
        }
        self.synchronize()
    }
    
    public func wmf_openArticleTitle() -> MWKTitle? {
        if let data = self.dataForKey(WMFOpenArticleTitleKey){
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MWKTitle
        }else{
            return nil
        }
    }
    
    public func wmf_setOpenArticleTitle(title: MWKTitle?) {
        if let title = title {
            let data = NSKeyedArchiver.archivedDataWithRootObject(title)
            self.setObject(data, forKey: WMFOpenArticleTitleKey)
        }else{
            self.removeObjectForKey(WMFOpenArticleTitleKey)
        }
        self.synchronize()
    }

    public func wmf_setSendUsageReports(enabled: Bool) {
        self.setObject(NSNumber(bool: enabled), forKey: "SendUsageReports")
        self.synchronize()

    }

    public func wmf_sendUsageReports() -> Bool {
        if let enabled = self.objectForKey("SendUsageReports") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }
    
    public func wmf_setAppInstallDateIfNil(date: NSDate) {
        let previous = self.wmf_appInstallDate()
        
        if previous == nil {
            self.setObject(date, forKey: "AppInstallDate")
            self.synchronize()
        }
    }
    
    public func wmf_appInstallDate() -> NSDate? {
        if let date = self.objectForKey("AppInstallDate") as? NSDate {
            return date
        }else{
            return nil
        }
    }
    
    public func wmf_appSite() -> MWKSite? {
        guard let data = self.objectForKey(WMFAppSiteKey) as? String else {
            DDLogError("Site preference was empty! Falling back to device language")
            let fallbackSite = MWKSite.siteWithCurrentLocale()
            // NOTE: need to set defaults directly, otherwise we'd get into inf. loop
            self.setObject(fallbackSite.language, forKey: WMFAppSiteKey)
            self.synchronize()
            return fallbackSite
        }
        return MWKSite.init(domain: WMFDefaultSiteDomain, language: data)
    }
    
    public func wmf_setAppSite(site: MWKSite) {
        guard !site.isEqualToSite(self.wmf_appSite()) else{
            return
        }
        self.setObject(site.language, forKey: WMFAppSiteKey)
        self.synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(NSUserDefaults.WMFSearchLanguageDidChangeNotification(), object: nil)
    }

    public func wmf_setDateLastDailyLoggingStatsSent(date: NSDate) {
        self.setObject(date, forKey: "DailyLoggingStatsDate")
        self.synchronize()
    }

    public func wmf_dateLastDailyLoggingStatsSent() -> NSDate? {
        if let date = self.objectForKey("DailyLoggingStatsDate") as? NSDate {
            return date
        }else{
            return nil
        }
    }

    public func wmf_setShowSearchLanguageBar(enabled: Bool) {
        self.setObject(NSNumber(bool: enabled), forKey: "ShowLanguageBar")
        self.synchronize()
        
    }
    
    public func wmf_showSearchLanguageBar() -> Bool {
        if let enabled = self.objectForKey("ShowLanguageBar") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }
    
    public func wmf_currentSearchLanguageSite() -> MWKSite? {
        if let data = self.objectForKey(WMFSearchLanguageKey) as? String{
            return MWKSite.init(domain: WMFDefaultSiteDomain, language: data)
        }else{
            return nil
        }
    }
    
    public func wmf_setCurrentSearchLanguageSite(site: MWKSite) {
        if let searchLanguage = self.wmf_currentSearchLanguageSite() {
            if searchLanguage.isEqualToSite(site){
                return;
            }
        }
        self.setObject(site.language, forKey: WMFSearchLanguageKey)
        self.synchronize()
    }

    
    
    public func wmf_setReadingFontSize(fontSize: NSNumber) {
        self.setObject(fontSize, forKey: "ReadingFontSize")
        self.synchronize()
        
    }
    
    public func wmf_readingFontSize() -> NSNumber {
        if let fontSize = self.objectForKey("ReadingFontSize") as? NSNumber {
            return fontSize
        }else{
            return NSNumber(integer:100) //default is 100%
        }
    }

}