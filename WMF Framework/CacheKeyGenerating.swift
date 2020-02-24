
import Foundation

public protocol CacheKeyGenerating: class {
    static func itemKeyForURL(_ url: URL) -> String?
    static func variantForURL(_ url: URL) -> String?
    static func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String
    static func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String
}

extension CacheKeyGenerating {
    static func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String {
        
        guard let variant = variant else {
            let fileName = itemKey.precomposedStringWithCanonicalMapping
            return fileName.sha256 ?? fileName
        }
        
        let fileName = "\(itemKey)__\(variant)".precomposedStringWithCanonicalMapping
        return fileName.sha256 ?? fileName
    }
    
    static func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String {
        
        let fileName = uniqueFileNameForItemKey(itemKey, variant: variant)
        
        return fileName + "__Header"
    }
}
