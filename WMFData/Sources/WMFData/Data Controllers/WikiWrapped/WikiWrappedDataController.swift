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
    
    public func createAndSaveViewedPage(pageTitle: String, namespaceID: Int16, project: WMFProject) async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform {
            let viewedPage = try self.coreDataStore.create(entity: WMFViewedPage.self, in: backgroundContext)
            
            guard let viewedPage else {
                return
            }
            
            viewedPage.pageTitle = pageTitle
            viewedPage.namespaceID = namespaceID
            viewedPage.wmfProjectID = project.coreDataIdentifier
            viewedPage.date = Date()
            try backgroundContext.save()
        }
    }
}
