import Foundation
import CoreData

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
        
        try await backgroundContext.perform {
            
            let predicate = NSPredicate(format: "title == %@ && namespaceID == %@ && projectID == %@", argumentArray: [title, namespaceID, project.coreDataIdentifier])
            let page = try self.coreDataStore.fetchOrCreate(entity: CDPage.self, predicate: predicate, in: backgroundContext)
            
            let viewedPage = try self.coreDataStore.create(entity: CDPageView.self, in: backgroundContext)
            viewedPage.page = page
            viewedPage.timestamp = Date()
            try backgroundContext.save()
        }
    }
}
