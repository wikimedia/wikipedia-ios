import Foundation

public struct FeatureFlags {

    public static var needsNewTalkPage: Bool {
        return true
    }

    public static var watchlistEnabled: Bool {
#if WMF_STAGING || WMF_EXPERIMENTAL
        return true
        #else
        return false
        #endif
    }
    
}
