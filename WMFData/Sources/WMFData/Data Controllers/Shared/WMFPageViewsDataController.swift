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

public final class WMFPageViewDay: Decodable, Encodable {
    public let day: Int
    public let viewCount: Int
    
    public init(day: Int, viewCount: Int) {
        self.day = day
        self.viewCount = viewCount
    }

    public func getViewCount() -> Int {
        viewCount
    }
    
    public func getDay() -> Int {
        day
    }
}

public final class WMFPageViewImportRequest {
    let title: String
    let project: WMFProject
    let viewedDate: Date
    
    public init(title: String, project: WMFProject, viewedDate: Date) {
        self.title = title
        self.project = project
        self.viewedDate = viewedDate
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
    
    public func addPageView(title: String, namespaceID: Int16, project: WMFProject) async throws {
        
        let coreDataTitle = title.normalizedForCoreData
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { return }
            
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
            
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func deletePageView(title: String, namespaceID: Int16, project: WMFProject) async throws {
        
        let coreDataTitle = title.normalizedForCoreData
        
        let backgroundContext = try coreDataStore.newBackgroundContext
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
    }
    
    public func deleteAllPageViews() async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext
        try await backgroundContext.perform {
            let pageViewFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageView")
            
            let batchPageViewDeleteRequest = NSBatchDeleteRequest(fetchRequest: pageViewFetchRequest)
            batchPageViewDeleteRequest.resultType = .resultTypeObjectIDs
            _ = try backgroundContext.execute(batchPageViewDeleteRequest) as? NSBatchDeleteResult
            
            backgroundContext.refreshAllObjects()
        }
    }
    
    public func importPageViews(requests: [WMFPageViewImportRequest]) async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
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
    
    public func fetchPageViewCounts(startDate: Date, endDate: Date, moc: NSManagedObjectContext? = nil) throws -> [WMFPageViewCount] {
        
        let context: NSManagedObjectContext
        if let moc {
            context = moc
        } else {
            context = try coreDataStore.viewContext
        }
        let results: [WMFPageViewCount] = try context.performAndWait {
            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
            let pageViewsDict = try self.coreDataStore.fetchGrouped(entityType: CDPageView.self, predicate: predicate, propertyToCount: "page", propertiesToGroupBy: ["page"], propertiesToFetch: ["page"], in: context)
            var pageViewCounts: [WMFPageViewCount] = []
            for dict in pageViewsDict {
                
                guard let objectID = dict["page"] as? NSManagedObjectID,
                      let count = dict["count"] as? Int else {
                    continue
                }
                
                guard let page = context.object(with: objectID) as? CDPage,
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
    
    public func fetchPageViewDates(startDate: Date, endDate: Date, moc: NSManagedObjectContext? = nil) throws -> [WMFPageViewDay] {
        let context: NSManagedObjectContext
        if let moc {
            context = moc
        } else {
            context = try coreDataStore.viewContext
        }
        
        let results: [WMFPageViewDay] = try context.performAndWait {
            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
            let cdPageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, predicate: predicate, fetchLimit: nil, in: context)
            
            guard let cdPageViews = cdPageViews else {
                return []
            }
            
            var countsDictionary: [Int: Int] = [:]
            
            for cdPageView in cdPageViews {
                if let timestamp = cdPageView.timestamp {
                    let calendar = Calendar.current
                    let dayOfWeek = calendar.component(.weekday, from: timestamp) // Sunday = 1, Monday = 2, ..., Saturday = 7
                    
                    countsDictionary[dayOfWeek, default: 0] += 1
                }
            }
            
            return countsDictionary.sorted(by: { $0.key < $1.key }).map { dayOfWeek, count in
                WMFPageViewDay(day: dayOfWeek, viewCount: count)
            }
        }
        
        return results
    }


}
