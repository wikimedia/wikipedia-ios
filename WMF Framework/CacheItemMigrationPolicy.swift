
import Foundation

enum CacheItemMigrationPolicyError: Error {
    case unrecognizedSourceAttributeTypes
}

class CacheItemMigrationPolicy: NSEntityMigrationPolicy {
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        
        if sInstance.entity.name == "CacheItem" {
            
            guard let key = sInstance.primitiveValue(forKey: "key") as? String,
                let variant = sInstance.primitiveValue(forKey: "variant") as? Int64,
                let date = sInstance.primitiveValue(forKey: "date") as? Date else {
                    throw CacheItemMigrationPolicyError.unrecognizedSourceAttributeTypes
            }
            
            let destinationItem = NSEntityDescription.insertNewObject(forEntityName: "CacheItem", into: manager.destinationContext)
            
            destinationItem.setValue(key, forKey: "key")
            
            let newVariant: String? = variant < 1 ? nil : String(variant)
            destinationItem.setValue(newVariant, forKey: "variant")
            destinationItem.setValue(date, forKey: "date")
            
            //should we confirm file actually exists in file system before setting this to true?
            
            //only images will be migrating
            let cacheKeyGenerator = ImageCacheKeyGenerator.self
            let fileName = cacheKeyGenerator.uniqueFileNameForItemKey(key, variant: newVariant)
            let filePath = CacheFileWriterHelper.fileURL(for: fileName).path
            let headerFileName = cacheKeyGenerator.uniqueHeaderFileNameForItemKey(key, variant: newVariant)
            
            //artifically create and save image response header
            if let mimeType = FileManager.default.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: filePath),
                let data = FileManager.default.contents(atPath: filePath) {
                    //construct response header file
                let headerFields: [String: String] = [
                        "Content-Type": mimeType,
                        "Content-Length": String(data.count)
                    ]
                CacheFileWriterHelper.saveResponseHeader(headerFields: headerFields, toNewFileName: headerFileName) { (result) in
                    switch result {
                    case .success, .exists:
                        destinationItem.setValue(true, forKey: "isDownloaded")
                    case .failure:
                        destinationItem.setValue(false, forKey: "isDownloaded")
                    }
                }
                
            } else {
                destinationItem.setValue(false, forKey: "isDownloaded")
            }
            
            destinationItem.setValue(nil, forKey: "url")
            
            manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationItem, for: mapping)
            
        }
    }
}
