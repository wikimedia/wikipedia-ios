import Foundation
import CoreData

public struct WMFCategory: Hashable, Sendable {
    public let categoryName: String
    public let project: WMFProject
}

public actor WMFCategoriesDataController {
    
    private let coreDataStore: WMFCoreDataStore
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        self.coreDataStore = coreDataStore
    }
    
    public func addCategories(categories: [String], articleTitle: String, project: WMFProject) async throws {
        
        let coreDataTitle = articleTitle.normalizedForCoreData
        
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        try await backgroundContext.perform {
            // First fetch WMFPage of article
            
            let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.id, 0, coreDataTitle])
            
            guard let page = try store.fetch(entityType: CDPage.self, predicate: predicate, fetchLimit: 1, in: backgroundContext)?.first else {
                throw WMFCoreDataStoreError.missingEntity
            }
            
            // Fetch or create category
            for category in categories {
                let categoryTitle = category.normalizedForCoreData
                let predicate = NSPredicate(format: "projectID == %@ && title == %@", argumentArray: [project.id, categoryTitle])
                
                guard let category = try? store.fetchOrCreate(entityType: CDCategory.self, predicate: predicate, in: backgroundContext),
                      var pages = category.pages as? Set<CDPage> else {
                    continue
                }
                
                category.title = categoryTitle
                category.projectID = project.id
                
                pages.insert(page)
                category.pages = pages as NSSet
            }
            
            try store.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    func deleteEmptyCategories() async throws {
        
        let store = coreDataStore
        let backgroundContext = try store.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        try await backgroundContext.perform {
            // Delete CDCategorys that have empty pages
            let emptyPagesPredicate = NSPredicate(format: "pages.@count == 0")
            guard let categoriesToDelete = try store.fetch(entityType: CDCategory.self, predicate: emptyPagesPredicate, fetchLimit: nil, in: backgroundContext) else {
                return
            }
            
            for category in categoriesToDelete {
                backgroundContext.delete(category)
            }
            
            try store.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func fetchCategoryCounts(startDate: Date, endDate: Date) async throws -> [WMFCategory: Int] {
        
        let store = coreDataStore
        let context = try store.newBackgroundContext
        
        return try await context.perform {
            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
            
            var countsByCategory: [WMFCategory: Int] = [:]
            
            guard let pageViews = try store.fetch(entityType: CDPageView.self, predicate: predicate, fetchLimit: nil, in: context) else {
                return [:]
            }
            
            let uniquePages = Set(pageViews.compactMap { $0.page })
            
            for page in uniquePages {
                guard let categories = page.categories as? Set<CDCategory> else { continue }
                
                for category in categories {
                    
                    guard let title = category.title,
                          let projectID = category.projectID,
                          let project = WMFProject(id: projectID) else {
                        continue
                    }
                    
                    countsByCategory[WMFCategory(categoryName: title, project: project), default: 0] += 1
                }
            }
            
            return countsByCategory
        }
    }
}
