import Foundation

struct FeatureFlags {
    
    static var needsNewTalkPage: Bool {
        #if WMF_STAGING
            return true
        #else
            return false
        #endif
    }
    
}
