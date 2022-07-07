import Foundation

public struct FeatureFlags {
    
    public static var needsNewTalkPage: Bool {
        #if WMF_STAGING
            return true
        #else
            return false
        #endif
    }
    
    public static var needsApplePay: Bool {
        // TODO: Apple Pay logging
        // TODO: Apple Pay icon name
        #if WMF_STAGING
            return true
        #else
            return false
        #endif
    }
    
}


/// Bridging class only for Objective-C access. Put all logic in FeatureFlags
@objc public class WMFFeatureFlags: NSObject {
    
    @objc public class var needsApplePay: Bool {
        return FeatureFlags.needsApplePay
    }
}
