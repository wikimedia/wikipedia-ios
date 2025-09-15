import Foundation
import CoreData

 public final class WMFPage {
   public let namespaceID: Int
   public let projectID: String
   public let title: String

     init(namespaceID: Int, projectID: String, title: String) {
       self.namespaceID = namespaceID
       self.projectID = projectID
       self.title = title
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

public final class WMFLegacyPageView: Codable {
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

public final class WMFPageViewsDataController {
    
    private let coreDataStore: WMFCoreDataStore
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        self.coreDataStore = coreDataStore
    }
    
    public func addPageView(title: String, namespaceID: Int16, project: WMFProject, previousPageViewObjectID: NSManagedObjectID?) async throws -> NSManagedObjectID? {
        
        let coreDataTitle = title.normalizedForCoreData
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let managedObjectID: NSManagedObjectID? = try await backgroundContext.perform { [weak self] () -> NSManagedObjectID? in
            
            guard let self else { return nil }
            
            let currentDate = Date()
            let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.coreDataIdentifier, namespaceID, coreDataTitle])
            let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
            page?.title = coreDataTitle
            page?.namespaceID = namespaceID
            page?.projectID = project.coreDataIdentifier
            page?.timestamp = currentDate
            
            let viewedPage = try self.coreDataStore.create(entityType: CDPageView.self, in: backgroundContext)
            viewedPage.page = page
            viewedPage.timestamp = currentDate
            
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
            
            guard let pageView = backgroundContext.object(with: pageViewManagedObjectID) as? CDPageView else {
                return
            }
            
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
            
            let pagePredicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.coreDataIdentifier, namespaceID, coreDataTitle])
            guard let page = try self.coreDataStore.fetch(entityType: CDPage.self, predicate: pagePredicate, fetchLimit: 1, in: backgroundContext)?.first else {
                return
            }
            
            let pageViewsPredicate = NSPredicate(format: "page == %@", argumentArray: [page])
            
            guard let pageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, predicate: pageViewsPredicate, fetchLimit: nil, in: backgroundContext) else {
                return
            }
            
            for pageView in pageViews {
                backgroundContext.delete(pageView)
            }
            
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
                let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [request.project.coreDataIdentifier, 0, coreDataTitle])
                
                let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
                page?.title = coreDataTitle
                page?.namespaceID = 0
                page?.projectID = request.project.coreDataIdentifier
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
            sumExpression.expression = NSExpression(
                forFunction: "sum:",
                arguments: [NSExpression(forKeyPath: "numberOfSeconds")]
            )
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
            
            guard let cdPageViews = cdPageViews else {
                return nil
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
            
            return WMFPageViewDates(days: days, times: times, months: months)
        }
        
        return results
    }
    
    public func fetchLinkedPageViews() async throws -> [[CDPageView]] {
        let context = try coreDataStore.viewContext
        
        let result: [[CDPageView]] = try await context.perform {
            let fetchRequest: NSFetchRequest<CDPageView> = CDPageView.fetchRequest()
            let allPageViews = try context.fetch(fetchRequest)

            // Find roots: page views with no previousPageView
            let roots = allPageViews.filter { $0.previousPageView == nil }

            var result: [[CDPageView]] = []

            // Walk all possible branches
            func walk(current: CDPageView, path: [CDPageView]) {
                let newPath = path + [current]
                
                let nextViews = (current.nextPageViews as? Set<CDPageView>) ?? []
                if nextViews.isEmpty {
                    // Leaf node — end of a navigation path
                    let sortedPath = newPath.sorted(by: { $0.timestamp ?? .distantPast < $1.timestamp ?? .distantPast })
                    result.append(sortedPath)
                } else {
                    for next in nextViews {
                        walk(current: next, path: newPath)
                    }
                }
            }

            for root in roots {
                walk(current: root, path: [])
            }

            return result
        }
        
        return result
    }
}
