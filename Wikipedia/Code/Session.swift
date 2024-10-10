import Foundation
import CocoaLumberjackSwift

public enum WMFCachePolicy {
    case foundation(URLRequest.CachePolicy)
    case noPersistentCacheOnError
    
    var rawValue: UInt {
        
        switch self {
        case .foundation(let cachePolicy):
            return cachePolicy.rawValue
        case .noPersistentCacheOnError:
            return 99
        }
    }
}

@objc(WMFSessionAuthenticationDelegate)
protocol SessionAuthenticationDelegate: NSObjectProtocol {
    func deauthenticate()
    func attemptReauthentication()
}

@objc(WMFSession)
public class Session: NSObject {
    
    public struct Request {
        public enum Method {
            case get
            case post
            case put
            case delete
            case head

            var stringValue: String {
                switch self {
                case .post:
                    return "POST"
                case .put:
                    return "PUT"
                case .delete:
                    return "DELETE"
                case .head:
                    return "HEAD"
                case .get:
                    fallthrough
                default:
                    return "GET"
                }
            }
        }

        public enum Encoding {
            case json
            case form
            case html
        }
    }
    
    public struct Callback {
        public typealias UsedPermanentCache = Bool
        let response: ((URLResponse) -> Void)?
        let data: ((Data) -> Void)?
        let success: ((UsedPermanentCache) -> Void)
        let failure: ((Error) -> Void)
        let cacheFallbackError: ((Error) -> Void)? // Extra handling block when session signals a success and returns data because it's leaning on cache, but actually reached a server error.
        
        public init(response: ((URLResponse) -> Void)?, data: ((Data) -> Void)?, success: @escaping (UsedPermanentCache) -> Void, failure: @escaping (Error) -> Void, cacheFallbackError: ((Error) -> Void)?) {
            self.response = response
            self.data = data
            self.success = success
            self.failure = failure
            self.cacheFallbackError = cacheFallbackError
        }
    }
    
    // event logging uuid, set if enabled, nil if disabled
    private var xWMFUUID: String? {
        let userDefaults = UserDefaults.standard
        return userDefaults.wmf_appInstallId
    }
    
    private static let defaultCookieStorage: HTTPCookieStorage = {
        let storage = sharedCookieStorage
        storage.cookieAcceptPolicy = .always
        return storage
    }()
    
    public func hasCentralAuthUserCookie() -> Bool {
        guard let storage = defaultURLSession.configuration.httpCookieStorage else {
            return false
        }
        
        guard let cookie = storage.cookieWithName("centralauth_User", for: Configuration.current.centralAuthCookieSourceDomain),
              !cookie.value.isEmpty else {
            return false
        }
        
        return true
    }
    
    public func cloneCentralAuthCookies() {
        // centralauth_ cookies work for any central auth domain - this call copies the centralauth_* cookies from .wikipedia.org to an explicit list of domains. This is  hardcoded because we only want to copy ".wikipedia.org" cookies regardless of WMFDefaultSiteDomain
        defaultURLSession.configuration.httpCookieStorage?.copyCookiesWithNamePrefix("centralauth_", for: configuration.centralAuthCookieSourceDomain, to: configuration.centralAuthCookieTargetDomains)
    }
    
    @objc public func removeAllCookies() {
        guard let storage = defaultURLSession.configuration.httpCookieStorage else {
            return
        }
        // Cookie reminders:
        //  - "HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)" does NOT seem to work.
        storage.cookies?.forEach { cookie in
            storage.deleteCookie(cookie)
        }
    }
    
    public func hasValidCentralAuthCookies(for domain: String) -> Bool {
        guard let storage = defaultURLSession.configuration.httpCookieStorage else {
            return false
        }
        let cookies = storage.cookiesWithNamePrefix("centralauth_", for: domain)
        guard !cookies.isEmpty else {
            return false
        }
        let now = Date()
        for cookie in cookies {
            if let cookieExpirationDate = cookie.expiresDate, cookieExpirationDate < now {
                return false
            }
        }
        return true
    }
    
    @objc public func clearTemporaryCache() {
        defaultURLSession.configuration.urlCache?.removeAllCachedResponses()
    }
    
    /// The permanent cache to utilize for this session
    weak var permanentCache: PermanentCacheController? {
        didSet {
            defaultURLSession.finishTasksAndInvalidate()
            defaultURLSession = Session.getURLSession(with: permanentCache, delegate: sessionDelegate)
        }
    }
    
    private static func getURLSession(with permanentCacheController: PermanentCacheController? = nil, delegate: SessionDelegate) -> URLSession {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = Session.defaultCookieStorage
        config.urlCache = permanentCacheController?.urlCache ?? URLCache.shared
        return URLSession(configuration: config, delegate: delegate, delegateQueue: delegate.delegateQueue)
    }
    
    private let configuration: Configuration
    public var defaultURLSession: URLSession
    private let sessionDelegate: SessionDelegate
    @objc weak var authenticationDelegate: SessionAuthenticationDelegate?
    
    @objc public required init(configuration: Configuration) {
        self.configuration = configuration
        self.sessionDelegate = SessionDelegate()
        self.defaultURLSession = Session.getURLSession(delegate: sessionDelegate)
    }
    
    @objc public static let sharedCookieStorage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: WMFApplicationGroupIdentifier)
    
    deinit {
        teardown()
    }
    
    @objc public func teardown() {
        guard defaultURLSession !== URLSession.shared else { // [NSURLSession sharedSession] may not be invalidated
            return
        }
        defaultURLSession.invalidateAndCancel()
        defaultURLSession = URLSession.shared
    }
    
    public let wifiOnlyURLSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = Session.defaultCookieStorage
        config.allowsCellularAccess = false
        return URLSession(configuration: config)
    }()
    
    @objc(requestToGetURL:)
    public func request(toGET requestURL: URL?) -> URLRequest? {
        guard let requestURL = requestURL else {
            return nil
        }
        return request(with: requestURL, method: .get)
    }

    /// If `bodyData` is set, it will be used. Otherwise, `bodyParameters` will be encoded into the provided `bodyEncoding`
    public func request(with requestURL: URL, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyData: Data? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], cachePolicy: URLRequest.CachePolicy? = nil) -> URLRequest {
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.stringValue
        if let cachePolicy = cachePolicy {
            request.cachePolicy = cachePolicy
        }
        let defaultHeaders = [
            "Accept": "application/json; charset=utf-8",
            "Accept-Encoding": "gzip",
            "User-Agent": WikipediaAppUtils.versionedUserAgent(),
            "Accept-Language": requestURL.wmf_languageVariantCode ?? Locale.acceptLanguageHeaderForPreferredLanguages
        ]
        for (key, value) in defaultHeaders {
            guard headers[key] == nil else {
                continue
            }
            request.setValue(value, forHTTPHeaderField: key)
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let xWMFUUID = xWMFUUID {
            request.setValue(xWMFUUID, forHTTPHeaderField: "X-WMF-UUID")
        }
        guard bodyParameters != nil || bodyData != nil else {
            return request
        }
        switch bodyEncoding {
        case .json:
            if let data = bodyData {
                request.httpBody = data
            } else if let bodyParameters = bodyParameters {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: bodyParameters, options: [])
                } catch let error {
                    DDLogError("error serializing JSON: \(error)")
                }
            }
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        case .form:
            if let data = bodyData {
                request.httpBody = data
            } else if let bodyParametersDictionary = bodyParameters as? [String: Any] {
                let queryString = URLComponents.percentEncodedQueryStringFrom(bodyParametersDictionary)
                request.httpBody = queryString.data(using: String.Encoding.utf8)
            }
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        case .html:
            if let data = bodyData {
                request.httpBody = data
            } else if let  body = bodyParameters as? String {
                request.httpBody = body.data(using: .utf8)
            }
            request.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
    
    @discardableResult public func jsonDictionaryTask(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let url = url else {
            return nil
        }
        let dictionaryRequest = request(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding)
        return jsonDictionaryTask(with: dictionaryRequest, completionHandler: completionHandler)
    }
    
    public func dataTask(with request: URLRequest, callback: Callback) -> URLSessionTask? {
        
        // odd workaround to show an article as living doc icons in the article content web view.
        let botIconName = ArticleAsLivingDocViewModel.Event.Large.botIconName
        if let url = request.url,
           url.absoluteString.contains(botIconName),
           let imageData = UIImage(named: botIconName)?.pngData() {
            let response = URLResponse(url: url, mimeType: "image/png", expectedContentLength: imageData.count, textEncodingName: nil)
            callback.response?(response)
            callback.data?(imageData)
            callback.success(false)
            return nil
        }

        let anonIconName = ArticleAsLivingDocViewModel.Event.Large.anonymousIconName
        if let url = request.url,
           url.absoluteString.contains(anonIconName),
           let imageData = UIImage(named: anonIconName)?.pngData() {
            let response = URLResponse(url: url, mimeType: "image/png", expectedContentLength: imageData.count, textEncodingName: nil)
            callback.response?(response)
            callback.data?(imageData)
            callback.success(false)
            return nil
        }
        
        if request.cachePolicy == .returnCacheDataElseLoad,
            let cachedResponse = permanentCache?.urlCache.cachedResponse(for: request) {
            callback.response?(cachedResponse.response)
            callback.data?(cachedResponse.data)
            callback.success(true)
            return nil
        }
        
        let task = defaultURLSession.dataTask(with: request)
        sessionDelegate.addCallback(callback: callback, for: task)
        return task
    }
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        
        let cachedCompletion = { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Swift.Void in
            
            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 304 {
                
                if let cachedResponse = self?.permanentCache?.urlCache.cachedResponse(for: request) {
                    completionHandler(cachedResponse.data, cachedResponse.response, nil)
                    return
                }
            }
            
            if error != nil {
                
                if let cachedResponse = self?.permanentCache?.urlCache.cachedResponse(for: request) {
                    completionHandler(cachedResponse.data, cachedResponse.response, nil)
                    return
                }
            }
            
            completionHandler(data, response, error)
            
        }
        
        let task = defaultURLSession.dataTask(with: request, completionHandler: cachedCompletion)
        return task
    }
    
    // tonitodo: utlilize Callback & addCallback/session delegate stuff instead of completionHandler
    public func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return defaultURLSession.downloadTask(with: url, completionHandler: completionHandler)
    }

    public func downloadTask(with urlRequest: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask? {

        return defaultURLSession.downloadTask(with: urlRequest, completionHandler: completionHandler)
    }
    
    public func dataTask(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], cachePolicy: URLRequest.CachePolicy? = nil, priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let url = url else {
            return nil
        }
        let dataRequest = request(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, headers: headers, cachePolicy: cachePolicy)
        let task = defaultURLSession.dataTask(with: dataRequest, completionHandler: completionHandler)
        task.priority = priority
        return task
    }
    
    /**
     Shared response handling for common status codes. Currently logs the user out and removes local credentials if a 401 is received
     and an attempt to re-login with stored credentials fails.
    */
    private func handleResponse(_ response: URLResponse?, reattemptLoginOn401Response: Bool = true) {
        guard let response = response, let httpResponse = response as? HTTPURLResponse else {
            return
        }
        switch httpResponse.statusCode {
        case 401:
            if reattemptLoginOn401Response {
                authenticationDelegate?.attemptReauthentication()
            } else {
                authenticationDelegate?.deauthenticate()
            }
        default:
            break
        }
    }
    
    /**
     Creates a URLSessionTask that will handle the response by decoding it to the decodable type T. If the response isn't 200, or decoding to T fails, it'll attempt to decode the response to codable type E (typically an error response).
     - parameters:
         - url: The url for the request
         - method: The HTTP method for the request
         - bodyParameters: The body parameters for the request
         - bodyEncoding: The body encoding for the request body parameters
         - completionHandler: Called after the request completes
         - result: The result object decoded from JSON
         - errorResult: The error result object decoded from JSON
         - response: The URLResponse
         - error: Any network or parsing error
     */
    @discardableResult public func jsonDecodableTaskWithDecodableError<T: Decodable, E: Decodable>(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, cachePolicy: URLRequest.CachePolicy? = nil, completionHandler: @escaping (_ result: T?, _ errorResult: E?, _ response: URLResponse?, _ error: Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let task = dataTask(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, cachePolicy: cachePolicy, completionHandler: { (data, response, error) in
            self.handleResponse(response)
            guard let data = data else {
                completionHandler(nil, nil, response, error)
                return
            }
            let handleErrorResponse = {
                do {
                    let errorResult: E = try self.jsonDecodeData(data: data)
                    completionHandler(nil, errorResult, response, nil)
                } catch let errorResultParsingError {
                    completionHandler(nil, nil, response, errorResultParsingError)
                }
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                handleErrorResponse()
                return
            }
            
            do {
                let result: T = try self.jsonDecodeData(data: data)
                completionHandler(result, nil, response, error)
            } catch let resultParsingError {
                DDLogError("Error parsing codable response: \(resultParsingError)")
                handleErrorResponse()
            }
        }) else {
            completionHandler(nil, nil, nil, RequestError.invalidParameters)
            return nil
        }
        return task
    }

    /**
     Creates a URLSessionTask that will handle the response by decoding it to the decodable type T.
     - parameters:
        - url: The url for the request
        - method: The HTTP method for the request
        - bodyParameters: The body parameters for the request
        - bodyEncoding: The body encoding for the request body parameters
        - headers: headers for the request
        - cachePolicy: cache policy for the request
        - priority: priority for the request
        - completionHandler: Called after the request completes
        - result: The result object decoded from JSON
        - response: The URLResponse
        - error: Any network or parsing error
     */
    @discardableResult public func jsonDecodableTask<T: Decodable>(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], cachePolicy: URLRequest.CachePolicy? = nil, priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (_ result: T?, _ response: URLResponse?,  _ error: Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let task = dataTask(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, headers: headers, cachePolicy: cachePolicy, priority: priority, completionHandler: { (data, response, error) in
            self.handleResponse(response)
            guard let data = data else {
                completionHandler(nil, response, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completionHandler(nil, response, nil)
                return
            }
            do {
                let result: T = try self.jsonDecodeData(data: data)
                completionHandler(result, response, error)
            } catch let resultParsingError {
                DDLogError("Error parsing codable response: \(resultParsingError)")
                completionHandler(nil, response, resultParsingError)
            }
        }) else {
            completionHandler(nil, nil, RequestError.invalidParameters)
            return nil
        }
        task.resume()
        return task
    }
    
    @discardableResult public func jsonDecodableTask<T: Decodable>(with urlRequest: URLRequest, completionHandler: @escaping (_ result: T?, _ response: URLResponse?,  _ error: Error?) -> Swift.Void) -> URLSessionDataTask? {
        
        guard let task = dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            self.handleResponse(response)
            guard let data = data else {
                completionHandler(nil, response, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completionHandler(nil, response, nil)
                return
            }
            do {
                let result: T = try self.jsonDecodeData(data: data)
                completionHandler(result, response, error)
            } catch let resultParsingError {
                DDLogError("Error parsing codable response: \(resultParsingError)")
                completionHandler(nil, response, resultParsingError)
            }
        }) else {
            completionHandler(nil, nil, RequestError.invalidParameters)
            return nil
        }
        
        task.resume()
        return task
    }
    
    @discardableResult private func jsonDictionaryTask(with request: URLRequest, reattemptLoginOn401Response: Bool = true, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        
        let cachedCompletion = { (data: Data?, response: URLResponse?, error: Error?) -> Swift.Void in
        
            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 304 {
                
                if let cachedResponse = self.permanentCache?.urlCache.cachedResponse(for: request),
                    let responseObject = try? JSONSerialization.jsonObject(with: cachedResponse.data, options: []) as? [String: Any] {
                    completionHandler(responseObject, cachedResponse.response as? HTTPURLResponse, nil)
                    return
                }
            }
            
            if error != nil, request.prefersPersistentCacheOverError {                
                if let cachedResponse = self.permanentCache?.urlCache.cachedResponse(for: request),
                    let responseObject = try? JSONSerialization.jsonObject(with: cachedResponse.data, options: []) as? [String: Any] {
                    completionHandler(responseObject, cachedResponse.response as? HTTPURLResponse, nil)
                    return
                }
            }
            
            guard let data = data else {
                completionHandler(nil, response as? HTTPURLResponse, error)
                return
            }
            do {
                guard !data.isEmpty, let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completionHandler(nil, response as? HTTPURLResponse, nil)
                    return
                }
                completionHandler(responseObject, response as? HTTPURLResponse, nil)
            } catch let error {
                DDLogError("Error parsing JSON: \(error)")
                completionHandler(nil, response as? HTTPURLResponse, error)
            }
        }
        
        return defaultURLSession.dataTask(with: request, completionHandler: { (data, response, error) in
            self.handleResponse(response, reattemptLoginOn401Response: reattemptLoginOn401Response)
            cachedCompletion(data, response, error)
        })
    }
    
    func jsonDecodeData<T: Decodable>(data: Data) throws -> T {
        let decoder = JSONDecoder()
        let result: T = try decoder.decode(T.self, from: data)
        return result
    }

    @objc(getJSONDictionaryFromURL:ignoreCache:completionHandler:)
    @discardableResult public func getJSONDictionary(from url: URL?, ignoreCache: Bool = false, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        guard let url = url else {
            completionHandler(nil, nil, RequestError.invalidParameters)
            return nil
        }
        var getRequest = request(with: url, method: .get)
        if ignoreCache {
            getRequest.cachePolicy = .reloadIgnoringLocalCacheData
            getRequest.prefersPersistentCacheOverError = false
        }
        let task = jsonDictionaryTask(with: getRequest, completionHandler: completionHandler)
        task.resume()
        return task
    }
    
    @objc(getJSONDictionaryFromURLRequest:completionHandler:)
    @discardableResult public func getJSONDictionary(from urlRequest: URLRequest, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {

        let task = jsonDictionaryTask(with: urlRequest, completionHandler: completionHandler)
        task.resume()
        return task
    }
    
    @objc(postFormEncodedBodyParametersToURL:bodyParameters:reattemptLoginOn401Response:completionHandler:)
    @discardableResult public func postFormEncodedBodyParametersToURL(to url: URL?, bodyParameters: [String: String]? = nil, reattemptLoginOn401Response: Bool = true, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        guard let url = url else {
            completionHandler(nil, nil, RequestError.invalidParameters)
            return nil
        }
        let postRequest = request(with: url, method: .post, bodyParameters: bodyParameters, bodyEncoding: .form)
        let task = jsonDictionaryTask(with: postRequest, reattemptLoginOn401Response: reattemptLoginOn401Response, completionHandler: completionHandler)
        task.resume()
        return task
    }
}

// MARK: Modern Swift Concurrency APIs

extension Session {
    
    public func data(for url: URL) async throws -> (Data, URLResponse) {
        let request = request(with: url)
        return try await defaultURLSession.data(for: request)
    }
}

// MARK: PermanentlyPersistableURLCache Passthroughs

enum SessionPermanentCacheError: Error {
    case unexpectedURLCacheType
}

extension Session {
    
    @objc func imageInfoURLRequestFromPersistence(with url: URL) -> URLRequest? {
        return urlRequestFromPersistence(with: url, persistType: .imageInfo)
    }
    
    func urlRequestFromPersistence(with url: URL, persistType: Header.PersistItemType, cachePolicy: WMFCachePolicy? = nil, headers: [String: String] = [:]) -> URLRequest? {
        
        guard var permanentCacheRequest = permanentCache?.urlCache.urlRequestFromURL(url, type: persistType, cachePolicy: cachePolicy) else {
            return nil
        }
        
        let sessionRequest = request(with: url, method: .get, bodyParameters: nil, bodyEncoding: .json, headers: headers, cachePolicy: permanentCacheRequest.cachePolicy)
        
        if let headerFields = sessionRequest.allHTTPHeaderFields {
            for (key, value) in headerFields {
                permanentCacheRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        return permanentCacheRequest
    }
    
    public func typeHeadersForType(_ type: Header.PersistItemType) -> [String: String] {
        return permanentCache?.urlCache.typeHeadersForType(type) ?? [:]
    }
    
    public func additionalHeadersForType(_ type: Header.PersistItemType, urlRequest: URLRequest) -> [String: String] {
        return permanentCache?.urlCache.additionalHeadersForType(type, urlRequest: urlRequest) ?? [:]
    }
    
    func uniqueKeyForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        return permanentCache?.urlCache.uniqueFileNameForURL(url, type: type)
    }
    
    func isCachedWithURLRequest(_ urlRequest: URLRequest, completion: @escaping (Bool) -> Void) {
        guard let urlCache = permanentCache?.urlCache else {
            completion(false)
            return
        }
        urlCache.isCachedWithURLRequest(urlRequest, completion: completion)
    }
    
    func cachedResponseForURL(_ url: URL, type: Header.PersistItemType) -> CachedURLResponse? {
        
        guard let request = permanentCache?.urlCache.urlRequestFromURL(url, type: type) else {
            return nil
        }
        
        return cachedResponseForURLRequest(request)
    }
    
    // assumes urlRequest is already populated with the proper cache headers
    func cachedResponseForURLRequest(_ urlRequest: URLRequest) -> CachedURLResponse? {
        return permanentCache?.urlCache.cachedResponse(for: urlRequest)
    }
    
    func cacheResponse(httpUrlResponse: HTTPURLResponse, content: CacheResponseContentType, urlRequest: URLRequest, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        
        permanentCache?.urlCache.cacheResponse(httpUrlResponse: httpUrlResponse, content: content, urlRequest: urlRequest, success: success, failure: failure)
    }
    
    func uniqueFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        return permanentCache?.urlCache.uniqueFileNameForItemKey(itemKey, variant: variant)
    }
    
    func uniqueFileNameForURLRequest(_ urlRequest: URLRequest) -> String? {
        return permanentCache?.urlCache.uniqueFileNameForURLRequest(urlRequest)
    }
    
    func itemKeyForURLRequest(_ urlRequest: URLRequest) -> String? {
        return permanentCache?.urlCache.itemKeyForURLRequest(urlRequest)
    }
    
    func variantForURLRequest(_ urlRequest: URLRequest) -> String? {
        return permanentCache?.urlCache.variantForURLRequest(urlRequest)
    }
    
    func itemKeyForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        return permanentCache?.urlCache.itemKeyForURL(url, type: type)
    }
    
    func variantForURL(_ url: URL, type: Header.PersistItemType) -> String? {
        return permanentCache?.urlCache.variantForURL(url, type: type)
    }
    
    func uniqueHeaderFileNameForItemKey(_ itemKey: CacheController.ItemKey, variant: String?) -> String? {
        return permanentCache?.urlCache.uniqueHeaderFileNameForItemKey(itemKey, variant: variant)
    }
    
    // Bundled migration only - copies files into cache
    func writeBundledFiles(mimeType: String, bundledFileURL: URL, urlRequest: URLRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        
        permanentCache?.urlCache.writeBundledFiles(mimeType: mimeType, bundledFileURL: bundledFileURL, urlRequest: urlRequest, completion: completion)
    }
}


class SessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    let delegateDispatchQueue = DispatchQueue(label: "SessionDelegateDispatchQueue", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil) // needs to be serial according the docs for NSURLSession
    let delegateQueue: OperationQueue
    var callbacks: [Int: Session.Callback] = [:]
    
    override init() {
        delegateQueue = OperationQueue()
        delegateQueue.underlyingQueue = delegateDispatchQueue
    }
    
    func addCallback(callback: Session.Callback, for task: URLSessionTask) {
        delegateDispatchQueue.async {
            self.callbacks[task.taskIdentifier] = callback
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        defer {
            completionHandler(.allow)
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            
            var shouldCheckPersistentCache = false
            if httpResponse.statusCode == 304 {
                shouldCheckPersistentCache = true
            }
            
            if let request = dataTask.originalRequest,
                request.prefersPersistentCacheOverError &&
                !HTTPStatusCode.isSuccessful(httpResponse.statusCode) {
                shouldCheckPersistentCache = true
            }
            
            let taskIdentifier = dataTask.taskIdentifier
            if shouldCheckPersistentCache,
                let callback = callbacks[taskIdentifier],
                let request = dataTask.originalRequest,
                let cachedResponse = (session.configuration.urlCache as? PermanentlyPersistableURLCache)?.cachedResponse(for: request) {
                callback.response?(cachedResponse.response)
                callback.data?(cachedResponse.data)
                callback.success(true)
                
                if httpResponse.statusCode != 304 {
                    callback.cacheFallbackError?(RequestError.http(httpResponse.statusCode))
                }
                
                callbacks.removeValue(forKey: taskIdentifier)

                return
            }
        }
        
        guard let callback = callbacks[dataTask.taskIdentifier]?.response else {
            return
        }
        callback(response)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        guard let callback = callbacks[dataTask.taskIdentifier]?.data else {
            return
        }
        callback(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let callback = callbacks[task.taskIdentifier] else {
            return
        }
        
        defer {
            callbacks.removeValue(forKey: task.taskIdentifier)
        }
        
        if let error = error as NSError? {
            if error.domain != NSURLErrorDomain || error.code != NSURLErrorCancelled {
                
                if let request = task.originalRequest,
                request.prefersPersistentCacheOverError,
                let cachedResponse = (session.configuration.urlCache as? PermanentlyPersistableURLCache)?.cachedResponse(for: request) {
                    callback.response?(cachedResponse.response)
                    callback.data?(cachedResponse.data)
                    callback.success(true)
                    return
                }
                
                callback.failure(error)
            }
            return
        }
        
        callback.success(false)
    }
}
