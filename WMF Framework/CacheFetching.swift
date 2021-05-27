
import Foundation

public struct CacheFetchingResult {
    let data: Data
    let response: URLResponse
}

enum CacheFetchingError: Error {
    case missingDataAndURLResponse
    case missingURLResponse
    case unableToDetermineURLRequest
}

internal protocol CacheFetching {
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, URLRequest?, URLResponse?, TemporaryFileURL?, MIMEType?) -> Void
    typealias DataCompletion = (Result<CacheFetchingResult, Error>) -> Void
    
    var permanentCacheCore: PermanentCacheCore { get }
    
    //internally populates urlRequest with cache header fields
    func dataForURL(_ url: URL, persistType: Header.PersistItemType, headers: [String: String], completion: @escaping DataCompletion) -> URLSessionTask?
    
    //assumes urlRequest is already populated with cache header fields
    func dataForURLRequest(_ urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask?
    
    //Session Passthroughs
    func cachedResponseForURL(_ url: URL, type: Header.PersistItemType) -> CachedURLResponse?
    func cachedResponseForURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? //assumes urlRequest is already populated with the proper cache headers
    func uniqueKeyForURL(_ url: URL, type: Header.PersistItemType) -> String?
    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String?
    func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String?
    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String?
    func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String?
    func variantForURLRequest(_ urlRequest: URLRequest) -> String?
    
    //Bundled migration only - copies files into cache
    func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Void, Error>) -> Void)
}

internal extension CacheFetching where Self:Fetcher {
    
    @discardableResult func dataForURLRequest(_ urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask? {
        
        let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let unwrappedResponse = urlResponse else {
                completion(.failure(CacheFetchingError.missingURLResponse))
                return
            }
            
            if let httpResponse = unwrappedResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            if let data = data,
                let urlResponse = urlResponse {
                let result = CacheFetchingResult(data: data, response: urlResponse)
                completion(.success(result))
            } else {
                completion(.failure(CacheFetchingError.missingDataAndURLResponse))
            }
        }
        
        task?.resume()
        return task
    }
    
    @discardableResult func dataForURL(_ url: URL, persistType: Header.PersistItemType, headers: [String: String] = [:], completion: @escaping DataCompletion) -> URLSessionTask? {
        
        guard let urlRequest = session.urlRequestFromPersistence(with: url, persistType: persistType, headers: headers) else {
            completion(.failure(CacheFetchingError.unableToDetermineURLRequest))
            return nil
        }
        
        return dataForURLRequest(urlRequest, completion: completion)
    }
}

//MARK: PermanentCacheCore Passthroughs (and one remaining Session Passthrough)

internal extension CacheFetching where Self:Fetcher {
    
    // This method still passes through to session. It uses a session call internally. The session method only seems to be used by this protocol extension
    // and one call from MWKImageInfoFetcher. Will leave untangling it until later - MWKImageInfoFetcher has the data source passed into it, so it should
    // be possible to disentangle.
    func urlRequestFromPersistence(with url: URL, persistType: Header.PersistItemType, cachePolicy: WMFCachePolicy? = nil, headers: [String: String] = [:]) -> URLRequest? {
        session.urlRequestFromPersistence(with: url, persistType: persistType, cachePolicy: cachePolicy, headers: headers)
    }
    
    func cachedResponseForURL(_ url: URL, type: Header.PersistItemType) -> CachedURLResponse? {
        let request = permanentCacheCore.urlRequestFromURL(url, type: type)
        return cachedResponseForURLRequest(request)
    }
    
    // This method calls through from the cache core to the url cache itself.
    // That is the pattern this refactor is trying to avoid, but one case of it is better than 14 or so
    // It may be possible to disentangle this one in a future commit also.
    func cachedResponseForURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? {
        permanentCacheCore.urlCache.cachedResponse(for: urlRequest)
    }
    
    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String? {
        permanentCacheCore.uniqueFileNameForURLRequest(urlRequest)
    }
    
    func uniqueKeyForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        permanentCacheCore.uniqueFileNameForURL(url, type: type)
    }
    
    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        permanentCacheCore.cacheResponse(httpUrlResponse: httpUrlResponse, content: content, urlRequest: urlRequest, success: success, failure: failure)
    }
    
    func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        permanentCacheCore.writeBundledFiles(mimeType: mimeType, bundledFileURL: bundledFileURL, urlRequest: urlRequest, completion: completion)
    }
    
    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        permanentCacheCore.uniqueFileNameForItemKey(itemKey, variant: variant)
    }
    
    func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String? {
        permanentCacheCore.itemKeyForURLRequest(urlRequest)
    }
    
    func variantForURLRequest(_ urlRequest: URLRequest) -> String? {
        permanentCacheCore.variantForURLRequest(urlRequest)
    }
    
    func itemKeyForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        permanentCacheCore.itemKeyForURL(url, type: type)
    }
    
    func variantForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        permanentCacheCore.variantForURL(url, type: type)
    }
        
    func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        permanentCacheCore.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
    }
    
    func isCachedWithURLRequest(_ request: URLRequest, completion: @escaping (Bool) -> Void) {
        permanentCacheCore.isCachedWithURLRequest(request, completion: completion)
    }
}
