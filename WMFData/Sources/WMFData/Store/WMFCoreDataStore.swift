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
        
        let container = NSPersistentContainer(name: dataModelName, managedObjectModel: dataModel)
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error {
                debugPrint("Error loading persistent stores: \(error)")
            } else {
                DispatchQueue.main.async {
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
    
    var viewContext: NSManagedObjectContext {
        get throws {
            guard let persistentContainer else {
                throw WMFCoreDataStoreError.setupMissingPersistentContainer
            }
            
            return persistentContainer.viewContext
        }
    }
    
    func create<T: NSManagedObject>(entity: T.Type, in moc: NSManagedObjectContext) throws -> T? {

        let entityName = String(describing: entity)
        
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
}

extension WMFProject {
    var coreDataIdentifier: String {
        switch self {
        case .commons:
            return "commons"
        case .wikidata:
            return "wikidata"
        case .wikipedia(let language):
            var identifier = "wikipedia-\(language.languageCode)"
            if let variantCode = language.languageVariantCode {
                identifier.append("-\(variantCode)")
            }
            return identifier
        }
    }
}
