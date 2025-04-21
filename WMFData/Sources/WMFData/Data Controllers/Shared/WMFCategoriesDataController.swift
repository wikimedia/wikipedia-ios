import Foundation

public final class WMFCategoriesDataController {
    
    private let coreDataStore: WMFCoreDataStore
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        self.coreDataStore = coreDataStore
    }
    
    public func addCategories(categories: [String], articleTitle: String, project: WMFProject) async throws {
        
        let coreDataTitle = articleTitle.normalizedForCoreData
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { return }
            
            // First fetch WMFPage of article
            
            let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.coreDataIdentifier, 0, coreDataTitle])
            
            guard let page = try self.coreDataStore.fetch(entityType: CDPage.self, predicate: predicate, fetchLimit: 1, in: backgroundContext)?.first else {
                throw WMFCoreDataStoreError.missingEntity
            }
            
            // Fetch or create category
            for category in categories {
                let categoryTitle = category.normalizedForCoreData
                let predicate = NSPredicate(format: "projectID == %@ && title == %@", argumentArray: [project.coreDataIdentifier, categoryTitle])
                
                guard let category = try? self.coreDataStore.fetchOrCreate(entityType: CDCategory.self, predicate: predicate, in: backgroundContext),
                      var pages = category.pages as? Set<CDPage> else {
                    continue
                }
                
                category.title = categoryTitle
                category.projectID = project.coreDataIdentifier
                
                pages.insert(page)
                category.pages = pages as NSSet
            }
            
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
}
