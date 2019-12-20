
import Foundation

//Responsible for providing CachedURLResponses, either from URLCache.shared or FileManager.

final public class ArticleCacheProvider {
    
    private let syncer: ArticleCacheSyncer
    private let fileManager: FileManager
    
    init(syncer: ArticleCacheSyncer, fileManager: FileManager) {
        self.syncer = syncer
        self.fileManager = fileManager
    }
    
    public func recentCachedURLResponse(for url: URL) -> CachedURLResponse? {
        let request = URLRequest(url: url)
        let urlCache = URLCache.shared
        return urlCache.cachedResponse(for: request)
    }
    
    public func savedCachedURLResponse(for url: URL) -> CachedURLResponse? {
        
        //mobile-html endpoint is saved under the desktop url. if it's mobile-html first convert to desktop before pulling the key.
        guard let key = ArticleURLConverter.desktopURL(mobileHTMLURL: url)?.wmf_databaseKey ?? url.wmf_databaseKey else {
            return nil
        }
        
        let cachedFilePath = syncer.fileURL(for: key).path
        if let data = fileManager.contents(atPath: cachedFilePath) {
            return savedCachedURLResponse(for: url, with: data, at: cachedFilePath)
        }
        
        return nil
    }
    
    private func savedCachedURLResponse(for url: URL, with data: Data, at filePath: String) -> CachedURLResponse {
        let mimeType = fileManager.getValueForExtendedFileAttributeNamed(WMFExtendedFileAttributeNameMIMEType, forFileAtPath: filePath)
        let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
        return CachedURLResponse(response: response, data: data)
    }
}

private extension FileManager {
    func getValueForExtendedFileAttributeNamed(_ attributeName: String, forFileAtPath path: String) -> String? {
        let name = (attributeName as NSString).utf8String
        let path = (path as NSString).fileSystemRepresentation

        let bufferLength = getxattr(path, name, nil, 0, 0, 0)

        guard bufferLength != -1, let buffer = malloc(bufferLength) else {
            return nil
        }

        let readLen = getxattr(path, name, buffer, bufferLength, 0, 0)
        return String(bytesNoCopy: buffer, length: readLen, encoding: .utf8, freeWhenDone: true)
    }
}
