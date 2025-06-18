import Foundation
import CoreData

public final class WMFCategoriesDataController {
    
    public struct WMFCategoryCount {
        public let categoryName: String
        public let project: WMFProject
        public let count: Int
    }
    
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
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
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
    
    func deleteEmptyCategories() async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { return }
            
            // Delete CDCategorys that have empty pages
            let emptyPagesPredicate = NSPredicate(format: "pages.@count == 0")
            guard let categoriesToDelete = try coreDataStore.fetch(entityType: CDCategory.self, predicate: emptyPagesPredicate, fetchLimit: nil, in: backgroundContext) else {
                return
            }
            
            for category in categoriesToDelete {
                backgroundContext.delete(category)
            }
            
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func fetchCategoryCounts() async throws -> [WMFCategoryCount] {
        
        let context = try coreDataStore.viewContext
        
        let counts: [WMFCategoryCount] = try await context.perform { [weak self] in
            
            guard let self else { return [] }
            
            var counts: [WMFCategoryCount] = []
            
            guard let categories = try coreDataStore.fetch(entityType: CDCategory.self, predicate: nil, fetchLimit: nil, in: context) else {
                return counts
            }
            
            for category in categories {
                guard let title = category.title,
                      let projectID = category.projectID,
                      let project = WMFProject(coreDataIdentifier: projectID),
                      let pages = category.pages else {
                    continue
                }
                counts.append(WMFCategoryCount(categoryName: title, project: project, count: pages.count))
            }
            
            return counts
        }
        
        return counts
    }
}
