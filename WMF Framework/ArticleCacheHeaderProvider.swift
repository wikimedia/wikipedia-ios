
import Foundation

class ArticleCacheHeaderProvider: CacheHeaderProviding {
    func requestHeader(url: URL, forceCache: Bool = false) -> [String: String] {
        
        var header: [String: String] = [:]
        
        guard let itemKey = itemKeyForURL(url) else {
            return header
        }
        
        header[Session.Header.persistentCacheItemKey] = itemKey
        
        header[Session.Header.persistentCacheForceCache] = String(forceCache)
        
        if let variant = variantForURL(url) {
            header[Session.Header.persistentCacheItemVariant] = variant
        }
        
        //tonitodo: here we can pull previously saved URLResponse header and populate things like If-None-Match (etag) and Accept-Language (vary).
        
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
        
        //if any wmf_preferredLanguageCodes have the same language code as url.wmf_language, return preferred variant
               
               //tonitodo: seems fragile, look for cleaner way to glean from NSLocale+WMFExtras
        
        for languageCode in NSLocale.wmf_preferredLanguageCodes {
            
            if let range = languageCode.range(of: "-") {
                let firstPart = languageCode[languageCode.startIndex..<range.lowerBound]
                
                if firstPart == language {
                    
                    //return entire variant
                    return languageCode
                }
            }
        }
        
        //maybe tonitodo? default variant here. If url.wmf_language supports variants (not sure if we want to hardcode variant-able languages or not but if so use that, could also try pulling a previous cached urlresponse header and check Vary value.
        
        return nil
    }
}
