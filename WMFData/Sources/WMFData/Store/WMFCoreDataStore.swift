import Foundation
import CoreData

public final class WMFCoreDataStore {
    
    private let appContainerURL: URL
    
    // Will only be populated if persistent stores load correctly
    private var persistentContainer: NSPersistentContainer?

    public init(appContainerURL: URL? = WMFDataEnvironment.current.appContainerURL) async throws {
        
        guard let appContainerURL else {
            throw WMFCoreDataStoreError.setupMissingAppContainerURL
        }
        
        self.appContainerURL = appContainerURL
        
        let dataModelName = "WMFData"
        let databaseFileName = "WMFData.sqlite"
        var databaseFileURL = appContainerURL
        databaseFileURL.appendPathComponent(databaseFileName, isDirectory: false)
        
        guard let dataModelFileURL = Bundle.module.url(forResource: dataModelName, withExtension: "momd") else {
            throw WMFCoreDataStoreError.setupMissingDataModelFileURL
        }
        
        guard let dataModel = NSManagedObjectModel(contentsOf: dataModelFileURL) else {
            throw WMFCoreDataStoreError.setupMissingDataModel
        }
        
        let description = NSPersistentStoreDescription(url: databaseFileURL)
        description.shouldAddStoreAsynchronously = true
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        let container = NSPersistentContainer(name: dataModelName, managedObjectModel: dataModel)
        container.persistentStoreDescriptions = [description]
        
        self.persistentContainer = container
        
        try await loadPersistentStores()
    }
    
    private func loadPersistentStores() async throws {
        guard let persistentContainer else {
            throw WMFCoreDataStoreError.setupMissingPersistentContainer
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.loadPersistentStores(completionHandler: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    // Access viewContext on background thread to trigger lazy init
                    let context = persistentContainer.viewContext
                    context.automaticallyMergesChangesFromParent = true
                    context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                    
                    continuation.resume()
                }
            })
        }
    }
    
    public var newBackgroundContext: NSManagedObjectContext {
        get throws {
            guard let persistentContainer else {
                throw WMFCoreDataStoreError.setupMissingPersistentContainer
            }
            
            return persistentContainer.newBackgroundContext()
        }
    }
    
    public var viewContext: NSManagedObjectContext {
        get throws {
            guard let persistentContainer else {
                throw WMFCoreDataStoreError.setupMissingPersistentContainer
            }
            
            return persistentContainer.viewContext
        }
    }
    
    public func fetchOrCreate<T: NSManagedObject>(entityType: T.Type, predicate: NSPredicate?, in moc: NSManagedObjectContext) throws -> T? {

        guard let existing: [T] = try fetch(entityType: entityType, predicate: predicate, fetchLimit: 1, in: moc),
              !existing.isEmpty else {
            return try create(entityType: entityType, in: moc)
        }

        return existing.first
    }

    private func fetchRequest<T>(entityType: T.Type, predicate: NSPredicate?, fetchLimit: Int?, sortDescriptors: [NSSortDescriptor]? = nil, in moc: NSManagedObjectContext) -> NSFetchRequest<T> {

        let entityName = NSStringFromClass(entityType)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        if let fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        if let sortDescriptors {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        return fetchRequest
    }

    public func fetch<T: NSManagedObject>(entityType: T.Type, predicate: NSPredicate?, fetchLimit: Int?, sortDescriptors: [NSSortDescriptor]? = nil, in moc: NSManagedObjectContext) throws -> [T]? {

        let fetchRequest = fetchRequest(entityType: entityType, predicate: predicate, fetchLimit: fetchLimit, sortDescriptors: sortDescriptors, in: moc)
        return try moc.fetch(fetchRequest)
    }
    
    func fetchGrouped<T: NSManagedObject>(entityType: T.Type, predicate: NSPredicate?, propertyToCount: String, propertiesToGroupBy: [String], propertiesToFetch: [String], in moc: NSManagedObjectContext) throws -> [[String: Any]] {
        
        let keypathExp = NSExpression(forKeyPath: propertyToCount)
        let expression = NSExpression(forFunction: "count:", arguments: [keypathExp])

        let countDesc = NSExpressionDescription()
        countDesc.expression = expression
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        
        let entityName = NSStringFromClass(entityType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.propertiesToGroupBy = propertiesToGroupBy
        fetchRequest.propertiesToFetch = propertiesToFetch + [countDesc]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        guard let result = try moc.fetch(fetchRequest) as? [[String: Any]] else {
            throw WMFCoreDataStoreError.unexpectedFetchGroupResult
        }
        return result
    }
    
    func create<T: NSManagedObject>(entityType: T.Type, in moc: NSManagedObjectContext) throws -> T {
        
        let entityName = NSStringFromClass(entityType)
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc) else {
            throw WMFCoreDataStoreError.missingEntity
        }
        
        let item = T(entity: entity, insertInto: moc)
        return item
    }
    
    func saveIfNeeded(moc: NSManagedObjectContext) throws {
        if moc.hasChanges {
            try moc.save()
        }
    }
    
    public func performDatabaseHousekeeping() async throws {
        
        let currentYear = Calendar.current.component(.year, from: Date())
        var dateComponents = DateComponents()
        dateComponents.year = currentYear - 1
        dateComponents.day = 1
        dateComponents.month = 1
        
        guard let oneYearAgoDate = Calendar.current.date(from: dateComponents) else {
            return
        }
        
        let backgroundContext = try newBackgroundContext
        try await backgroundContext.perform { [weak self] in
            
            try autoreleasepool {
                
                guard let self else { return }
                
                // Delete CDPageViews that were added > one year ago
                let timestamp = NSPredicate(format: "timestamp < %@", argumentArray: [oneYearAgoDate])
                
                guard let pageViewsToDelete = try self.fetch(entityType: CDPageView.self, predicate: timestamp, fetchLimit: 2000, in: backgroundContext) else {
                    return
                }
                
                for pageView in pageViewsToDelete {
                    backgroundContext.delete(pageView)
                }
                
                let emptyPageViewsPredicate = NSPredicate(format: "pageViews.@count == 0")
                let emptyArticleTabItemsPredicate = NSPredicate(format: "articleTabItems.@count == 0")
                let savedPageInfoPredicate = NSPredicate(format: "savedInfo == nil")

                let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timestamp, emptyPageViewsPredicate, emptyArticleTabItemsPredicate, savedPageInfoPredicate])

                // Delete CDPages that have no page views, no article tab items, and were added > one year ago
                guard let pagesToDelete = try self.fetch(entityType: CDPage.self, predicate: compoundPredicate, fetchLimit: 2000, in: backgroundContext) else {
                    return
                }
                
                for page in pagesToDelete {
                    backgroundContext.delete(page)
                }
                
                // Delete CDCategorys that have empty pages
                let emptyPagesPredicate = NSPredicate(format: "pages.@count == 0")
                guard let categoriesToDelete = try self.fetch(entityType: CDCategory.self, predicate: emptyPagesPredicate, fetchLimit: nil, in: backgroundContext) else {
                    return
                }
                
                for category in categoriesToDelete {
                    backgroundContext.delete(category)
                }
                
                try self.saveIfNeeded(moc: backgroundContext)
            }
        }
    }
}

extension String {
    public var normalizedForCoreData: String {
        return self.spacesToUnderscores.precomposedStringWithCanonicalMapping
    }
}
