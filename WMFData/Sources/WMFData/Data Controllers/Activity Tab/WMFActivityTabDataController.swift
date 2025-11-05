import Foundation

public actor WMFActivityTabDataController {
    public static let shared = WMFActivityTabDataController()
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? {
        return _coreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) {
        self._coreDataStore = coreDataStore
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
    
    private(set) public var hasSeenActivityTab: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenActivityTab.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenActivityTab.rawValue, value: newValue)
        }
    }

    public func setHasSeenActivityTab(_ value: Bool) {
            self.hasSeenActivityTab = value
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

        guard let count = try? await fetchSavedCounts(startDate: startDate, endDate: endDate) else {return nil}

        return SavedArticleModuleData(savedArticlesCount: count, articleUrlStrings: [], dateLastSaved: Date())

    }

    func fetchSavedCounts(startDate: Date, endDate: Date) async throws -> Int {
        guard let coreDataStore = self.coreDataStore else {
            throw WMFServiceError.missingData
        }
        let context = try coreDataStore.newBackgroundContext

        let startNSDate = startDate as NSDate
        let endNSDate = endDate as NSDate

        return try await context.perform {
            let predicate = NSPredicate(
                format: "savedDate != nil AND savedDate.savedDate >= %@ AND savedDate.savedDate <= %@",
                startNSDate, endNSDate
            )

            let pages: [CDPage]? = try coreDataStore.fetch(
                entityType: CDPage.self,
                predicate: predicate,
                fetchLimit: nil,
                in: context
            )

            return pages?.count ?? 0
        }
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
    public let articleUrlStrings: [String]
    public let dateLastSaved: Date?

    public init(savedArticlesCount: Int, articleUrlStrings: [String], dateLastSaved: Date?) {
        self.savedArticlesCount = savedArticlesCount
        self.articleUrlStrings = articleUrlStrings
        self.dateLastSaved = dateLastSaved
    }
}
