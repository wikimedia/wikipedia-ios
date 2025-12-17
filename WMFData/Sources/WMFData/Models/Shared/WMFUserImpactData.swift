import Foundation

public struct WMFUserImpactData {
    
    public struct TopViewedArticle {
        public let title: String
        let views: [Date: Int]
        public let viewsCount: Int
    }
    
    let totalPageviewsCount: Int?
    public let topViewedArticles: [TopViewedArticle]
    public let editCountByDay: [Date: Int]
    public let totalEditsCount: Int?
    public let receivedThanksCount: Int?
    public let longestEditingStreak: Int?
    public let lastEditTimestamp: Date?
    public let dailyTotalViews: [Date: Int]
}
