import Foundation

public struct WMFUserImpactData: Sendable {
    public init(totalPageviewsCount: Int? = nil, topViewedArticles: [WMFUserImpactData.TopViewedArticle], editCountByDay: [Date : Int], totalEditsCount: Int? = nil, receivedThanksCount: Int? = nil, longestEditingStreak: Int? = nil, lastEditTimestamp: Date? = nil, dailyTotalViews: [Date : Int]) {
        self.totalPageviewsCount = totalPageviewsCount
        self.topViewedArticles = topViewedArticles
        self.editCountByDay = editCountByDay
        self.totalEditsCount = totalEditsCount
        self.receivedThanksCount = receivedThanksCount
        self.longestEditingStreak = longestEditingStreak
        self.lastEditTimestamp = lastEditTimestamp
        self.dailyTotalViews = dailyTotalViews
    }
    
    
    public struct TopViewedArticle: Identifiable, Sendable {
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
