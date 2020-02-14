
import Foundation

protocol CacheKeyGenerating: class {
    static func itemKeyForURL(_ url: URL) -> String?
    static func variantForURL(_ url: URL) -> String?
    static func uniqueFileNameForURL(_ url: URL) -> String?
    static func uniqueHeaderFileNameForURL(_ url: URL) -> String?
    static func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String
    static func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String
}

extension CacheKeyGenerating {
    static func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String {
        
        guard let variant = variant else {
            return itemKey.precomposedStringWithCanonicalMapping
        }
        
        let fileName = "\(itemKey)__\(variant)".precomposedStringWithCanonicalMapping
        return CacheFileWriterHelper.fileName(for: fileName)
    }
    
    static func uniqueHeaderFileNameForURL(_ url: URL) -> String? {
        
        guard let fileName = uniqueFileNameForURL(url) else {
            return nil
        }
        
        return fileName + "__Header"
    }
    
    static func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String {
        
        let fileName = uniqueFileNameForItemKey(itemKey, variant: variant)
        
        return fileName + "__Header"
    }
}
