import Foundation
import CoreData

public final class WMFCoreDataStore {
    
    private let appContainerURL: URL
    
    // Will only be populated if persistent stores load correctly
    private var persistentContainer: NSPersistentContainer?
    
    public init(appContainerURL: URL? = WMFDataEnvironment.current.appContainerURL) throws {
        
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
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        let container = NSPersistentContainer(name: dataModelName, managedObjectModel: dataModel)
        container.persistentStoreDescriptions = [description]
        
        for description in container.persistentStoreDescriptions {
            for (key, value) in description.options {
                print("\(key): \(value)")
            }
        }
        container.loadPersistentStores { _, error in
            if let error {
                debugPrint("Error loading persistent stores: \(error)")
            } else {
                DispatchQueue.main.async {
                    container.viewContext.automaticallyMergesChangesFromParent = true
                    container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                    
                    self.persistentContainer = container
                }
            }
        }
        
        self.persistentContainer = container
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
    
    func fetchOrCreate<T: NSManagedObject>(entityType: T.Type, entityName: String, predicate: NSPredicate, in moc: NSManagedObjectContext) throws -> T? {
        
        guard let existing: [T] = try fetch(entityType: entityType, entityName: entityName, predicate: predicate, fetchLimit: 1, in: moc),
              !existing.isEmpty else {
            return try create(entityType: entityType, entityName: entityName, in: moc)
        }

        return existing.first
    }
    
    func fetch<T: NSManagedObject>(entityType: T.Type, entityName: String, predicate: NSPredicate?, fetchLimit: Int?, in moc: NSManagedObjectContext) throws -> [T]? {
        
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        if let fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        return try moc.fetch(fetchRequest)
    }
    
    func create<T: NSManagedObject>(entityType: T.Type, entityName: String, in moc: NSManagedObjectContext) throws -> T {
        
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
    
    func pruneTransactionHistory() throws {
        
        guard let sevenDaysAgo = Calendar.current.date(byAdding: .day,
                                                 value: -7,
                                                       to: Date()) else {
            return
        }
        
        let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)
        let backgroundContext = try newBackgroundContext
        try backgroundContext.execute(deleteHistoryRequest)
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
