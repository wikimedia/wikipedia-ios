
import Foundation

final class ImageCacheProvider: CacheProviding {
    
    func persistedCachedURLResponse(for url: URL) -> CachedURLResponse? {

        //tonitodo: variant fallbacks here
        guard let key = url.wmf_databaseKey else {
            return nil
        }
        
        let cachedFilePath = CacheFileWriterHelper.fileURL(for: key).path
        if let data = FileManager.default.contents(atPath: cachedFilePath) {
            return CacheProviderHelper.persistedCachedURLResponse(for: url, with: data, at: cachedFilePath)
        }
        
        return nil
    }
}
