
import Foundation

class ArticleCacheKeyGenerator: CacheKeyGenerating {
    static func itemKeyForURL(_ url: URL) -> String? {
        return url.wmf_databaseKey
    }
    
    static func variantForURL(_ url: URL) -> String? {
        
        #if WMF_APPS_LABS_MOBILE_HTML
            if let pathComponents = (url as NSURL).pathComponents,
            pathComponents.count >= 2 {
                let newHost = pathComponents[1]
                let hostComponents = newHost.components(separatedBy: ".")
                if hostComponents.count < 3 {
                    return Locale.preferredWikipediaLanguageVariant(for: url)
                } else {
                    let potentialLanguage = hostComponents[0]
                    if potentialLanguage == "m" {
                        return Locale.preferredWikipediaLanguageVariant(for: url)
                    } else {
                        return Locale.preferredWikipediaLanguageVariant(for: url, urlLanguage: potentialLanguage)
                    }
                }
            }
        
            return Locale.preferredWikipediaLanguageVariant(for: url)
        #else
            return Locale.preferredWikipediaLanguageVariant(for: url)
        #endif
    }
}
