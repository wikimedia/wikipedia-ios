
import Foundation

final class ArticleCacheProvider: CacheProviding {
    
    func persistedCachedURLResponse(for url: URL) -> CachedURLResponse? {
        
        //mobile-html endpoint is saved under the desktop url. if it's mobile-html first convert to desktop before pulling the key.
        guard let key = ArticleURLConverter.desktopURL(mobileHTMLURL: url)?.wmf_databaseKey ?? url.wmf_databaseKey else {
            return nil
        }
        
        let cachedFilePath = CacheFileWriterHelper.fileURL(for: key).path
        if let data = FileManager.default.contents(atPath: cachedFilePath) {
            return CacheProviderHelper.persistedCachedURLResponse(for: url, with: data, at: cachedFilePath)
        }
        
        return nil
    }
}
