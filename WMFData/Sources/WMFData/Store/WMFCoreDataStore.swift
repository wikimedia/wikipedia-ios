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
            self.persistentContainer?.loadPersistentStores(completionHandler: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    
                    DispatchQueue.main.async {
                        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                        
                        continuation.resume()
                    }
                }
            })
        }
        
    }
    
    var newBackgroundContext: NSManagedObjectContext {
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
    
    func fetchOrCreate<T: NSManagedObject>(entityType: T.Type, predicate: NSPredicate?, in moc: NSManagedObjectContext) throws -> T? {
        
        guard let existing: [T] = try fetch(entityType: entityType, predicate: predicate, fetchLimit: 1, in: moc),
              !existing.isEmpty else {
            return try create(entityType: entityType, in: moc)
        }

        return existing.first
    }
    
    private func fetchRequest<T>(entityType: T.Type, predicate: NSPredicate?, fetchLimit: Int?, in moc: NSManagedObjectContext) -> NSFetchRequest<T> {
        
        let entityName = NSStringFromClass(entityType)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        if let fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        return fetchRequest
    }
    
    func fetch<T: NSManagedObject>(entityType: T.Type, predicate: NSPredicate?, fetchLimit: Int?, in moc: NSManagedObjectContext) throws -> [T]? {
        
        let fetchRequest = fetchRequest(entityType: entityType, predicate: predicate, fetchLimit: fetchLimit, in: moc)
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
        
        guard let sevenDaysAgoDate = Calendar.current.date(byAdding: .day,
                                                 value: -7,
                                                       to: Date()) else {
            return
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        var dateComponents = DateComponents()
        dateComponents.year = currentYear - 1
        dateComponents.day = 1
        dateComponents.month = 1
        
        guard let oneYearAgoDate = Calendar.current.date(from: dateComponents) else {
            return
        }
        
        let backgroundContext = try newBackgroundContext
        try await backgroundContext.perform {
            
            // Delete WMFPageViews that were added > one year ago
            let predicate = NSPredicate(format: "timestamp < %@", argumentArray: [oneYearAgoDate])
            let pageViewFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPageView")
            pageViewFetchRequest.predicate = predicate
            
            let batchPageViewDeleteRequest = NSBatchDeleteRequest(fetchRequest: pageViewFetchRequest)
            batchPageViewDeleteRequest.resultType = .resultTypeObjectIDs
            _ = try backgroundContext.execute(batchPageViewDeleteRequest) as? NSBatchDeleteResult
            
            // Delete WMFPages that were added > one year ago
            let pageFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPage")
            pageFetchRequest.predicate = predicate
            
            let batchPageDeleteRequest = NSBatchDeleteRequest(fetchRequest: pageFetchRequest)
            batchPageDeleteRequest.resultType = .resultTypeObjectIDs
            _ = try backgroundContext.execute(batchPageDeleteRequest) as? NSBatchDeleteResult
        }
    }
}

extension WMFProject {
    var coreDataIdentifier: String {
        switch self {
        case .commons:
            return "commons"
        case .wikidata:
            return "wikidata"
        case .wikipedia(let language):
            var identifier = "wikipedia~\(language.languageCode)"
            if let variantCode = language.languageVariantCode {
                identifier.append("~\(variantCode)")
            }
            return identifier
        }
    }
}

extension String {
    var normalizedForCoreData: String {
        return self.spacesToUnderscores.precomposedStringWithCanonicalMapping
    }
}
