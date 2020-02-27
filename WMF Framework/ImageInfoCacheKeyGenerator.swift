
import Foundation

class ImageInfoCacheKeyGenerator: CacheKeyGenerating {
    static func itemKeyForURL(_ url: URL) -> String? {
        return url.absoluteString.precomposedStringWithCanonicalMapping;
    }
    
    static func variantForURL(_ url: URL) -> String? {
        return nil
    }
}
