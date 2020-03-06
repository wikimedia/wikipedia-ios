
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

public protocol CacheFetching {
    typealias TemporaryFileURL = URL
    typealias MIMEType = String
    typealias DownloadCompletion = (Error?, URLRequest?, URLResponse?, TemporaryFileURL?, MIMEType?) -> Void
    typealias DataCompletion = (Result<CacheFetchingResult, Error>) -> Void
    
    //internally populates urlRequest with cache header fields
    func dataForURL(_ url: URL, type: Header.PersistItemType, completion: @escaping DataCompletion) -> URLSessionTask?
    
    //assumes urlRequest is already populated with cache header fields
    func dataForURLRequest(_ urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask?
    
    //Session Passthroughs
    func cachedResponseForURL(_ url: URL, type: Header.PersistItemType) -> CachedURLResponse?
    func cachedResponseForURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? //assumes urlRequest is already populated with the proper cache headers
    func uniqueKeyForURL(_ url: URL, type: Header.PersistItemType) -> String?
    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, mimeType: String?, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String?
    func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String?
    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String?
    func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String?
    func variantForURLRequest(_ urlRequest: URLRequest) -> String?
    
    //Bundled migration only - copies files into cache
    func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Bool, Error>) -> Void)
}

extension CacheFetching where Self:Fetcher {
    
    @discardableResult public func dataForURLRequest(_ urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask? {
        
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
    
    @discardableResult public func dataForURL(_ url: URL, type: Header.PersistItemType, completion: @escaping DataCompletion) -> URLSessionTask? {
        
        guard let urlRequest = session.urlRequestFromURL(url, type: type) else {
            completion(.failure(CacheFetchingError.unableToDetermineURLRequest))
            return nil
        }
        
        return dataForURLRequest(urlRequest, completion: completion)
    }
}

//MARK: Session Passthroughs

extension CacheFetching where Self:Fetcher {
    
    public func cachedResponseForURL(_ url: URL, type: Header.PersistItemType) -> CachedURLResponse? {
        return session.cachedResponseForURL(url, type: type)
    }
    
    public func cachedResponseForURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? {
        return session.cachedResponseForURLRequest(urlRequest)
    }
    
    public func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String? {
        return session.uniqueFileNameForURLRequest(urlRequest)
    }
    
    public func uniqueKeyForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        return session.uniqueKeyForURL(url, type: type)
    }
    
    public func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, mimeType: String?, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        session.cacheResponse(httpUrlResponse: httpUrlResponse, content: content, mimeType: mimeType, urlRequest: urlRequest, success: success, failure: failure)
    }
    
    public func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Bool, Error>) -> Void) {
        session.writeBundledFiles(mimeType: mimeType, bundledFileURL: bundledFileURL, urlRequest: urlRequest, completion: completion)
    }
    
    public func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        return session.uniqueFileNameForItemKey(itemKey, variant: variant)
    }
    
    public func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String? {
        return session.itemKeyForURLRequest(urlRequest)
    }
    
    public func variantForURLRequest(_ urlRequest: URLRequest) -> String? {
        return session.variantForURLRequest(urlRequest)
    }
    
    public func itemKeyForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        return session.itemKeyForURL(url, type: type)
    }
    
    public func variantForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        return session.variantForURL(url, type: type)
    }
    
    public func urlRequestFromURL(_ url: URL, type: Header.PersistItemType, cachePolicy: URLRequest.CachePolicy? = nil) -> URLRequest? {
        return session.urlRequestFromURL(url, type: type, cachePolicy: cachePolicy)
    }
    
    public func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        return session.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
    }
    
    public func isCachedWithURLRequest(_ request: URLRequest) -> Bool {
        return session.isCachedWithURLRequest(request)
    }
}
