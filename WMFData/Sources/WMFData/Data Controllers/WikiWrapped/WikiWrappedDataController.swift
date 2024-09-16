import Foundation
import CoreData

 public final class WMFPage {
   let namespaceID: Int
   let projectID: String
   public let title: String
   let pageViews: [WMFPageView]

     init(namespaceID: Int, projectID: String, title: String, pageViews: [WMFPageView] = []) {
       self.namespaceID = namespaceID
       self.projectID = projectID
       self.title = title
       self.pageViews = pageViews
   }
 }

public final class WMFPageView: Identifiable {
    public var id: Date {
        return timestamp
    }
   public let timestamp: Date
   public let page: WMFPage

   init(timestamp: Date, page: WMFPage) {
       self.timestamp = timestamp
       self.page = page
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
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { return }
            
            let predicate = NSPredicate(format: "title == %@ && namespaceID == %@ && projectID == %@", argumentArray: [title, namespaceID, project.coreDataIdentifier])
            let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, entityName: "WMFPage", predicate: predicate, in: backgroundContext)
            page?.title = title
            page?.namespaceID = namespaceID
            page?.projectID = project.coreDataIdentifier
            
            let viewedPage = try self.coreDataStore.create(entityType: CDPageView.self, entityName: "WMFPageView", in: backgroundContext)
            viewedPage.page = page
            viewedPage.timestamp = Date()

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
        
        try coreDataStore.pruneTransactionHistory()
    }
    
    public func fetchPageViews() throws -> [WMFPageView] {
        
        let viewContext = try coreDataStore.viewContext
        let results: [WMFPageView] = try viewContext.performAndWait {
            guard let cdPageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, entityName: "WMFPageView", predicate: nil, fetchLimit: nil, in: viewContext) else {
                return []
            }
            
            var pageViews: [WMFPageView] = []
            
            for cdPageView in cdPageViews {
                guard let timestamp = cdPageView.timestamp,
                      let cdPage = cdPageView.page else {
                    continue
                }
                
                guard let projectID = cdPage.projectID,
                      let title = cdPage.title else {
                    continue
                }
                
                let page = WMFPage(namespaceID: Int(cdPage.namespaceID), projectID: projectID, title: title, pageViews: [])
                        
                pageViews.append(WMFPageView(timestamp: timestamp, page: page))
            }
            
            return pageViews
        }
        
        return results
    }
    
    public func deletePageView(pageView: WMFPageView) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { return }
            
            let predicate = NSPredicate(format: "timestamp == %@", argumentArray: [pageView.timestamp])
            
            guard let page = try self.coreDataStore.fetch(entityType: CDPageView.self, entityName: "WMFPageView", predicate: predicate, fetchLimit: 1, in: backgroundContext)?.first else {
                return
            }
            
            backgroundContext.delete(page)
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
}
