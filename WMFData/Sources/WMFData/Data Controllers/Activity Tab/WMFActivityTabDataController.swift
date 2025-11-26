import Foundation

public actor WMFActivityTabDataController {
    public static let shared = WMFActivityTabDataController()
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    public init() {}

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

    public func getActivityAssignment() -> Int {
        shouldShowActivityTab ? 1 : 0
    }

    public var shouldShowActivityTab: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue, value: newValue)
        }
    }
    
    public func shouldShowLoginPrompt(for state: LoginState) -> Bool {
        switch state {
        case .loggedIn:
            return false
        case .temp:
            return !dismissLoginTempUser
        case .loggedOut:
            return !dismissLoginIPUser
        }
    }
    
    public func recordDismissLoginprompt(for state: LoginState) {
        switch state {
        case .loggedOut:
            dismissLoginIPUser = true
        case .temp:
            dismissLoginTempUser = true
        case .loggedIn:
            break
        }
    }

    public var dismissLoginIPUser: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.activityTabIPUserDismissLogin.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.activityTabIPUserDismissLogin.rawValue, value: newValue)
        }
    }
    
    public var dismissLoginTempUser: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.activityTabTempAccountUserDismissLogin.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.activityTabTempAccountUserDismissLogin.rawValue, value: newValue)
        }
    }
    
    public var hasSeenActivityTab: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenActivityTab.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenActivityTab.rawValue, value: newValue)
        }
    }

    public func setHasSeenActivityTab(_ value: Bool) {
        self.hasSeenActivityTab = value
    }

    public func getHasSeenActivityTab() -> Bool {
        return hasSeenActivityTab
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

            var todaysPages = Set<String>()
            if let existingItems = dailyTimeline[dayBucket] {
                todaysPages = Set(existingItems.map { $0.pageTitle })
            }

            guard !todaysPages.contains(page.title) else { continue }

            let item = TimelineItem(
                id: UUID().uuidString,
                date: timestamp,
                titleHtml: page.title,
                projectID: page.projectID,
                pageTitle: page.title,
                url: articleURL,
                description: nil,
                imageURLString: nil,
                snippet: nil,
                page: page,
                itemType: .read
            )

            dailyTimeline[dayBucket, default: []].append(item)
        }

        let sortedTimeline = dailyTimeline.mapValues { items in
            items.sorted { $0.date < $1.date }
        }

        return sortedTimeline

    }
    
    public func deletePageView(title: String, namespaceID: Int16, project: WMFProject) async throws {
        let dataController = try WMFPageViewsDataController()
        try? await dataController.deletePageView(title: title, namespaceID: namespaceID, project: project)
    }
    
    public func deletePageView(for item: TimelineItem) async throws {
        guard let project = WMFProject(id: item.page.projectID) else { return }
        try await deletePageView(
            title: item.page.title,
            namespaceID: Int16(item.page.namespaceID),
            project: project
        )
    }
    
    public func fetchSummary(for page: WMFPage) async throws -> WMFArticleSummary? {
        let articleSummaryController = WMFArticleSummaryDataController()
        guard let project = WMFProject(id: page.projectID) else { return nil }
        return try await articleSummaryController.fetchArticleSummary(project: project, title: page.title)
    }

}

extension WMFActivityTabDataController {
    @objc public nonisolated static func activityAssignmentForObjC() -> Int {
        let key = WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue
        let value = (try? WMFDataEnvironment.current.userDefaultsStore?.load(key: key)) ?? false
        return value ? 1 : 0
    }
}


public protocol SavedArticleModuleDataDelegate: AnyObject {
    func getSavedArticleModuleData(from startDate: Date, to endDate: Date) async -> SavedArticleModuleData
}

public struct TimelineItem: Identifiable, Equatable {
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
    
    public let itemType: TimelineItemType

    public init(id: String,
                date: Date,
                titleHtml: String,
                projectID: String,
                pageTitle: String,
                url: URL?,
                description: String? = nil,
                imageURLString: String? = nil,
                snippet: String? = nil,
                page: WMFPage,
                itemType: TimelineItemType = .standard) {
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
        self.itemType = itemType
    }

    public static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        lhs.id == rhs.id
    }
}

public enum TimelineItemType {
    case standard // no icon, logged out users, etc.
    case edit
    case read
    case save
}

public enum LoginState: Int {
    case loggedOut = 0
    case temp = 1
    case loggedIn = 2
}
