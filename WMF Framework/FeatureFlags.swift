import Foundation

@objc(WMFFeatureFlags)
public class FeatureFlags: NSObject {
    
    public static var needsNewTalkPage: Bool {
        #if WMF_STAGING
            return true
        #else
            return false
        #endif
    }
    
    @objc public static var needsApplePay: Bool {
        // TODO: Apple Pay logging
        // TODO: Apple Pay icon name
        // TODO: Fix keyboard hiding textfield on iOS13
        #if WMF_STAGING
            return true
        #else
            return false
        #endif
    }
    
}
