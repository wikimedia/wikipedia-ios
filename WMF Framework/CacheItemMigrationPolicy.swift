
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
            autoreleasepool { () -> Void in
                guard
                    let fileName = fetcher.uniqueFileNameForItemKey(key, variant: newVariant),
                    let headerFileName = fetcher.uniqueHeaderFileNameForItemKey(key, variant: newVariant) else {
                        return
                }
                let fileURL = CacheFileWriterHelper.fileURL(for: fileName)
                let filePath = fileURL.path
                //artifically create and save image response header
                var headers: [String: String] = [:]
                headers["Content-Type"] = FileManager.default.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: filePath)
                let values = try? fileURL.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
                if let fileSize = values?.fileSize {
                    headers["Content-Length"] = String(fileSize)
                }
                guard !headers.isEmpty else {
                    return
                }
                CacheFileWriterHelper.saveResponseHeader(headerFields: headers, toNewFileName: headerFileName) { (result) in
                    switch result {
                    case .success, .exists:
                        isDownloaded = true
                    case .failure:
                        break
                    }
                }
            }
            destinationItem.setValue(isDownloaded, forKey: "isDownloaded")
            destinationItem.setValue(nil, forKey: "url")
            manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationItem, for: mapping)
            
        }
    }
}
