import Foundation

public actor WMFActivityTabDataController {
    public static let shared = WMFActivityTabDataController()
    private let articleSummaryDataController: WMFArticleSummaryDataController
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? {
        return _coreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore,
                articleSummaryDataController: WMFArticleSummaryDataController = .init()
    ) {
        self._coreDataStore = coreDataStore
        self.articleSummaryDataController = articleSummaryDataController
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
    
    private var hasSeenActivityTab: Bool {
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

    // MARK: - Saved articles

    public func getSavedArticleModuleData(from startDate: Date, to endDate: Date) async -> SavedArticleModuleData? {
        guard let pages = try? await fetchSavedArticleSnapshots(startDate: startDate, endDate: endDate) else {return nil}

        var lastDate: Date?
        var randomURLs: [URL?] = []

        if let lastDateSaved = pages.first?.savedDate {
            lastDate = lastDateSaved
        }

        if let thumbnailURLs = try? await fetchSavedArticlesImageURLs(startDate: startDate, endDate: endDate) {
            randomURLs = thumbnailURLs
        }

        return SavedArticleModuleData(savedArticlesCount: pages.count, articleThumbURLs: randomURLs, dateLastSaved: lastDate)
    }

    private func fetchSavedArticleSnapshots(startDate: Date, endDate: Date) async throws -> [SavedArticleSnapshot] {
        guard let coreDataStore else { throw WMFServiceError.missingData }
        let context = try coreDataStore.newBackgroundContext

        let startNSDate = startDate as NSDate
        let endNSDate   = endDate as NSDate

        return try await context.perform {
            let sortDescriptor = NSSortDescriptor(key: "savedDate.savedDate", ascending: false)
            let predicate = NSPredicate(
                format: "savedDate != nil AND savedDate.savedDate >= %@ AND savedDate.savedDate <= %@",
                startNSDate, endNSDate
            )

            guard
                let pages: [CDPage] = try coreDataStore.fetch(
                    entityType: CDPage.self,
                    predicate: predicate,
                    fetchLimit: nil,
                    sortDescriptors: [sortDescriptor],
                    in: context
                )
            else { return [] }

            var snapshots: [SavedArticleSnapshot] = []
            snapshots.reserveCapacity(pages.count)

            for page in pages {
                guard
                    let projectID = page.projectID,
                    let title = page.title, !title.isEmpty
                else { continue }

                let project = WMFProject(id: projectID)
                let url = project?.siteURL?.wmfURL(withTitle: title, languageVariantCode: nil)
                let date = page.savedDate?.savedDate

                snapshots.append(
                    SavedArticleSnapshot(
                        projectID: projectID,
                        title: title,
                        namespaceID: page.namespaceID,
                        savedDate: date,
                        articleURL: url
                    )
                )
            }
            return snapshots
        }
    }

    private func fetchSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary {
        try await withCheckedThrowingContinuation { continuation in
            articleSummaryDataController.fetchArticleSummary(project: project, title: title) { result in
                switch result {
                case .success(let summary):
                    continuation.resume(returning: summary)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchSavedArticlesImageURLs(startDate: Date, endDate: Date) async throws -> [URL?] {
        let snapshots = try await fetchSavedArticleSnapshots(startDate: startDate, endDate: endDate)
        guard !snapshots.isEmpty else { return [] }

        return await withTaskGroup(of: URL?.self) { group in
            for snap in snapshots {
                group.addTask { [snap] in
                    guard let project = WMFProject(id: snap.projectID) else { return nil }
                    do {
                        let summary = try await self.fetchSummary(project: project, title: snap.title)
                        return summary.thumbnailURL
                    } catch {
                        return nil
                    }
                }
            }

            var urls = [URL?]()
            for await url in group {
                if let url { urls.append(url) }
            }
            return urls
        }
    }

    /// Helper struct for lighter data access
    private struct SavedArticleSnapshot: Sendable {
        let projectID: String
        let title: String
        let namespaceID: Int16
        let savedDate: Date?
        let articleURL: URL?
    }
}

extension WMFActivityTabDataController {
    @objc public nonisolated static func activityAssignmentForObjC() -> Int {
        let key = WMFUserDefaultsKey.developerSettingsShowActivityTab.rawValue
        let value = (try? WMFDataEnvironment.current.userDefaultsStore?.load(key: key)) ?? false
        return value ? 1 : 0
    }
}

public struct SavedArticleModuleData: Codable {
    public let savedArticlesCount: Int
    public let articleThumbURLs: [URL?]
    public let dateLastSaved: Date?

    public init(savedArticlesCount: Int, articleThumbURLs: [URL?], dateLastSaved: Date?) {
        self.savedArticlesCount = savedArticlesCount
        self.articleThumbURLs = articleThumbURLs
        self.dateLastSaved = dateLastSaved
    }
}
