
import Foundation

final class ArticleCacheProvider: CacheProviding {
    
    private let imageController: ImageCacheController
    
    init(imageController: ImageCacheController) {
        self.imageController = imageController
    }
    
    func recentCachedURLResponse(for request: URLRequest) -> CachedURLResponse? {
        
        guard let url = request.url else {
            return nil
        }
        
        if isMimeTypeImage(type: (url as NSURL).wmf_mimeTypeForExtension()) {
            return imageController.recentCachedURLResponse(for: request)
        }
        
        let request = URLRequest(url: url)
        let urlCache = URLCache.shared
        return urlCache.cachedResponse(for: request)
    }
    
    func persistedCachedURLResponse(for request: URLRequest) -> CachedURLResponse? {
        
        guard let url = request.url else {
            return nil
        }
        
        if isMimeTypeImage(type: (url as NSURL).wmf_mimeTypeForExtension()) {
            return imageController.persistedCachedURLResponse(for: request)
        }
        
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
    
    private func isMimeTypeImage(type: String) -> Bool {
        return type.hasPrefix("image")
    }
}
