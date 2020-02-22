
import Foundation

public final class ImageFetcher: Fetcher, CacheFetching {
    
    private let cacheHeaderProvider: CacheHeaderProviding = ImageCacheHeaderProvider()
    
    @objc public func request(for url: URL, forceCache: Bool = false) -> URLRequest {

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
    
    @objc @discardableResult public func data(for urlRequest: URLRequest, completion: @escaping (Data?, Error?) -> Void) -> URLSessionTask? {
        let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                completion(data, nil)
            }
        }
        
        task?.resume()
        return task
    }
}
