import Foundation

@objc public enum WMFActivityTabExperimentAssignment: Int {
    case unknown = -1
    case control = 0
    case activityTab = 1
}

public actor WMFActivityTabDataController {
    public static let shared = WMFActivityTabDataController()
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    private let experimentsDataController: WMFExperimentsDataController?
    private var assignmentCache: WMFActivityTabExperimentAssignment?
    private let activityTabExperimentPercentage: Int = 50

    public init(developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared,
                experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        if let experimentStore {
            self.experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        } else {
            self.experimentsDataController = nil
        }
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

    public func shouldShowLoginPrompt(for state: LoginState) -> Bool {
        switch state {
        case .loggedIn:
            return false
        case .temp:
            return !tempAccountUserHasDismissedActivityTabLogInPrompt
        case .loggedOut:
            return !loggedOutUserHasDismissedActivityTabLogInPrompt
        }
    }
    
    public var loggedOutUserHasDismissedActivityTabLogInPrompt: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.activityTabUserDismissLogin.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.activityTabUserDismissLogin.rawValue, value: newValue)
        }
    }
    
    public var tempAccountUserHasDismissedActivityTabLogInPrompt: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.activityTabTempAccountUserDismissLogin.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.activityTabTempAccountUserDismissLogin.rawValue, value: newValue)
        }
    }
    
    public func setLoggedOutUserHasDismissedActivityTabLogInPrompt(_ value: Bool) async {
        loggedOutUserHasDismissedActivityTabLogInPrompt = value
    }

    public func setTempAccountUserHasDismissedActivityTabLogInPrompt(_ value: Bool) async {
        tempAccountUserHasDismissedActivityTabLogInPrompt = value
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
        dateComponents.month = 1
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

    public func getTimelineItems() async throws -> [Date: [TimelineItem]] {
        let rawSavedItems = try await fetchTimelineSavedArticles()
        let readItems = try await fetchTimelineReadArticles()

        let dedupedSavedItems = Self.deduplicatedSavedItems(rawSavedItems)

        var allItems: [Date: [TimelineItem]] = [:]

        allItems.merge(dedupedSavedItems) { old, new in
            old + new
        }

        allItems.merge(readItems) { old, new in
            old + new
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

            var todaysPages = Set<String>()
            if let existingItems = dailyTimeline[dayBucket] {
                todaysPages = Set(existingItems.map { $0.pageTitle })
            }
            
            let identifier = String("read~\(page.projectID)~\(page.title)~\(record.timestamp.timeIntervalSince1970)")

            guard !todaysPages.contains(page.title) else { continue }

            let item = TimelineItem(
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
        guard let project = WMFProject(id: item.projectID) else { return }
        try await deletePageView(
            title: item.pageTitle,
            namespaceID: Int16(item.namespaceID),
            project: project
        )
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
    
    public func getUserImpactData(userID: Int) async throws -> WMFUserImpactDataController.APIResponse {
        
        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        let project = WMFProject.wikipedia(primaryAppLanguage)
        
        let dataController = WMFUserImpactDataController.shared
        
        return try await dataController.fetch(userID: userID, project: project, language: primaryAppLanguage.languageCode)
    }

    // MARK: - Experiment

    public func assignOrFetchExperimentAssignment() throws -> WMFActivityTabExperimentAssignment {
        if isForceControlDevSettingOn {
            return .control
        }
        if isForceExperimentDevSettingOn {
            return .activityTab
        }

        guard isDevSettingOn || hasExperimentStarted() else {
            throw CustomError.beforeStartDate
        }

        if let assignmentCache {
            return assignmentCache
        }

        if let bucketValue = experimentsDataController?.bucketForExperiment(.activityTab) {
            let assignment: WMFActivityTabExperimentAssignment

            switch bucketValue {
            case .activityTabControl:
                assignment = .control
            case .activityTabExperiment:
                assignment = .activityTab
            default:
                assignment = .unknown
            }

            self.assignmentCache = assignment
            return assignment
        }

        // return assigment if existing, do not assign new if past experiment end date
        guard isDevSettingOn || !hasExperimentEnded() else {
            throw CustomError.pastAssignmentEndDate
        }

        let newAssignment = try assignExperiment()
        self.assignmentCache = newAssignment
        return newAssignment
    }

    private func assignExperiment() throws -> WMFActivityTabExperimentAssignment {

        guard isDevSettingOn || hasExperimentStarted() else {
            throw CustomError.beforeStartDate
        }

        guard isDevSettingOn || !hasExperimentEnded() else {
            throw CustomError.pastAssignmentEndDate
        }

        guard !alreadyAssigned else {
            throw CustomError.alreadyAssignedExperiment
        }

        guard let experimentsDataController else {
            throw CustomError.missingExperimentsDataController
        }

        let bucketValue = try experimentsDataController.determineBucketForExperiment(.activityTab, withPercentage: activityTabExperimentPercentage)

        var assignment: WMFActivityTabExperimentAssignment

        switch bucketValue {
        case .activityTabControl:
            assignment = .control
        case .activityTabExperiment:
            assignment = .activityTab
        default:
            throw CustomError.unexpectedAssignment
        }
        assignmentCache = assignment
        return assignment
    }

     public var isDevSettingOn: Bool {
         get {
             return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue)) ?? false
         } set {
             try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue, value: newValue)
         }
     }

    public var isForceControlDevSettingOn: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceActivityTabControl.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceActivityTabControl.rawValue, value: newValue)
        }
    }

    public var isForceExperimentDevSettingOn: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsForceActivityTabExperiment.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceActivityTabExperiment.rawValue, value: newValue)
        }
    }

    public var alreadyAssigned: Bool {
       return experimentsDataController?.bucketForExperiment(.activityTab) != nil
    }

    private var experimentEndDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 1
        dateComponents.day = 15
        return Calendar.current.date(from: dateComponents)
    }

    private var experimentStartDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 12
        dateComponents.day = 1
        return Calendar.current.date(from: dateComponents)
    }

    private func hasExperimentStarted() -> Bool {
        guard let experimentStartDate else {
            return false
        }
        return experimentStartDate <= Date()
    }

    private func hasExperimentEnded() -> Bool {
        guard let experimentEndDate else {
            return false
        }
        return experimentEndDate <= Date()
    }

    public enum CustomError: Error {

        case missingExperimentsDataController
        case unexpectedAssignment
        case missingAssignment
        case alreadyAssignedExperiment
        case pastAssignmentEndDate
        case beforeStartDate
        case errorFetchingAssigment
        case missingLanguage
        case unexpectedError(Error)
    }

}

extension WMFActivityTabDataController {

    public nonisolated static func activityAssignmentForObjC() -> WMFActivityTabExperimentAssignment {
        let semaphore = DispatchSemaphore(value: 0)
        var result: WMFActivityTabExperimentAssignment = .unknown

        Task {
            let controller = WMFActivityTabDataController.shared

            let assignment: WMFActivityTabExperimentAssignment?
            do {
                assignment = try await controller.assignOrFetchExperimentAssignment()
            } catch {
                debugPrint("Error in activityAssignmentForObjC: \(error)")
                assignment = nil
            }

            result = assignment ?? .unknown
            semaphore.signal()
        }

        semaphore.wait()
        return result
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
