import Foundation

public struct FeatureFlags {

    public static var needsNewTalkPage: Bool {
        return true
    }

    public static var watchlistEnabled: Bool {
        return true
    }
    
    public static var needsImageRecommendations: Bool {
        
    #if WMF_STAGING || WMF_EXPERIMENTAL
        return true
    #else
        return false
    #endif
    }
    
    // Bypasses card display conditional (50+ edits on primary app wiki, not blocked, wiki has recommendations)
    // This allows for easier design review on Experimental app
    public static var forceImageRecommendationsExploreCard: Bool {
        
    #if WMF_EXPERIMENTAL
        return true
    #else
        return false
    #endif
    }
}

@objc public class WMFFeatureFlags: NSObject {
    
    @objc public static var needsImageRecommendations: Bool {
        return FeatureFlags.needsImageRecommendations
    }
    
    @objc public static var forceImageRecommendationsExploreCard: Bool {
        return FeatureFlags.forceImageRecommendationsExploreCard
    }
}
