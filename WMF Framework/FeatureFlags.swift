import Foundation

public struct FeatureFlags {

    public static var needsNewTalkPage: Bool {
        return true
    }

    public static var watchlistEnabled: Bool {
        #if WMF_STAGING
        return true
        #else
        return false
        #endif
    }
    
    public static var applePayEnabled: Bool {
        #if WMF_STAGING
        return true
        #else
        return false
        #endif
    }
}
