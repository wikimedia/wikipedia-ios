
import Foundation

class ArticleCacheHeaderProvider: CacheHeaderProviding {
    func requestHeader(url: URL, forceCache: Bool = false) -> [String: String] {
        
        var header: [String: String] = [:]
        
        guard let itemKey = itemKeyForURL(url) else {
            return header
        }
        
        header[Session.Header.persistentCacheItemKey] = itemKey
        
        if let variant = variantForURL(url) {
            header[Session.Header.persistentCacheItemVariant] = variant
        }
        
        header[Session.Header.persistentCacheForceCache] = String(forceCache)
        
        //tonitodo: here we can pull previously saved URLResponse header and populate things like If-None-Match (etag) and Accept-Language.
        
        //The accept profile is case sensitive https://gerrit.wikimedia.org/r/#/c/356429/
        header["Accept"] = "application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Summary/1.1.2\""
        
        return header
        
    }
    
}

private extension ArticleCacheHeaderProvider {
    
    func uniqueFileNameForURL(_ url: URL) -> String? {
        
        guard let itemKey = itemKeyForURL(url),
            let variant = variantForURL(url) else {
                return nil
        }
        
        return "\(itemKey)__\(variant)".precomposedStringWithCanonicalMapping
    }
    
    func itemKeyForURL(_ url: URL) -> String? {
        return url.wmf_databaseKey
    }
    
    func variantForURL(_ url: URL) -> String? {
        
        guard let language = url.wmf_language else {
            return nil
        }
        
        for languageCode in NSLocale.wmf_preferredLanguageCodes {
            //tonitodo: seems fragile, look for cleaner way to glean from NSLocale+WMFExtras
            if let range = languageCode.range(of: "-") {
                let firstPart = languageCode[languageCode.startIndex..<range.lowerBound]
                
                if firstPart == language {
                    
                    let secondPart = languageCode[range.upperBound..<languageCode.endIndex]
                    return secondPart.isEmpty ? nil : String(secondPart)
                }
            }
        }
        
        return nil
    }
}
