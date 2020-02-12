
import Foundation

class ImageCacheHeaderProvider: CacheHeaderProviding {
    func requestHeader(url: URL, forceCache: Bool = false) -> [String: String] {
        var header: [String: String] = [:]
        
        guard let itemKey = itemKeyForURL(url) else {
            return header
        }
        
        header[Session.Header.persistentCacheItemKey] = itemKey
        
        if let variant = variantForURL(url) {
            header[Session.Header.persistentCacheItemVariant] = variant
        }
        
        header[Session.Header.persistentCacheItemType] = "Image"
        header[Session.Header.persistentCacheForceCache] = String(forceCache)
        //The accept profile is case sensitive https://gerrit.wikimedia.org/r/#/c/356429/
        header["Accept"] = "application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Summary/1.1.2\""
        
        return header
    }
}

private extension ImageCacheHeaderProvider {
    
    func itemKeyForURL(_ url: URL) -> String? {
        guard let host = url.host, let imageName = WMFParseImageNameFromSourceURL(url) else {
            return url.absoluteString.precomposedStringWithCanonicalMapping
        }
        return (host + "__" + imageName).precomposedStringWithCanonicalMapping
    }

    func variantForURL(_ url: URL) -> String? {
        let sizePrefix = WMFParseSizePrefixFromSourceURL(url)
        return sizePrefix == NSNotFound ? nil : String(sizePrefix)
    }

    func uniqueFileNameForURL(_ url: URL) -> String? {
        guard let itemKey = itemKeyForURL(url),
            let variant = variantForURL(url) else {
                return nil
        }
        
        return "\(itemKey)__\(variant)".precomposedStringWithCanonicalMapping
    }
}
