
import Foundation

final class CacheProviderHelper {
    static func persistedCachedURLResponse(for url: URL, with data: Data, at filePath: String) -> CachedURLResponse {
        let mimeType = FileManager.default.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: filePath)
        let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
        return CachedURLResponse(response: response, data: data)
    }
}
