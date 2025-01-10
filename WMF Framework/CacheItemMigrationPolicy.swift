import Foundation

enum CacheItemMigrationPolicyError: Error {
    case unrecognizedSourceAttributeTypes
}

class CacheItemMigrationPolicy: NSEntityMigrationPolicy {
    
    private let fetcher = ImageFetcher()
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        
        if sInstance.entity.name == "CacheItem" {
            
            guard let key = sInstance.primitiveValue(forKey: "key") as? String,
                let variant = sInstance.primitiveValue(forKey: "variant") as? Int64,
                let date = sInstance.primitiveValue(forKey: "date") as? Date else {
                    throw CacheItemMigrationPolicyError.unrecognizedSourceAttributeTypes
            }
            
            let destinationItem = NSEntityDescription.insertNewObject(forEntityName: "CacheItem", into: manager.destinationContext)
            
            destinationItem.setValue(key, forKey: "key")
            
            let newVariant = String(variant)
            destinationItem.setValue(newVariant, forKey: "variant")
            destinationItem.setValue(date, forKey: "date")
            let isDownloaded = false
            
            destinationItem.setValue(isDownloaded, forKey: "isDownloaded")
            destinationItem.setValue(nil, forKey: "url")
            manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationItem, for: mapping)
            
        }
    }
}
