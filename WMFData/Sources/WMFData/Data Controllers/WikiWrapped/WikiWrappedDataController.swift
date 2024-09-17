import Foundation
import CoreData

 public final class WMFPage {
   public let namespaceID: Int
   public let projectID: String
   public let title: String
   let pageViews: [WMFPageView]

     init(namespaceID: Int, projectID: String, title: String, pageViews: [WMFPageView] = []) {
       self.namespaceID = namespaceID
       self.projectID = projectID
       self.title = title
       self.pageViews = pageViews
   }
 }

public final class WMFPageView {
   public let timestamp: Date
   public let page: WMFPage

   init(timestamp: Date, page: WMFPage) {
       self.timestamp = timestamp
       self.page = page
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

public final class WMFPageViewImportRequest {
    let title: String
    let project: WMFProject
    let viewedDate: Date
    var pageObjectID: NSManagedObjectID?
    
    public init(title: String, project: WMFProject, viewedDate: Date) {
        self.title = title
        self.project = project
        self.viewedDate = viewedDate
    }
    
}

public final class WMFWikiWrappedDataController {
    
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
            let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, entityName: "WMFPage", predicate: predicate, in: backgroundContext)
            page?.title = coreDataTitle
            page?.namespaceID = namespaceID
            page?.projectID = project.coreDataIdentifier
            page?.timestamp = currentDate
            
            let viewedPage = try self.coreDataStore.create(entityType: CDPageView.self, entityName: "WMFPageView", in: backgroundContext)
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
            guard let page = try self.coreDataStore.fetch(entityType: CDPage.self, entityName: "WMFPage", predicate: pagePredicate, fetchLimit: 1, in: backgroundContext)?.first else {
                return
            }
            
            let pageViewsPredicate = NSPredicate(format: "page == %@", argumentArray: [page])
            
            guard let pageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, entityName: "WMFPageView", predicate: pageViewsPredicate, fetchLimit: nil, in: backgroundContext) else {
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
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { return }
            
            guard let pageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, entityName: "WMFPageView", predicate: nil, fetchLimit: nil, in: backgroundContext) else {
                return
            }
            
            for pageView in pageViews {
                backgroundContext.delete(pageView)
            }
            
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func importPageViews(requests: [WMFPageViewImportRequest]) async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        try await backgroundContext.perform {
            
            let batchInsertPage = self.newBatchInsertPageRequest(requests: requests)
            try backgroundContext.execute(batchInsertPage)
        }
        
        backgroundContext.refreshAllObjects()
        
        try await backgroundContext.perform {
            let batchInsertPageView = self.newBatchInsertPageViewRequest(moc: backgroundContext, requests: requests)
            try backgroundContext.execute(batchInsertPageView)
        }
    }
    
    private func newBatchInsertPageRequest(requests: [WMFPageViewImportRequest])
      -> NSBatchInsertRequest {
      // 1
      var index = 0
      let total = requests.count

      // 2
      let batchInsert = NSBatchInsertRequest(
        entity: CDPage.entity()) { (managedObject: NSManagedObject) -> Bool in
        // 3
        guard index < total else { return true }

            if let page = managedObject as? CDPage {
            // 4
            let request = requests[index]
            let coreDataTitle = request.title.normalizedForCoreData

            page.title = coreDataTitle
            page.namespaceID = 0
            page.projectID = request.project.coreDataIdentifier
            page.timestamp = request.viewedDate
            page.pageViews = []
            request.pageObjectID = page.objectID
        }

        // 5
        index += 1
        return false
      }
      return batchInsert
    }
    
    private func newBatchInsertPageViewRequest(moc: NSManagedObjectContext, requests: [WMFPageViewImportRequest])
      -> NSBatchInsertRequest {
      // 1
      var index = 0
      let total = requests.count

      // 2
      let batchInsert = NSBatchInsertRequest(
        entity: CDPageView.entity()) { (managedObject: NSManagedObject) -> Bool in
            // 3
            guard index < total else { return true }
            
            let request = requests[index]

            guard let pageView = managedObject as? CDPageView,
                  let pageObjectID = request.pageObjectID,
                  let page = managedObject.managedObjectContext?.object(with: pageObjectID) as? CDPage else {
                index += 1
                return false
            }
            // 4
                
            pageView.page = page
            pageView.timestamp = request.viewedDate

            // 5
            index += 1
            return false
          }
          return batchInsert
    }
    
    public func fetchPageViewCounts() throws -> [WMFPageViewCount] {
        
        let viewContext = try coreDataStore.viewContext
        let results: [WMFPageViewCount] = try viewContext.performAndWait {
            let pageViewsDict = try self.coreDataStore.fetchGrouped(entityName: "WMFPageView", predicate: nil, propertyToCount: "page", propertiesToGroupBy: ["page"], propertiesToFetch: ["page"], in: viewContext)
            var pageViewCounts: [WMFPageViewCount] = []
            for dict in pageViewsDict {
                
                guard let objectID = dict["page"] as? NSManagedObjectID,
                      let count = dict["count"] as? Int else {
                    continue
                }
                
                guard let page = viewContext.object(with: objectID) as? CDPage,
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
}
