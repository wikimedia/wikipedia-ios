import Foundation

public final class WMFActivityTabDataController {
    public static let shared = WMFActivityTabDataController()
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    
    public init() {
        
    }
    
    public func getTimeReadPast7Days() async throws -> (Int, Int)? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfToday = calendar.startOfDay(for: now) as Date?,
              let startDate = calendar.date(byAdding: .day, value: -7, to: startOfToday),
              let endDate = calendar.date(byAdding: .day, value: 1, to: startOfToday)?.addingTimeInterval(-1) else { return (0, 0) }

        let dataController = try WMFPageViewsDataController()
        
        let minutesRead = try await dataController.fetchPageViewMinutes(startDate: startDate, endDate: endDate)

        // Turn total minutes into hours/minutes read
        let hours = minutesRead / 60
        let minutes = minutesRead % 60

        return (hours, minutes)
    }
    
    public func getArticlesRead() async throws -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: now) else { return 0 }
        
        let dataController = try WMFPageViewsDataController()
        let pageCounts = try await dataController.fetchPageViewCounts(startDate: startDate, endDate: now)
        
        let totalReads = pageCounts.reduce(0) { $0 + $1.count }
        
        return totalReads
    }
    
    public func getWeeklyReadsThisMonth() async throws -> [Int] {
        let calendar = Calendar.current
        let now = Date()
        
        let dataController = try WMFPageViewsDataController()
        var weeklyCounts: [Int] = []
        
        for week in 0..<4 {
            guard
                let endDate = calendar.date(byAdding: .day, value: -(7 * week), to: now),
                let startDate = calendar.date(byAdding: .day, value: -(7 * (week + 1)) + 1, to: now)
            else {
                continue
            }
            
            let pageCounts = try await dataController.fetchPageViewCounts(startDate: startDate, endDate: endDate)
            let count = pageCounts.reduce(0) { $0 + $1.count }
            
            weeklyCounts.append(count)
        }
        
        return Array(weeklyCounts.reversed())
    }


    @objc public func getActivityAssignment() -> Int {
        // TODO: More thoroughly assign experiment
        if shouldShowActivityTab { return 1 }
        return 0
    }

     public var shouldShowActivityTab: Bool {
         get {
             return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue)) ?? false
         } set {
             try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue, value: newValue)
         }
     }
    
    public var hasSeenActivityTab: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenActivityTab.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenActivityTab.rawValue, value: newValue)
        }
    }
    
    public func getMostRecentReadDateTime() async throws -> Date? {
        let dataController = try WMFPageViewsDataController()
        return try await dataController.fetchMostRecentTime()
    }
    
    public func getTopCategories() async throws -> [String]? {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return nil
        }

        let endDate = now

        let categories = try await fetchTopCategories(startDate: startOfMonth, endDate: endDate)

        let topThreeCategories = categories
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0.replacingOccurrences(of: "_", with: " ") }

        return Array(topThreeCategories)
    }
    
    public func fetchTopCategories(startDate: Date, endDate: Date) async throws -> [String] {
        let categoryCounts = try await WMFCategoriesDataController()
            .fetchCategoryCounts(startDate: startDate, endDate: endDate)

        return categoryCounts
            .sorted { $0.value > $1.value }
            .map { $0.key.categoryName }
    }
    
    public func fetchTimeline() async throws -> [Date: [TimelineItem]] {
        let dataController = try WMFPageViewsDataController()
        let pageRecords = try await dataController.fetchTimelinePages()
        guard !pageRecords.isEmpty else { return [:] }

        var dailyTimeline: [Date: [TimelineItem]] = [:]
        let calendar = Calendar.current

        for record in pageRecords {
            let page = record.page
            let timestamp = record.timestamp
            let dayBucket = calendar.startOfDay(for: timestamp)
            let articleURL = WMFProject(id: page.projectID)?.siteURL?.wmfURL(withTitle: page.title)

            let id = "\(page.projectID)-\(page.title)-\(Int(timestamp.timeIntervalSince1970))"

            let item = TimelineItem(
                id: id,
                date: timestamp,
                titleHtml: page.title,
                projectID: page.projectID,
                pageTitle: page.title,
                url: articleURL,
                description: nil,
                imageURLString: nil,
                snippet: nil,
                page: page
            )

            dailyTimeline[dayBucket, default: []].append(item)
        }

        for (key, items) in dailyTimeline {
            dailyTimeline[key] = items.sorted(by: { $0.date < $1.date })
        }

        return dailyTimeline
    }


    public func fetchSummary(for page: WMFPage) async throws -> WMFArticleSummary? {
        let articleSummaryController = WMFArticleSummaryDataController()
        guard let project = WMFProject(id: page.projectID) else { return nil }
        return try await articleSummaryController.fetchArticleSummary(project: project, title: page.title)
    }
}

public class SavedArticleModuleData: NSObject, Codable {
    public let savedArticlesCount: Int
    public let articleUrlStrings: [String]
    public let dateLastSaved: Date?

    public init(savedArticlesCount: Int, articleUrlStrings: [String], dateLastSaved: Date?) {
        self.savedArticlesCount = savedArticlesCount
        self.articleUrlStrings = articleUrlStrings
        self.dateLastSaved = dateLastSaved
    }
}

public protocol SavedArticleModuleDataDelegate: AnyObject {
    func getSavedArticleModuleData(from startDate: Date, to endDate: Date) async -> SavedArticleModuleData
}

public final class TimelineItem: Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let titleHtml: String
    public let projectID: String
    public let pageTitle: String
    public let url: URL?
    public var description: String?
    public var imageURLString: String?
    public var snippet: String?
    
    public let page: WMFPage

    public init(id: String,
                date: Date,
                titleHtml: String,
                projectID: String,
                pageTitle: String,
                url: URL?,
                description: String? = nil,
                imageURLString: String? = nil,
                snippet: String? = nil,
                page: WMFPage) {
        self.id = id
        self.date = date
        self.titleHtml = titleHtml
        self.projectID = projectID
        self.pageTitle = pageTitle
        self.url = url
        self.description = description
        self.imageURLString = imageURLString
        self.snippet = snippet
        self.page = page
    }

    public static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        lhs.id == rhs.id
    }
}
