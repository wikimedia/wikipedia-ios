
import Foundation

public extension HTTPURLResponse {
    static let etagHeaderKey = "Etag"
    static let ifNoneMatchHeaderKey = "If-None-Match"
}

final class CacheProviderHelper {
    
    static func persistedCacheResponse(url: URL, responseFileName: String, responseHeaderFileName: String) -> CachedURLResponse? {
        
        guard let responseData = FileManager.default.contents(atPath: responseFileName),
            let responseHeaderData = FileManager.default.contents(atPath: responseHeaderFileName) else {
            return nil
        }
        
        //let mimeType = FileManager.default.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: responseFileName)
    
        var responseHeaders: [String: String]?
        do {
            if let unarchivedHeaders = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(responseHeaderData) as? [String: String] {
                responseHeaders = unarchivedHeaders
            }
        } catch {
            
        }
        
        if let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: responseHeaders) {
            return CachedURLResponse(response: httpResponse, data: responseData)
        }
        
        return nil
    }
}
