
import Foundation

final class ImageCacheProvider: CacheProviding {
    
    func persistedCachedURLResponse(for request: URLRequest) -> CachedURLResponse? {

        //tonitodo: variant fallbacks here
        guard let url = request.url,
            let key = url.wmf_databaseKey else {
            return nil
        }
        
        let cachedFilePath = CacheFileWriterHelper.fileURL(for: key).path
        if let data = FileManager.default.contents(atPath: cachedFilePath) {
            return CacheProviderHelper.persistedCachedURLResponse(for: url, with: data, at: cachedFilePath)
        }
        
        return nil
    }
}
