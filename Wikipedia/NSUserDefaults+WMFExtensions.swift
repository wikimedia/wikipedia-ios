
import Foundation

let WMFAppLaunchDateKey = "WMFAppLaunchDateKey"
let WMFAppBecomeActiveDateKey = "WMFAppBecomeActiveDateKey"
let WMFAppResignActiveDateKey = "WMFAppResignActiveDateKey"


extension NSUserDefaults {
    
    public func wmf_dateForKey(key: String) -> NSDate? {
        if let date = self.objectForKey(key) as? NSDate {
            return date
        }else{
            return nil
        }
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
    
    public func wmf_setAppBecomeActiveDate(date: NSDate) {
        self.setObject(date, forKey: WMFAppBecomeActiveDateKey)
        self.synchronize()
    }
    
    public func wmf_appResignActiveDate() -> NSDate? {
        return self.wmf_dateForKey(WMFAppResignActiveDateKey)
    }
    
    public func wmf_setAppResignActiveDate(date: NSDate) {
        self.setObject(date, forKey: WMFAppResignActiveDateKey)
        self.synchronize()
    }
}