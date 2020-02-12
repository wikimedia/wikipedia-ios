
import Foundation

public extension HTTPURLResponse {
    static let etagHeaderKey = "Etag"
    static let ifNoneMatchHeaderKey = "If-None-Match"
}

final class CacheProviderHelper {
    
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
