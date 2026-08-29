import Foundation
import CocoaLumberjackSwift
import WMFData

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
    
    // internally populates urlRequest with cache header fields
    func dataForURL(_ url: URL, persistType: Header.PersistItemType, headers: [String: String], completion: @escaping DataCompletion) -> URLSessionTask?
    
    // assumes urlRequest is already populated with cache header fields
    func dataForURLRequest(_ urlRequest: URLRequest, completion: @escaping DataCompletion) -> URLSessionTask?
    
    // Session Passthroughs
    func cachedResponseForURL(_ url: URL, type: Header.PersistItemType) -> CachedURLResponse?
    func cachedResponseForURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? // assumes urlRequest is already populated with the proper cache headers
    func uniqueKeyForURL(_ url: URL, type: Header.PersistItemType) -> String?
    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String?
    func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String?
    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String?
    func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String?
    func variantForURLRequest(_ urlRequest: URLRequest) -> String?
    
    // Bundled migration only - copies files into cache
    func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Void, Error>) -> Void)
}

// note, Session.handleResponse and SessionDelegate don't cover this path, so HTTP failures here are otherwise unlogged
enum CacheFetchingHTTPErrorLogger {

    static let source = "CacheFetching"

    static func logIfNeeded(httpResponse: HTTPURLResponse, urlRequest: URLRequest) {
        // 404s are routine here for resources an article no longer references, so only log rate limits and server errors
        let statusCode = httpResponse.statusCode
        guard statusCode == RequestError.rateLimitedStatusCode || (500...599).contains(statusCode) else {
            return
        }

        DDLogError("CacheFetching: HTTP \(statusCode) for \(urlRequest.url?.absoluteString ?? "unknown URL")")

        ClientErrorFunnel.shared.logHTTPError(
            info: WMFHTTPErrorInfo(
                statusCode: statusCode,
                method: urlRequest.httpMethod,
                url: urlRequest.url?.absoluteString,
                source: source
            )
        )
    }
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
            
            // note, the status code is carried through so SavedArticlesFetcher can tell a 429 from an ordinary failure
            if let httpResponse = unwrappedResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
                CacheFetchingHTTPErrorLogger.logIfNeeded(httpResponse: httpResponse, urlRequest: urlRequest)
                completion(.failure(RequestError.from(code: httpResponse.statusCode, response: httpResponse)))
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
    
    @discardableResult public func dataForURL(_ url: URL, persistType: Header.PersistItemType, headers: [String: String] = [:], completion: @escaping DataCompletion) -> URLSessionTask? {
        
        guard let urlRequest = session.urlRequestFromPersistence(with: url, persistType: persistType, headers: headers) else {
            completion(.failure(CacheFetchingError.unableToDetermineURLRequest))
            return nil
        }
        
        return dataForURLRequest(urlRequest, completion: completion)
    }
}

// MARK: Session Passthroughs

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
    
    public func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        session.cacheResponse(httpUrlResponse: httpUrlResponse, content: content, urlRequest: urlRequest, success: success, failure: failure)
    }
    
    public func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Void, Error>) -> Void) {
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
    
    public func urlRequestFromPersistence(with url: URL, persistType: Header.PersistItemType, cachePolicy: WMFCachePolicy? = nil, headers: [String: String] = [:]) -> URLRequest? {
        return session.urlRequestFromPersistence(with: url, persistType: persistType, cachePolicy: cachePolicy, headers: headers)
    }
    
    public func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        return session.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
    }
    
    public func isCachedWithURLRequest(_ request: URLRequest, completion: @escaping (Bool) -> Void) {
        return session.isCachedWithURLRequest(request, completion: completion)
    }
}
