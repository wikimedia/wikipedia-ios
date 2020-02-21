
import Foundation

final class ImageFetcher: Fetcher, CacheFetching {
    
    private let cacheHeaderProvider: CacheHeaderProviding = ImageCacheHeaderProvider()
    
    func request(for url: URL, forceCache: Bool = false) -> URLRequest {

        var request = URLRequest(url: url)
        let header = cacheHeaderProvider.requestHeader(urlRequest: request)
        
        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if forceCache {
            request.cachePolicy = .returnCacheDataElseLoad
        }
        
        return request
    }
}
