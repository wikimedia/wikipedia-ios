import Foundation
import CoreData

public final class WMFPageView: Sendable {
    let numberOfSeconds: Int
    let timestamp: Date?
    let nextPageViews: [WMFPageView]
    let page: WMFPage
    let previousPageView: WMFPageView?
    
    init(numberOfSeconds: Int, timestamp: Date?, nextPageViews: [WMFPageView], page: WMFPage, previousPageView: WMFPageView) {
        self.numberOfSeconds = numberOfSeconds
        self.timestamp = timestamp
        self.nextPageViews = nextPageViews
        self.page = page
        self.previousPageView = previousPageView
    }
    
    init?(cdPageView: CDPageView) {
        self.numberOfSeconds = Int(cdPageView.numberOfSeconds)
        self.timestamp = cdPageView.timestamp
        if let nextCDPageViews = cdPageView.nextPageViews as? Set<CDPageView> {
            self.nextPageViews = nextCDPageViews.compactMap { WMFPageView(cdPageView: $0) }
        } else {
            self.nextPageViews = []
        }
        
        if let wmfPage = WMFPage(cdPage: cdPageView.page) {
            self.page = wmfPage
        } else {
            return nil
        }
        
        if let previousCDPageView = cdPageView.previousPageView {
            self.previousPageView = WMFPageView(cdPageView: previousCDPageView)
        } else {
            previousPageView = nil
        }
    }
}

public final class WMFPage: Hashable, Equatable, Sendable {
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
    
    init?(cdPage: CDPage?) {
        guard let cdPage,
              let projectID = cdPage.projectID,
              let title = cdPage.title else {
            return nil
        }
        self.namespaceID = Int(cdPage.namespaceID)
        self.projectID = projectID
        self.title = title
    }

 }

public final class WMFPageViewCount: Identifiable, Sendable {
    
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

public final class WMFPageViewDates: Codable, Sendable {
    public let days: [WMFPageViewDay]
    public let times: [WMFPageViewTime]
    public let months: [WMFPageViewMonth]
    
    init(days: [WMFPageViewDay], times: [WMFPageViewTime], months: [WMFPageViewMonth]) {
        self.days = days
        self.times = times
        self.months = months
    }
}

public final class WMFPageViewDay: Codable, Sendable {
    public let day: Int
    public let viewCount: Int
    
    init(day: Int, viewCount: Int) {
        self.day = day
        self.viewCount = viewCount
    }
}

public final class WMFPageViewMonth: Codable, Sendable {
    public let month: Int
    public let viewCount: Int
    
    init(month: Int, viewCount: Int) {
        self.month = month
        self.viewCount = viewCount
    }
}

public final class WMFPageViewTime: Codable, Sendable {
    public let hour: Int
    public let viewCount: Int
    
    init(hour: Int, viewCount: Int) {
        self.hour = hour
        self.viewCount = viewCount
    }
}

public struct WMFPageWithTimestamp: Sendable {
    public let page: WMFPage
    public let timestamp: Date
}

public final class WMFLegacyPageView: Codable, Sendable {
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

public actor WMFPageViewsDataController {
    
    private let coreDataStore: WMFCoreDataStore
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        self.coreDataStore = coreDataStore
    }
    
    public func addPageView(title: String, namespaceID: Int16, project: WMFProject, previousPageViewObjectID: NSManagedObjectID?, timestamp: Date? = nil) async throws -> NSManagedObjectID? {
        
        let coreDataTitle = title.normalizedForCoreData
        
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let timestamp = timestamp ?? Date()
                    let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.id, namespaceID, coreDataTitle])
                    let page = try store.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
                    page?.title = coreDataTitle
                    page?.namespaceID = namespaceID
                    page?.projectID = project.id
                    page?.timestamp = timestamp
                    
                    let viewedPage = try store.create(entityType: CDPageView.self, in: backgroundContext)
                    viewedPage.page = page
                    viewedPage.timestamp = timestamp
                    
                    if let previousPageViewObjectID,
                       let previousPageView = backgroundContext.object(with: previousPageViewObjectID) as? CDPageView {
                        viewedPage.previousPageView = previousPageView
                    }
                    
                    try store.saveIfNeeded(moc: backgroundContext)
                    
                    continuation.resume(returning: viewedPage.objectID)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func addPageViewSeconds(pageViewManagedObjectID: NSManagedObjectID, numberOfSeconds: Double) async throws {
        
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                do {
                    guard let pageView = backgroundContext.object(with: pageViewManagedObjectID) as? CDPageView else {
                        continuation.resume()
                        return
                    }
                    
                    pageView.numberOfSeconds += Int64(numberOfSeconds)
                    
                    try store.saveIfNeeded(moc: backgroundContext)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func deletePageView(title: String, namespaceID: Int16, project: WMFProject) async throws {
        
        let coreDataTitle = title.normalizedForCoreData
        
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                do {
                    let pagePredicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.id, namespaceID, coreDataTitle])
                    guard let page = try store.fetch(entityType: CDPage.self, predicate: pagePredicate, fetchLimit: 1, in: backgroundContext)?.first else {
                        continuation.resume()
                        return
                    }
                    
                    let pageViewsPredicate = NSPredicate(format: "page == %@", argumentArray: [page])
                    
                    guard let pageViews = try store.fetch(entityType: CDPageView.self, predicate: pageViewsPredicate, fetchLimit: nil, in: backgroundContext) else {
                        continuation.resume()
                        return
                    }
                    
                    for pageView in pageViews {
                        backgroundContext.delete(pageView)
                    }
                    
                    try store.saveIfNeeded(moc: backgroundContext)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        let categoriesDataController = try WMFCategoriesDataController(coreDataStore: self.coreDataStore)
        try await categoriesDataController.deleteEmptyCategories()
    }
    
    public func deleteAllPageViewsAndCategories() async throws {
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                do {
                    let categoryFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDCategory")
                    
                    let batchCategoryDeleteRequest = NSBatchDeleteRequest(fetchRequest: categoryFetchRequest)
                    batchCategoryDeleteRequest.resultType = .resultTypeObjectIDs
                    _ = try backgroundContext.execute(batchCategoryDeleteRequest) as? NSBatchDeleteResult
                    
                    let pageViewFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageView")
                    
                    let batchPageViewDeleteRequest = NSBatchDeleteRequest(fetchRequest: pageViewFetchRequest)
                    batchPageViewDeleteRequest.resultType = .resultTypeObjectIDs
                    _ = try backgroundContext.execute(batchPageViewDeleteRequest) as? NSBatchDeleteResult
                    
                    backgroundContext.refreshAllObjects()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func importPageViews(requests: [WMFLegacyPageView]) async throws {
        
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                do {
                    for request in requests {
                        
                        let coreDataTitle = request.title.normalizedForCoreData
                        let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [request.project.id, 0, coreDataTitle])
                        
                        let page = try store.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
                        page?.title = coreDataTitle
                        page?.namespaceID = 0
                        page?.projectID = request.project.id
                        page?.timestamp = request.viewedDate
                        
                        let viewedPage = try store.create(entityType: CDPageView.self, in: backgroundContext)
                        viewedPage.page = page
                        viewedPage.timestamp = request.viewedDate
                    }
                    
                    try store.saveIfNeeded(moc: backgroundContext)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchPageViewCounts(startDate: Date, endDate: Date) async throws -> [WMFPageViewCount] {
        
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
                    let pageViewsDict = try store.fetchGrouped(entityType: CDPageView.self, predicate: predicate, propertyToCount: "page", propertiesToGroupBy: ["page"], propertiesToFetch: ["page"], in: backgroundContext)
                    var pageViewCounts: [WMFPageViewCount] = []
                    for dict in pageViewsDict {
                        
                        guard let objectID = dict["page"] as? NSManagedObjectID,
                              let count = dict["count"] as? Int else {
                            continue
                        }
                        
                        guard let page = backgroundContext.object(with: objectID) as? CDPage,
                              let projectID = page.projectID, let title = page.title else {
                            continue
                        }
                        
                        let namespaceID = page.namespaceID
                        
                        pageViewCounts.append(WMFPageViewCount(page: WMFPage(namespaceID: Int(namespaceID), projectID: projectID, title: title), count: count))
                    }
                    continuation.resume(returning: pageViewCounts)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchPageViewMinutes(startDate: Date, endDate: Date) async throws -> Int {
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
                    
                    let request = NSFetchRequest<NSDictionary>(entityName: "CDPageView")
                    request.predicate = predicate

                    let sumExpression = NSExpressionDescription()
                    sumExpression.name = "totalSeconds"
                    sumExpression.expression = NSExpression(
                        forFunction: "sum:",
                        arguments: [NSExpression(forKeyPath: "numberOfSeconds")]
                    )
                    sumExpression.expressionResultType = .integer64AttributeType

                    request.resultType = .dictionaryResultType
                    request.propertiesToFetch = [sumExpression]

                    if let result = try backgroundContext.fetch(request).first,
                       let totalSeconds = result["totalSeconds"] as? Int64 {
                        continuation.resume(returning: Int(totalSeconds / Int64(60)))
                    } else {
                        continuation.resume(returning: 0)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchPageViewDates(startDate: Date, endDate: Date, moc: NSManagedObjectContext? = nil) async throws -> WMFPageViewDates? {
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
                    let cdPageViews = try store.fetch(entityType: CDPageView.self, predicate: predicate, fetchLimit: nil, in: backgroundContext)
                    
                    guard let cdPageViews = cdPageViews else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
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
                    
                    let days = countsDictionaryDay.sorted(by: { $0.key < $1.key }).map { dayOfWeek, count in
                        WMFPageViewDay(day: dayOfWeek, viewCount: count)
                    }
                    
                    let times: [WMFPageViewTime] = countsDictionaryTime.sorted(by: { $0.key < $1.key }).map { hour, count in
                        return WMFPageViewTime(hour: hour, viewCount: count)
                    }
                    
                    let months = countsDictionaryMonth.sorted(by: { $0.key < $1.key }).map { month, count in
                        WMFPageViewMonth(month: month, viewCount: count)
                    }
                    
                    continuation.resume(returning: WMFPageViewDates(days: days, times: times, months: months))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchLinkedPageViews() async throws -> [[WMFPageView]] {
        let store = coreDataStore
        let context = try store.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<CDPageView> = CDPageView.fetchRequest()
                    let allPageViews = try context.fetch(fetchRequest)

                    // Find roots: page views with no previousPageView
                    let roots = allPageViews.filter { $0.previousPageView == nil }

                    var result: [[CDPageView]] = []
                    var returnResult: [[WMFPageView]] = []

                    // Walk all possible branches
                    func walk(current: CDPageView, path: [CDPageView]) {
                        let newPath = path + [current]
                        
                        let nextViews = (current.nextPageViews as? Set<CDPageView>) ?? []
                        if nextViews.isEmpty {
                            // Leaf node — end of a navigation path
                            let sortedPath = newPath.sorted(by: { $0.timestamp ?? .distantPast < $1.timestamp ?? .distantPast })
                            result.append(sortedPath)
                            returnResult.append(sortedPath.compactMap {WMFPageView(cdPageView: $0)})
                            
                        } else {
                            for next in nextViews {
                                walk(current: next, path: newPath)
                            }
                        }
                    }

                    for root in roots {
                        walk(current: root, path: [])
                    }

                    continuation.resume(returning: returnResult)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchMostRecentTime() async throws -> Date? {
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext

        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageView")
                    fetchRequest.fetchLimit = 1
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                    
                    if let pageView = try backgroundContext.fetch(fetchRequest).first as? CDPageView {
                        continuation.resume(returning: pageView.timestamp)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchTimelinePages() async throws -> [WMFPageWithTimestamp] {
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
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

                        let wmfPage = WMFPage(
                            namespaceID: Int(page.namespaceID),
                            projectID: projectID,
                            title: title
                        )

                        result.append(WMFPageWithTimestamp(page: wmfPage, timestamp: timestamp))
                    }

                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
