
import Foundation

class ImageCacheKeyGenerator: CacheKeyGenerating {
    static func itemKeyForURL(_ url: URL) -> String? {
        guard let host = url.host, let imageName = WMFParseImageNameFromSourceURL(url) else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
        return (host + "__" + imageName).precomposedStringWithCanonicalMapping
    }

    static func variantForURL(_ url: URL) -> String? {
        let sizePrefix = WMFParseSizePrefixFromSourceURL(url)
        return sizePrefix == NSNotFound ? nil : String(sizePrefix)
    }

    static func uniqueFileNameForURL(_ url: URL) -> String? {
        
        guard let itemKey = itemKeyForURL(url) else {
            return nil
        }
        
        guard let variant = variantForURL(url) else {
            return itemKey.precomposedStringWithCanonicalMapping
        }
        
        return "\(itemKey)__\(variant)".precomposedStringWithCanonicalMapping
    }
}
