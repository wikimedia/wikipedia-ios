import Foundation

@objc public class WKFeatureFlags: NSObject {

    public static var needsNewTalkPage: Bool {
        return true
    }

    public static var watchlistEnabled: Bool {
        return true
    }
    
    @objc public static var needsImageRecommendations: Bool {
        return true
    }
    
    public static var needsImageRecommendationsSuppressPosting: Bool {
        return false
    }

    // Bypasses card display conditional (50+ edits on primary app wiki, not blocked, wiki has recommendations)
    // This allows for easier design review on Experimental app
    @objc public static var forceImageRecommendationsExploreCard: Bool {
        return false
    }
}
