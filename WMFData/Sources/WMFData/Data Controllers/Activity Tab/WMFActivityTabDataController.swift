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
    
    public func getArticlesRead() async throws -> Int? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return 0 }
        let endDate = now
        
        let dataController = try WMFPageViewsDataController()
        let pageCounts = try await dataController.fetchPageViewCounts(startDate: startOfMonth, endDate: endDate)
        
        let totalReads = pageCounts.reduce(0) { $0 + $1.count }
        
        return totalReads
    }
    
    public func getWeeklyReadsThisMonth() async throws -> [Int]? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return nil }
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let dataController = try WMFPageViewsDataController()
        var weeklyCounts: [Int] = []
        
        var currentStart = startOfMonth
        
        while currentStart <= endOfMonth {
            guard let currentEnd = calendar.date(byAdding: .day, value: 6, to: currentStart) else { break }
            let blockEnd = min(currentEnd, endOfMonth)
             
            let pageCounts = try await dataController.fetchPageViewCounts(startDate: currentStart, endDate: blockEnd)
            let count = pageCounts.reduce(0) { $0 + $1.count }
            
            weeklyCounts.append(count)
            
            guard let nextStart = calendar.date(byAdding: .day, value: 7, to: currentStart) else { break }
            currentStart = nextStart
        }
        
        return weeklyCounts
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
        let dataController = try WMFPageViewsDataController()

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
}
