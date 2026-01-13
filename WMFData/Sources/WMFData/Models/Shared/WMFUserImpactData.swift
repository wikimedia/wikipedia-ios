import Foundation

public struct WMFUserImpactData {
    
    public struct TopViewedArticle: Identifiable {
        public let id: String
        public let title: String
        let views: [Date: Int]
        public let viewsCount: Int
        
        public init(title: String, views: [Date : Int], viewsCount: Int) {
            self.id = title
            self.title = title
            self.views = views
            self.viewsCount = viewsCount
        }
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
