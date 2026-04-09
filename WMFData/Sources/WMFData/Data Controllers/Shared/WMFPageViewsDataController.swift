import Foundation
import CoreData
import WidgetKit

public final class WMFPage: Hashable, Equatable {
   public let namespaceID: Int
   public let projectID: String
   public let title: String

     init(namespaceID: Int, projectID: String, title: String) {
       self.namespaceID = namespaceID
       self.projectID = projectID
       self.title = title
   }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(namespaceID)
        hasher.combine(projectID)
        hasher.combine(title)
    }

    public static func == (lhs: WMFPage, rhs: WMFPage) -> Bool {
        return
            lhs.namespaceID == rhs.namespaceID &&
            lhs.projectID == rhs.projectID &&
            lhs.title == rhs.title
    }
}

public final class WMFPageViewCount: Identifiable {

    public var id: String {
        return "\(page.projectID)~\(page.namespaceID)~\(page.title)"
    }

    public let page: WMFPage
    public let count: Int

   init(page: WMFPage, count: Int) {
       self.page = page
       self.count = count
   }
}

public final class WMFPageViewDates: Codable {
    public let days: [WMFPageViewDay]
    public let times: [WMFPageViewTime]
    public let months: [WMFPageViewMonth]

    init(days: [WMFPageViewDay], times: [WMFPageViewTime], months: [WMFPageViewMonth]) {
        self.days = days
        self.times = times
        self.months = months
    }
}

public final class WMFPageViewDay: Codable {
    public let day: Int
    public let viewCount: Int

    init(day: Int, viewCount: Int) {
        self.day = day
        self.viewCount = viewCount
    }
}

public final class WMFPageViewMonth: Codable {
    public let month: Int
    public let viewCount: Int

    init(month: Int, viewCount: Int) {
        self.month = month
        self.viewCount = viewCount
    }
}

public final class WMFPageViewTime: Codable {
    public let hour: Int
    public let viewCount: Int

    init(hour: Int, viewCount: Int) {
        self.hour = hour
        self.viewCount = viewCount
    }
}

public struct WMFPageWithTimestamp {
    public let page: WMFPage
    public let timestamp: Date
}

public final class WMFLegacyPageView: Codable, @unchecked Sendable {
    public let title: String
    let project: WMFProject
    let viewedDate: Date
    public let latitude: Double?
    public let longitude: Double?

    public init(title: String, project: WMFProject, viewedDate: Date, latitude: Double? = nil, longitude: Double? = nil) {
        self.title = title
        self.project = project
        self.viewedDate = viewedDate
        self.latitude = latitude
        self.longitude = longitude
    }
}

public final class WMFPageViewsDataController: @unchecked Sendable {

    private let coreDataStore: WMFCoreDataStore

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
    }

    public func addPageView(title: String, namespaceID: Int16, project: WMFProject, previousPageViewObjectID: NSManagedObjectID?, timestamp: Date? = nil) async throws -> NSManagedObjectID? {

        let coreDataTitle = title.normalizedForCoreData
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let managedObjectID: NSManagedObjectID? = try await backgroundContext.perform { [weak self] () -> NSManagedObjectID? in
            guard let self else { return nil }
            let timestamp = timestamp ?? Date()
            let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.id, namespaceID, coreDataTitle])
            let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
            page?.title = coreDataTitle
            page?.namespaceID = namespaceID
            page?.projectID = project.id
            page?.timestamp = timestamp

            let viewedPage = try self.coreDataStore.create(entityType: CDPageView.self, in: backgroundContext)
            viewedPage.page = page
            viewedPage.timestamp = timestamp

            if let previousPageViewObjectID,
               let previousPageView = backgroundContext.object(with: previousPageViewObjectID) as? CDPageView {
                viewedPage.previousPageView = previousPageView
            }

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
            return viewedPage.objectID
        }

        return managedObjectID
    }

    public func addPageViewSeconds(pageViewManagedObjectID: NSManagedObjectID, numberOfSeconds: Double) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }
            guard let pageView = backgroundContext.object(with: pageViewManagedObjectID) as? CDPageView else { return }
            pageView.numberOfSeconds += Int64(numberOfSeconds)
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func deletePageView(title: String, namespaceID: Int16, project: WMFProject) async throws {
        let coreDataTitle = title.normalizedForCoreData
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }
            let pagePredicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.id, namespaceID, coreDataTitle])
            guard let page = try self.coreDataStore.fetch(entityType: CDPage.self, predicate: pagePredicate, fetchLimit: 1, in: backgroundContext)?.first else { return }
            let pageViewsPredicate = NSPredicate(format: "page == %@", argumentArray: [page])
            guard let pageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, predicate: pageViewsPredicate, fetchLimit: nil, in: backgroundContext) else { return }
            for pageView in pageViews { backgroundContext.delete(pageView) }
            try coreDataStore.saveIfNeeded(moc: backgroundContext)
        }

        let categoriesDataController = try WMFCategoriesDataController(coreDataStore: self.coreDataStore)
        try await categoriesDataController.deleteEmptyCategories()
    }

    public func deleteAllPageViewsAndCategories() async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await backgroundContext.perform {
            let categoryFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDCategory")
            let batchCategoryDeleteRequest = NSBatchDeleteRequest(fetchRequest: categoryFetchRequest)
            batchCategoryDeleteRequest.resultType = .resultTypeObjectIDs
            _ = try backgroundContext.execute(batchCategoryDeleteRequest) as? NSBatchDeleteResult

            let pageViewFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageView")
            let batchPageViewDeleteRequest = NSBatchDeleteRequest(fetchRequest: pageViewFetchRequest)
            batchPageViewDeleteRequest.resultType = .resultTypeObjectIDs
            _ = try backgroundContext.execute(batchPageViewDeleteRequest) as? NSBatchDeleteResult

            backgroundContext.refreshAllObjects()
        }
    }

    public func importPageViews(requests: [WMFLegacyPageView]) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await backgroundContext.perform {
            for request in requests {
                let coreDataTitle = request.title.normalizedForCoreData
                let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [request.project.id, 0, coreDataTitle])
                let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
                page?.title = coreDataTitle
                page?.namespaceID = 0
                page?.projectID = request.project.id
                page?.timestamp = request.viewedDate

                let viewedPage = try self.coreDataStore.create(entityType: CDPageView.self, in: backgroundContext)
                viewedPage.page = page
                viewedPage.timestamp = request.viewedDate
            }
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func fetchPageViewCounts(startDate: Date, endDate: Date) async throws -> [WMFPageViewCount] {
        let backgroundContext = try coreDataStore.newBackgroundContext

        let results: [WMFPageViewCount] = try await backgroundContext.perform {
            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
            let pageViewsDict = try self.coreDataStore.fetchGrouped(entityType: CDPageView.self, predicate: predicate, propertyToCount: "page", propertiesToGroupBy: ["page"], propertiesToFetch: ["page"], in: backgroundContext)
            var pageViewCounts: [WMFPageViewCount] = []
            for dict in pageViewsDict {
                guard let objectID = dict["page"] as? NSManagedObjectID,
                      let count = dict["count"] as? Int else { continue }
                guard let page = backgroundContext.object(with: objectID) as? CDPage,
                      let projectID = page.projectID, let title = page.title else { continue }
                let namespaceID = page.namespaceID
                pageViewCounts.append(WMFPageViewCount(page: WMFPage(namespaceID: Int(namespaceID), projectID: projectID, title: title), count: count))
            }
            return pageViewCounts
        }

        return results
    }

    public func fetchPageViewMinutes(startDate: Date, endDate: Date) async throws -> Int {
        let backgroundContext = try coreDataStore.newBackgroundContext

        let result: Int64 = try await backgroundContext.perform {
            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
            let request = NSFetchRequest<NSDictionary>(entityName: "CDPageView")
            request.predicate = predicate

            let sumExpression = NSExpressionDescription()
            sumExpression.name = "totalSeconds"
            sumExpression.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: "numberOfSeconds")])
            sumExpression.expressionResultType = .integer64AttributeType
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [sumExpression]

            if let result = try backgroundContext.fetch(request).first,
               let totalSeconds = result["totalSeconds"] as? Int64 {
                return totalSeconds / Int64(60)
            }
            return 0
        }

        return Int(result)
    }

    func fetchPageViewDates(startDate: Date, endDate: Date, moc: NSManagedObjectContext? = nil) async throws -> WMFPageViewDates? {
        let backgroundContext = try coreDataStore.newBackgroundContext

        let results: WMFPageViewDates? = try await backgroundContext.perform { () -> WMFPageViewDates? in
            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
            let cdPageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, predicate: predicate, fetchLimit: nil, in: backgroundContext)
            guard let cdPageViews = cdPageViews else { return nil }

            var countsDictionaryDay: [Int: Int] = [:]
            var countsDictionaryTime: [Int: Int] = [:]
            var countsDictionaryMonth: [Int: Int] = [:]

            for cdPageView in cdPageViews {
                if let timestamp = cdPageView.timestamp {
                    let calendar = Calendar.current
                    let dayOfWeek = calendar.component(.weekday, from: timestamp)
                    let hourOfDay = calendar.component(.hour, from: timestamp)
                    let month = calendar.component(.month, from: timestamp)
                    countsDictionaryDay[dayOfWeek, default: 0] += 1
                    countsDictionaryTime[hourOfDay, default: 0] += 1
                    countsDictionaryMonth[month, default: 0] += 1
                }
            }

            let days = countsDictionaryDay.sorted(by: { $0.key < $1.key }).map { WMFPageViewDay(day: $0.key, viewCount: $0.value) }
            let times = countsDictionaryTime.sorted(by: { $0.key < $1.key }).map { WMFPageViewTime(hour: $0.key, viewCount: $0.value) }
            let months = countsDictionaryMonth.sorted(by: { $0.key < $1.key }).map { WMFPageViewMonth(month: $0.key, viewCount: $0.value) }
            return WMFPageViewDates(days: days, times: times, months: months)
        }

        return results
    }

    public func fetchLinkedPageViews() async throws -> [[CDPageView]] {
        let context = try coreDataStore.viewContext

        let result: [[CDPageView]] = try await context.perform {
            let fetchRequest: NSFetchRequest<CDPageView> = CDPageView.fetchRequest()
            let allPageViews = try context.fetch(fetchRequest)
            let roots = allPageViews.filter { $0.previousPageView == nil }
            var result: [[CDPageView]] = []

            func walk(current: CDPageView, path: [CDPageView]) {
                let newPath = path + [current]
                let nextViews = (current.nextPageViews as? Set<CDPageView>) ?? []
                if nextViews.isEmpty {
                    let sortedPath = newPath.sorted(by: { $0.timestamp ?? .distantPast < $1.timestamp ?? .distantPast })
                    result.append(sortedPath)
                } else {
                    for next in nextViews { walk(current: next, path: newPath) }
                }
            }

            for root in roots { walk(current: root, path: []) }
            return result
        }

        return result
    }

    public func fetchMostRecentTime() async throws -> Date? {
        let backgroundContext = try coreDataStore.newBackgroundContext

        let result: Date? = try await backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageView")
            fetchRequest.fetchLimit = 1
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            if let pageView = try backgroundContext.fetch(fetchRequest).first as? CDPageView {
                return pageView.timestamp
            }
            return nil
        }

        return result
    }

    public func fetchTimelinePages() async throws -> [WMFPageWithTimestamp] {
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let results: [WMFPageWithTimestamp] = try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<CDPageView> = CDPageView.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            fetchRequest.fetchLimit = 1000

            let pageViews = try backgroundContext.fetch(fetchRequest)
            var result: [WMFPageWithTimestamp] = []

            for pageView in pageViews {
                guard
                    let page = pageView.page,
                    let projectID = page.projectID,
                    let title = page.title,
                    let timestamp = pageView.timestamp
                else { continue }

                let wmfPage = WMFPage(namespaceID: Int(page.namespaceID), projectID: projectID, title: title)
                result.append(WMFPageWithTimestamp(page: wmfPage, timestamp: timestamp))
            }

            return result
        }

        return results
    }
}

// MARK: - Reading Challenge

extension WMFPageViewsDataController {

    public func fetchReadingChallengeState(
        isEnrolled: Bool,
        now: Date = Date()
    ) async throws -> ReadingChallengeState {

        // Developer override — only applies when master toggle is on
        let devDefaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia")
        func devBool(_ key: WMFUserDefaultsKey) -> Bool {
            devDefaults?.bool(forKey: key.rawValue) ?? false
        }
        func setDevBool(_ key: WMFUserDefaultsKey, value: Bool) {
            devDefaults?.set(true, forKey: key.rawValue)
        }
        if devBool(.devForceReadingChallengeEnabled) {
            let storedStreak = devDefaults?.integer(forKey: WMFUserDefaultsKey.devForceReadingChallengeStreakCount.rawValue) ?? 0
            let devStreak = storedStreak == 0 ? 7 : storedStreak
            if devBool(.devForceReadingChallengeCompletedFullStreak) { return .challengeCompleted }
            if devBool(.devForceReadingChallengeCompletedIncompleteStreak) { return .challengeConcludedIncomplete(streak: devStreak) }
            if devBool(.devForceReadingChallengeCompletedNoStreak) { return .challengeConcludedNoStreak }
            if devBool(.devForceReadingChallengeNotLiveYet) { return .notLiveYet }
            if devBool(.devForceReadingChallengeEnrolledNotStarted) { return .enrolledNotStarted }
            if devBool(.devForceReadingChallengeStreakOngoingRead) { return .streakOngoingRead(streak: devStreak) }
            if devBool(.devForceReadingChallengeStreakOngoingNotYetRead) { return .streakOngoingNotYetRead(streak: devStreak) }
            return .notEnrolled
        }

        let config = ReadingChallengeStateConfig.self
        let calendar = Calendar.current

        let todayStart = calendar.startOfDay(for: now)
        let removeDateStart = calendar.startOfDay(for: config.removeDate)
        let startDateStart = calendar.startOfDay(for: config.startDate)
        let endDateStart = calendar.startOfDay(for: config.endDate)
        let oneDayInSeconds = 60 * 60  * 24
        let maxDateToCompleteStreak = calendar.startOfDay(for:endDateStart.addingTimeInterval(TimeInterval((config.streakGoal * oneDayInSeconds))))

        if todayStart > removeDateStart {
            return .challengeRemoved
        }

        if todayStart < startDateStart {
            return .notLiveYet
        }

        guard isEnrolled else {
            return .notEnrolled
        }

        let (streak, hasReadToday, streakStartedAfterEnrollmentCutoff) = try await computeStreak(
            calendar: calendar,
            now: now,
            startDate: config.startDate,
            endDate: config.endDate
        )

        // Cap at goal — completion is terminal, no need to count beyond it
        let cappedStreak = min(streak, config.streakGoal)
        
        // Note: once a user successfully completes a reading streak, computeStreak starts to evaluate to 0 a few days later.
        // This user defaults boolean gets around that bug
        if devBool(.userCompletedReadingChallenge) {
            return .challengeCompleted
        }

        if cappedStreak >= config.streakGoal {
            setDevBool(.userCompletedReadingChallenge, value: true)
            return .challengeCompleted
        }

        if todayStart > endDateStart {
            if streakStartedAfterEnrollmentCutoff {
                return .challengeConcludedNoStreak
            }
            
            if cappedStreak == 0 {
                return .challengeConcludedNoStreak
            }
        }
        
        if todayStart > maxDateToCompleteStreak {
            return cappedStreak > 1
                ? .challengeConcludedIncomplete(streak: cappedStreak)
                : .challengeConcludedNoStreak
        }

        if cappedStreak == 0 {
            return .enrolledNotStarted
        }

        return hasReadToday
            ? .streakOngoingRead(streak: cappedStreak)
            : .streakOngoingNotYetRead(streak: cappedStreak)
    }

    private func computeStreak(
        calendar: Calendar,
        now: Date,
        startDate: Date,
        endDate: Date
    ) async throws -> (streak: Int, hasReadToday: Bool, streakStartedAfterEnrollmentCutoff: Bool) {

        let backgroundContext = try coreDataStore.newBackgroundContext

        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<CDPageView> = CDPageView.fetchRequest()
            fetchRequest.propertiesToFetch = ["timestamp"]
            let allViews = try backgroundContext.fetch(fetchRequest)

            let startOfChallengeStart = calendar.startOfDay(for: startDate)

            var daysWithRead = Set<DateComponents>()
            for view in allViews {
                guard let ts = view.timestamp else { continue }
                guard calendar.startOfDay(for: ts) >= startOfChallengeStart else { continue }
                let comps = calendar.dateComponents([.year, .month, .day], from: ts)
                daysWithRead.insert(comps)
            }

            let todayStart = calendar.startOfDay(for: now)
            let todayComps = calendar.dateComponents([.year, .month, .day], from: todayStart)
            let hasReadToday = daysWithRead.contains(todayComps)

            var streak = 0
            var cursor = todayStart
            var streakStartDate: Date = todayStart

            while true {
                let cursorComps = calendar.dateComponents([.year, .month, .day], from: cursor)

                if cursor == todayStart {
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                    cursor = yesterday
                    continue
                }

                if daysWithRead.contains(cursorComps) {
                    streak += 1
                    streakStartDate = cursor
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                    cursor = prev
                } else {
                    break
                }
            }

            if hasReadToday {
                streak += 1
                if streak == 1 { streakStartDate = todayStart }
            }

            let endDateStart = calendar.startOfDay(for: endDate)
            let streakStartedAfterEnrollmentCutoff = streak > 0 && streakStartDate > endDateStart

            return (streak, hasReadToday, streakStartedAfterEnrollmentCutoff)
        }
    }
}
