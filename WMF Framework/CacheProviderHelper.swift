
import Foundation

final class CacheProviderHelper {
    
    static func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL, cachePolicy: NSURLRequest.CachePolicy, itemKey: String?, moc: NSManagedObjectContext) -> URLRequest? {
        
        guard let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return nil
        }
        
        mutableRequest.url = newURL
        mutableRequest.cachePolicy = cachePolicy
        
        var etag: String?
        if let cachedResponse = URLCache.shared.cachedResponse(for: mutableRequest as URLRequest),
        let httpResponse = cachedResponse.response as? HTTPURLResponse {
            etag = httpResponse.allHeaderFields["Etag"] as? String
        }
        
        if etag == nil,
            let itemKey = itemKey {
            if let item = CacheDBWriterHelper.cacheItem(with: itemKey, in: moc) {
                moc.performAndWait {
                    if let itemEtag = item.etag {
                        etag = itemEtag
                    }
                }
            }
        }

        //TODO: do we need "Last-Modified" & "If-Modified-Since" respectively?
        if let etag = etag {
             mutableRequest.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        return mutableRequest.copy() as? URLRequest
    }
    
    static func persistedCacheResponse(url: URL, itemKey: String) -> CachedURLResponse? {
        
        let cachedFilePath = CacheFileWriterHelper.fileURL(for: itemKey).path
        if let data = FileManager.default.contents(atPath: cachedFilePath) {
            
            let mimeType = FileManager.default.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: cachedFilePath)
            let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
            return CachedURLResponse(response: response, data: data)
        }
        
        return nil
    }
}
