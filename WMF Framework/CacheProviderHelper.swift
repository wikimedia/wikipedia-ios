
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
            mutableRequest.setValue(etag, forHTTPHeaderField: HTTPURLResponse.ifNoneMatchHeaderKey)
        }
        
        return mutableRequest.copy() as? URLRequest
    }
    
    static func persistedCacheResponse(url: URL, itemKey: String) -> CachedURLResponse? {
        
        var etag: String?
        if let moc = CacheController.backgroundCacheContext,
            let item = CacheDBWriterHelper.cacheItem(with: itemKey, in: moc) {
            moc.performAndWait {
                if let itemEtag = item.etag {
                    etag = itemEtag
                }
            }
        }
        
        
        let cachedFilePath = CacheFileWriterHelper.fileURL(for: itemKey).path
        if let data = FileManager.default.contents(atPath: cachedFilePath) {
            
            var headerFields: [String: String] = [:]
            if let etag = etag {
                headerFields[HTTPURLResponse.etagHeaderKey] = etag
            }
            if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headerFields) {
                return CachedURLResponse(response: response, data: data)
            }
        }
        
        return nil
    }
}
