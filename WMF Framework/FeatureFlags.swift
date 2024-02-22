import Foundation

public struct FeatureFlags {

    public static var needsNewTalkPage: Bool {
        return true
    }

    public static var watchlistEnabled: Bool {
        return true
    }
    
    public static var needsNativeSourceEditor: Bool {
        return true
    }
    
    public static var needsImageRecommendations: Bool {
        
    #if WMF_STAGING || WMF_EXPERIMENTAL
        return true
    #else
        return false
    #endif
    }
}
