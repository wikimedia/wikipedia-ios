
import Foundation

class ArticleCacheKeyGenerator: CacheKeyGenerating {
    static func uniqueFileNameForURL(_ url: URL) -> String? {
        
        guard let itemKey = itemKeyForURL(url),
            let variant = variantForURL(url) else {
                return nil
        }
        
        return "\(itemKey)__\(variant)".precomposedStringWithCanonicalMapping
    }
    
    static func itemKeyForURL(_ url: URL) -> String? {
        return url.wmf_databaseKey
    }
    
    static func variantForURL(_ url: URL) -> String? {
        return Locale.preferredWikipediaLanguageVariant(for: url)
    }
}
