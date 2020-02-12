
import Foundation

public extension HTTPURLResponse {
    static let etagHeaderKey = "Etag"
    static let ifNoneMatchHeaderKey = "If-None-Match"
}

final class CacheProviderHelper {
    
    static func newCachePolicyRequest(from originalRequest: NSURLRequest, newURL: URL, itemKey: String?, moc: NSManagedObjectContext) -> URLRequest? {
        
        guard let mutableRequest = (originalRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return nil
        }
        
        mutableRequest.url = newURL
        
        var etag: String?
        if let cachedResponse = URLCache.shared.cachedResponse(for: mutableRequest as URLRequest),
        let httpResponse = cachedResponse.response as? HTTPURLResponse {
            etag = httpResponse.allHeaderFields[HTTPURLResponse.etagHeaderKey] as? String
        }
        
        if etag == nil,
            let itemKey = itemKey {
            moc.performAndWait {
                if let item = CacheDBWriterHelper.cacheItem(with: itemKey, in: moc) {
                    if let itemEtag = item.etag {
                        etag = itemEtag
                    }
                }
            }
        }

        if let etag = etag {
            mutableRequest.setValue(etag, forHTTPHeaderField: HTTPURLResponse.ifNoneMatchHeaderKey)
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
