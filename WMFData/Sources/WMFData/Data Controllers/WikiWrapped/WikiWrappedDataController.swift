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
