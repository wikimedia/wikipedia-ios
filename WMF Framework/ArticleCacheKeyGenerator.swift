
import Foundation

class ArticleCacheKeyGenerator: CacheKeyGenerating {
    static func itemKeyForURL(_ url: URL) -> String? {
        return url.wmf_databaseKey
    }
    
    static func variantForURL(_ url: URL) -> String? {
        return Locale.preferredWikipediaLanguageVariant(for: url)
    }
}
