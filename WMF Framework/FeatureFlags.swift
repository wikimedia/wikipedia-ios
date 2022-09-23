import Foundation

public struct FeatureFlags {
    
    public static var needsNewTalkPage: Bool {
        return true
        
        #if WMF_STAGING
            return true
        #else
            return false
        #endif
    }
    
}
