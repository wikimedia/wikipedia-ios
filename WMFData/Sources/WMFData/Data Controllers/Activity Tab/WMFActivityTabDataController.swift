import Foundation

public actor WMFActivityTabDataController {
    public static let shared = WMFActivityTabDataController()
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    public var historyDataController: WMFHistoryDataController? = nil

    public init() {}
    
    // MARK: - Activity Tab Customization Toggles

    public var isTimeSpentReadingOn: Bool {
        get {
            return (try? userDefaultsStore?.load(
                key: WMFUserDefaultsKey.activityTabIsTimeSpentReadingOn.rawValue
            )) ?? true
        }
        set {
            try? userDefaultsStore?.save(
                key: WMFUserDefaultsKey.activityTabIsTimeSpentReadingOn.rawValue,
                value: newValue
            )
        }
    }

    public var isReadingInsightsOn: Bool {
        get {
            return (try? userDefaultsStore?.load(
                key: WMFUserDefaultsKey.activityTabIsReadingInsightsOn.rawValue
            )) ?? true
        }
        set {
            try? userDefaultsStore?.save(
                key: WMFUserDefaultsKey.activityTabIsReadingInsightsOn.rawValue,
                value: newValue
            )
        }
    }

    public var isEditingInsightsOn: Bool {
        get {
            return (try? userDefaultsStore?.load(
                key: WMFUserDefaultsKey.activityTabIsEditingInsightsOn.rawValue
            )) ?? true
        }
        set {
            try? userDefaultsStore?.save(
                key: WMFUserDefaultsKey.activityTabIsEditingInsightsOn.rawValue,
                value: newValue
            )
        }
    }

    public var isTimelineOfBehaviorOn: Bool {
        get {
            return (try? userDefaultsStore?.load(
                key: WMFUserDefaultsKey.activityTabIsTimelineOfBehaviorOn.rawValue
            )) ?? true
        }
        set {
            try? userDefaultsStore?.save(
                key: WMFUserDefaultsKey.activityTabIsTimelineOfBehaviorOn.rawValue,
                value: newValue
            )
        }
    }
    
    public func updateIsTimeSpentReadingOn(_ value: Bool) {
        isTimeSpentReadingOn = value
    }
    
    public func updateIsReadingInsightsOn(_ value: Bool) {
        isReadingInsightsOn = value
    }
    
    public func updateIsEditingInsightsOn(_ value: Bool) {
        isEditingInsightsOn = value
    }
    
    public func updateIsTimelineOfBehaviorOn(_ value: Bool) {
        isTimelineOfBehaviorOn = value
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
    
    public var hasSeenActivityTab: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenActivityTabNewOnboarding.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenActivityTabNewOnboarding.rawValue, value: newValue)
        }
    }

    public func setHasSeenActivityTab(_ value: Bool) {
        self.hasSeenActivityTab = value
    }

    public func getHasSeenActivityTab() -> Bool {
        return hasSeenActivityTab
    }
    
    public func setHasSeenSurvey(value: Bool) {
        self.hasSeenSurvey = value
    }
    
    private var hasSeenSurvey: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenActiviyTabSurvey.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenActiviyTabSurvey.rawValue, value: newValue)
        }
    }
    
    public func shouldShowSurvey() -> Bool {
        let visitCount = activityTabVisitCount
        let alreadySeenSurvey = hasSeenSurvey
        
        guard visitCount >= 3 && !alreadySeenSurvey else {
            return false
        }
        
        if let surveyEndDate {
            return surveyEndDate >= Date()
        }
        
        return false
    }
    
    private var surveyEndDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 4
        dateComponents.day = 15
        return Calendar.current.date(from: dateComponents)
    }
    
    private var activityTabVisitCount: Int {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.activityTabVisitCount.rawValue)) ?? 0
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.activityTabVisitCount.rawValue, value: newValue)
        }
    }
    
    public func incrementActivityTabVisitCount() {
        let visitCount = self.activityTabVisitCount + 1
        self.activityTabVisitCount = visitCount
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

    public func getTimelineItems(username: String?) async throws -> [Date: [TimelineItem]] {
        var edits: [TimelineItem] = []

        if let username {
            do {
                let articleEdits = try await UserContributionsDataController.shared
                    .fetchRecentEdits(username: username)

                edits = articleEdits.map { TimelineItem(articleEdit: $0) }

            } catch {
                debugPrint("Failed to fetch user edits: \(error)")
            }
        }

        let rawSavedItems = try await fetchTimelineSavedArticles()
        let readItems = try await fetchTimelineReadArticles()
        let dedupedSavedItems = Self.deduplicatedSavedItems(rawSavedItems)

        var allItems: [Date: [TimelineItem]] = [:]

        allItems.merge(dedupedSavedItems) { $0 + $1 }
        allItems.merge(readItems) { $0 + $1 }

        if !edits.isEmpty {
            var editsByDay: [Date: [TimelineItem]] = [:]

            for edit in edits {
                let day = Calendar.current.startOfDay(for: edit.date)
                editsByDay[day, default: []].append(edit)
            }

            allItems.merge(editsByDay) { $0 + $1 }
        }

        return allItems
    }

    private static func deduplicatedSavedItems(_ savedItems: [Date: [TimelineItem]]) -> [Date: [TimelineItem]] {

        struct ArticleKey: Hashable {
            let projectID: String
            let title: String
        }

        var latestByArticle: [ArticleKey: (sectionDate: Date, item: TimelineItem)] = [:]

        for (sectionDate, items) in savedItems {
            for item in items {
                guard item.itemType == .saved else {
                    continue
                }

                let key = ArticleKey(
                    projectID: item.projectID,
                    title: item.pageTitle
                )

                if let existing = latestByArticle[key] {
                    if item.date > existing.item.date {
                        latestByArticle[key] = (sectionDate, item)
                    }
                } else {
                    latestByArticle[key] = (sectionDate, item)
                }
            }
        }

        var result: [Date: [TimelineItem]] = [:]

        for (sectionDate, item) in latestByArticle.values {
            result[sectionDate, default: []].append(item)
        }

        return result
    }

    public func fetchTimelineSavedArticles() async throws -> [Date: [TimelineItem]] {
        let dataController = WMFSavedArticlesDataController()
        let savedPages = try await dataController.fetchTimelinePages()
        guard !savedPages.isEmpty else { return [:] }
        var dailyTimeline: [Date: [TimelineItem]] = [:]
        let calendar = Calendar.current

        for item in savedPages {
            let savedDate = item.timestamp
            let page = item.page
            let dayBucket = calendar.startOfDay(for: savedDate)
            let articleURL = WMFProject(id: page.projectID)?.siteURL?.wmfURL(withTitle: page.title)
            
            let identifier = String("saved~\(page.projectID)~\(page.title)~\(item.timestamp.timeIntervalSince1970)")

            let timelineItem = TimelineItem(
                id: identifier,
                date: savedDate,
                titleHtml: page.title,
                projectID: page.projectID,
                pageTitle: page.title,
                url: articleURL,
                namespaceID: page.namespaceID,
                itemType: .saved
            )
            
            dailyTimeline[dayBucket, default: []].append(timelineItem)
        }

        let sortedTimeline = dailyTimeline.mapValues { items in
            items.sorted { $0.date < $1.date }
        }

        return sortedTimeline
    }

    public func fetchTimelineReadArticles() async throws -> [Date: [TimelineItem]] {
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

            let existingItems = dailyTimeline[dayBucket]
            
            let identifier = String("read~\(page.projectID)~\(page.title)~\(record.timestamp.timeIntervalSince1970)")
            
           
            let newItem = TimelineItem(
                id: identifier,
                date: timestamp,
                titleHtml: page.title,
                projectID: page.projectID,
                pageTitle: page.title,
                url: articleURL,
                description: nil,
                imageURLString: nil,
                snippet: nil,
                namespaceID: page.namespaceID,
                itemType: .read
            )
            
            // prefer first visit to same article over last
            if var existingItems,
               let index = existingItems.firstIndex(where: { item in
                    record.page.title == item.pageTitle
               }) {
                existingItems[index] = newItem
                dailyTimeline[dayBucket] = existingItems
            } else {
                dailyTimeline[dayBucket, default: []].append(newItem)
            }
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
        guard let project = WMFProject(id: item.projectID) else { return }
        try await deletePageView(
            title: item.pageTitle,
            namespaceID: Int16(item.namespaceID),
            project: project
        )

        historyDataController?.deleteHistoryItem(timelineToHistoryItem(item))
    }

    private func timelineToHistoryItem(_ timelineItem: TimelineItem) -> HistoryItem {
        return HistoryItem(id: timelineItem.id, url: timelineItem.url, titleHtml: timelineItem.titleHtml, description: timelineItem.description, shortDescription: timelineItem.snippet, imageURLString: timelineItem.imageURLString, isSaved: false, snippet: nil, variant: nil)
    }

    public func fetchSummary(for pageTitle: String, projectID: String) async throws -> WMFArticleSummary? {
        let articleSummaryController = WMFArticleSummaryDataController.shared
        guard let project = WMFProject(id: projectID) else { return nil }
        return try await articleSummaryController.fetchArticleSummary(project: project, title: pageTitle)
    }

    public func getGlobalEditCount() async throws -> Int? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            throw CustomError.missingLanguage
        }
        let proj = WMFProject.wikipedia(appLanguage)

        do {
            let userInfoDataController = WMFGlobalUserInfoDataController(project: proj)
            let globalUserInfo = try await userInfoDataController.fetchGlobalUserInfo()
            return globalUserInfo.editcount
        } catch {
            throw CustomError.unexpectedError(error)
        }
    }

    public func getUserImpactData(userID: Int) async throws -> WMFUserImpactData {
        
        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        let project = WMFProject.wikipedia(primaryAppLanguage)
        
        let dataController = WMFUserImpactDataController.shared
        
        return try await dataController.fetch(userID: userID, project: project, language: primaryAppLanguage.languageCode)
    }

    public enum CustomError: Error {
        case missingLanguage
        case unexpectedError(Error)
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
    public let namespaceID: Int
    
    // Edit-specific properties
    public let revisionID: Int?
    public let parentRevisionID: Int?
    
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
                namespaceID: Int,
                revisionID: Int? = nil,
                parentRevisionID: Int? = nil,
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
        self.namespaceID = namespaceID
        self.revisionID = revisionID
        self.parentRevisionID = parentRevisionID
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
    case saved
}

public enum LoginState: Int {
    case loggedOut = 0
    case temp = 1
    case loggedIn = 2
}

extension TimelineItem {
    
    init(articleEdit: ArticleEdit) {
        self.init(
            id: articleEdit.id,
            date: articleEdit.date,
            titleHtml: articleEdit.title,
            projectID: articleEdit.projectID,
            pageTitle: articleEdit.title,
            url: articleEdit.url,
            namespaceID: 0,
            revisionID: articleEdit.revisionID,
            parentRevisionID: articleEdit.parentRevisionID,
            itemType: .edit
        )
    }
}
