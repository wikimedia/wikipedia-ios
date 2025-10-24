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

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return 0
        }

        let endDate = now
        
        let dataController = try WMFPageViewsDataController()
        let articlesRead = try await dataController.fetchPageViewCounts(startDate: startOfMonth, endDate: endDate)

        return articlesRead.count
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
}
