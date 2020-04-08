
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
            
            var isDownloaded = false
            if let fileName = fetcher.uniqueFileNameForItemKey(key, variant: newVariant),
                let headerFileName = fetcher.uniqueHeaderFileNameForItemKey(key, variant: newVariant) {
                
                let filePath = CacheFileWriterHelper.fileURL(for: fileName).path
                isDownloaded = FileManager.default.fileExists(atPath: filePath)
                
                //artifically create and save image response header
                //perform on another thread in case this takes a while
                DispatchQueue.global(qos: .background).async {
                    if let mimeType = FileManager.default.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: filePath),
                        let data = FileManager.default.contents(atPath: filePath) {
                            //construct response header file
                        let headerFields: [String: String] = [
                                "Content-Type": mimeType,
                                "Content-Length": String(data.count)
                            ]
                        CacheFileWriterHelper.saveResponseHeader(headerFields: headerFields, toNewFileName: headerFileName) { (result) in
                            //no-op
                        }
                    }
                }
            }
            
            destinationItem.setValue(isDownloaded, forKey: "isDownloaded")
            destinationItem.setValue(nil, forKey: "url")
            
            manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationItem, for: mapping)
        }
    }
}
