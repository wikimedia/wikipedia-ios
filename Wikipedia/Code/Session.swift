import Foundation

@objc(WMFSession) public class Session: NSObject {
    public struct Header {
        public static let persistentCacheItemKey = "Persistent-Cache-Item-Key"
        public static let persistentCacheItemVariant = "Persistent-Cache-Item-Variant"
        public static let persistentCacheItemType = "Persistent-Cache-Item-Type"
        public static let persistentCacheETag = "Persistent-Cache-ETag"
        
        public enum ItemType: String {
            case image = "Image"
            case article = "Article"
        }
    }
    public struct Request {
        public enum Method {
            case get
            case post
            case put
            case delete

            var stringValue: String {
                switch self {
                case .post:
                    return "POST"
                case .put:
                    return "PUT"
                case .delete:
                    return "DELETE"
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
        }
    }
    
    public struct Callback {
        let response: ((URLResponse) -> Void)?
        let data: ((Data) -> Void)?
        let success: (() -> Void)
        let failure: ((Error) -> Void)
        
        public init(response: ((URLResponse) -> Void)?, data: ((Data) -> Void)?, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
            self.response = response
            self.data = data
            self.success = success
            self.failure = failure
        }
    }
    
    public var xWMFUUID: String? = nil // event logging uuid, set if enabled, nil if disabled
    
    private static let defaultCookieStorage: HTTPCookieStorage = {
        let storage = HTTPCookieStorage.shared
        storage.cookieAcceptPolicy = .always
        return storage
    }()
    
    public func cloneCentralAuthCookies() {
        // centralauth_ cookies work for any central auth domain - this call copies the centralauth_* cookies from .wikipedia.org to an explicit list of domains. This is  hardcoded because we only want to copy ".wikipedia.org" cookies regardless of WMFDefaultSiteDomain
        defaultURLSession.configuration.httpCookieStorage?.copyCookiesWithNamePrefix("centralauth_", for: configuration.centralAuthCookieSourceDomain, to: configuration.centralAuthCookieTargetDomains)
        cacheQueue.async(flags: .barrier) {
            self._isAuthenticated = nil
        }
    }
    
    public func removeAllCookies() {
        guard let storage = defaultURLSession.configuration.httpCookieStorage else {
            return
        }
        // Cookie reminders:
        //  - "HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)" does NOT seem to work.
        storage.cookies?.forEach { cookie in
            storage.deleteCookie(cookie)
        }
        cacheQueue.async(flags: .barrier) {
            self._isAuthenticated = nil
        }
    }
    
    @objc public static var defaultConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = Session.defaultCookieStorage
        return config
    }
    
    @objc public static let urlSession: URLSession = {
        return URLSession(configuration: Session.defaultConfiguration, delegate: sessionDelegate, delegateQueue: sessionDelegate.delegateQueue)
    }()
    
    @objc public static func clearTemporaryCache() {
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }
    
    private static let sessionDelegate: SessionDelegate = {
        return SessionDelegate()
    }()
    
    private let configuration: Configuration
    
    public required init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    @objc public static let shared = Session(configuration: Configuration.current)
    
    public let defaultURLSession = Session.urlSession
    private let sessionDelegate = Session.sessionDelegate
    
    public let wifiOnlyURLSession: URLSession = {
        var config = Session.defaultConfiguration
        config.allowsCellularAccess = false
        return URLSession(configuration: config)
    }()
    
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

    private var cacheQueue = DispatchQueue(label: "session-cache-queue", qos: .default, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
    private var _isAuthenticated: Bool?
    @objc public var isAuthenticated: Bool {
        var read: Bool?
        cacheQueue.sync {
            read = _isAuthenticated
        }
        if let auth = read {
            return auth
        }
        let hasValid = hasValidCentralAuthCookies(for: configuration.centralAuthCookieSourceDomain)
        cacheQueue.async(flags: .barrier) {
            self._isAuthenticated = hasValid
        }
        return hasValid
    }
    
    @objc(requestToGetURL:)
    public func request(toGET requestURL: URL?) -> URLRequest? {
        guard let requestURL = requestURL else {
            return nil
        }
        return request(with: requestURL, method: .get)
    }

    public func request(with requestURL: URL, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:]) -> URLRequest? {
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.stringValue
        let defaultHeaders = [
            "Accept": "application/json; charset=utf-8",
            "Accept-Encoding": "gzip",
            "User-Agent": WikipediaAppUtils.versionedUserAgent(),
            "Accept-Language": NSLocale.wmf_acceptLanguageHeaderForPreferredLanguages
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
        guard let bodyParameters = bodyParameters else {
            return request
        }
        
        switch bodyEncoding {
        case .json:
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyParameters, options: [])
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            } catch let error {
                DDLogError("error serializing JSON: \(error)")
            }
        case .form:
            guard let bodyParametersDictionary = bodyParameters as? [String: Any] else {
                break
            }
            let queryString = URLComponents.percentEncodedQueryStringFrom(bodyParametersDictionary)
            request.httpBody = queryString.data(using: String.Encoding.utf8)
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
    
    @discardableResult public func jsonDictionaryTask(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let url = url else {
            return nil
        }
        guard let request = request(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding) else {
            return nil
        }
        return jsonDictionaryTask(with: request, completionHandler: completionHandler)
    }
    
    public func dataTask(with request: URLRequest, callback: Callback) -> URLSessionTask? {
        
        if request.cachePolicy == .returnCacheDataElseLoad,
            let cachedResponse = sessionDelegate.responseFromPersistentCacheOrFallbackIfNeeded(request: request) {
            callback.response?(cachedResponse.response)
            callback.data?(cachedResponse.data)
            callback.success()
            return nil
        }

        let task = defaultURLSession.dataTask(with: request)
        sessionDelegate.addCallback(callback: callback, for: task)
        return task
    }
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        let task = defaultURLSession.dataTask(with: request, completionHandler: completionHandler)
        return task
    }
    
    //tonitodo: utlilize Callback & addCallback/session delegate stuff instead of completionHandler
    public func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return defaultURLSession.downloadTask(with: url, completionHandler: completionHandler)
    }

    public func downloadTask(with urlRequest: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask? {
        
        if urlRequest.cachePolicy == .returnCacheDataElseLoad,
            let cachedResponse = sessionDelegate.responseFromPersistentCacheOrFallbackIfNeeded(request: urlRequest) {
            completionHandler(nil, cachedResponse.response, nil)
            return nil
        }
        
        return defaultURLSession.downloadTask(with: urlRequest, completionHandler: completionHandler)
    }
    
    public func dataTask(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let url = url else {
            return nil
        }
        guard let request = request(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, headers: headers) else {
            return nil
        }
        
        let task = defaultURLSession.dataTask(with: request, completionHandler: completionHandler)
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
        
        let logout = {
            WMFAuthenticationManager.sharedInstance.logout(initiatedBy: .server) {
                self.removeAllCookies()
            }
        }
        switch httpResponse.statusCode {
        case 401:
            if (reattemptLoginOn401Response) {
                WMFAuthenticationManager.sharedInstance.attemptLogin(reattemptOn401Response: false) { (loginResult) in
                    switch loginResult {
                    case .failure(let error):
                        DDLogDebug("\n\nloginWithSavedCredentials failed with error \(error).\n\n")
                        logout()
                    default:
                        break
                    }
                }
            } else {
                logout()
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
    @discardableResult public func jsonDecodableTaskWithDecodableError<T: Decodable, E: Decodable>(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping (_ result: T?, _ errorResult: E?, _ response: URLResponse?, _ error: Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let task = dataTask(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, completionHandler: { (data, response, error) in
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
//            #if DEBUG
//                let stringData = String(data: data, encoding: .utf8)
//                DDLogDebug("codable response:\n\(String(describing:response?.url)):\n\(String(describing: stringData))")
//            #endif
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
     - completionHandler: Called after the request completes
     - result: The result object decoded from JSON
     - response: The URLResponse
     - error: Any network or parsing error
     */
    @discardableResult public func jsonDecodableTask<T: Decodable>(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (_ result: T?, _ response: URLResponse?,  _ error: Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let task = dataTask(with: url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, headers: headers, priority: priority, completionHandler: { (data, response, error) in
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
        return defaultURLSession.dataTask(with: request, completionHandler: { (data, response, error) in
            self.handleResponse(response, reattemptLoginOn401Response: reattemptLoginOn401Response)
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
        guard var request = self.request(with: url, method: .get) else {
            completionHandler(nil, nil, RequestError.invalidParameters)
            return nil
        }
        if ignoreCache {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        let task = jsonDictionaryTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }
    
    @objc(postFormEncodedBodyParametersToURL:bodyParameters:reattemptLoginOn401Response:completionHandler:)
    @discardableResult public func postFormEncodedBodyParametersToURL(to url: URL?, bodyParameters: [String: String]? = nil, reattemptLoginOn401Response: Bool = true, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        guard let url = url else {
            completionHandler(nil, nil, RequestError.invalidParameters)
            return nil
        }
        guard let request = self.request(with: url, method: .post, bodyParameters: bodyParameters, bodyEncoding: .form) else {
            completionHandler(nil, nil, RequestError.invalidParameters)
            return nil
        }
        let task = jsonDictionaryTask(with: request, reattemptLoginOn401Response: reattemptLoginOn401Response, completionHandler: completionHandler)
        task.resume()
        return task
    }
}

class SessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    let delegateDispatchQueue = DispatchQueue(label: "SessionDelegateDispatchQueue", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil) // needs to be serial according the docs for NSURLSession
    let delegateQueue: OperationQueue
    var callbacks: [Int: Session.Callback] = [:]
    private let cacheManagedObjectContext = CacheController.backgroundCacheContext //tonitodo: This is not very flexible
    
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
        
        if let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 304 { //catches errors and 304 Not Modified
            
            let taskIdentifier = dataTask.taskIdentifier
            if let callback = callbacks[taskIdentifier],
                let request = dataTask.originalRequest,
                let cachedResponse = responseFromPersistentCacheOrFallbackIfNeeded(request: request) {
                callback.response?(cachedResponse.response)
                callback.data?(cachedResponse.data)
                callback.success()
                callbacks.removeValue(forKey: taskIdentifier)
            }
        }

        defer {
            completionHandler(.allow)
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
                
                if let request = task.currentRequest,
                let cachedResponse = responseFromPersistentCacheOrFallbackIfNeeded(request: request) {
                    callback.response?(cachedResponse.response)
                    callback.data?(cachedResponse.data)
                    callback.success()
                    return
                } else {
                    callback.failure(error)
                }
            }
            return
        }
        
        callback.success()
    }
}

extension SessionDelegate {
    func responseFromPersistentCacheOrFallbackIfNeeded(request: URLRequest) -> CachedURLResponse? {
        
        //1. first try pulling from URLCache
        if let response = URLCache.shared.cachedResponse(for: request) {
            return response
        }
        
        guard let url = request.url,
            let itemKey = request.allHTTPHeaderFields?[Session.Header.persistentCacheItemKey] else {
            return nil
        }
        
        let variant = request.allHTTPHeaderFields?[Session.Header.persistentCacheItemVariant]
        let itemTypeRaw = request.allHTTPHeaderFields?[Session.Header.persistentCacheItemType] ?? Session.Header.ItemType.article.rawValue
        let itemType = Session.Header.ItemType(rawValue: itemTypeRaw) ?? Session.Header.ItemType.article
        
        let cacheKeyGenerator: CacheKeyGenerating.Type
        switch itemType {
            case Session.Header.ItemType.image:
                cacheKeyGenerator = ImageCacheKeyGenerator.self
            case Session.Header.ItemType.article:
                cacheKeyGenerator = ArticleCacheKeyGenerator.self
        }
        
        //2. else try pulling from Persistent Cache
        if let persistedCachedResponse = CacheProviderHelper.persistedCacheResponse(url: url, itemKey: itemKey, variant: variant, cacheKeyGenerator: cacheKeyGenerator) {
            return persistedCachedResponse
        //3. else try pulling a fallback from Persistent Cache
        } else if let moc = cacheManagedObjectContext,
            let fallbackCachedResponse = CacheProviderHelper.fallbackCacheResponse(url: url, itemKey: itemKey, variant: variant, itemType: itemType, cacheKeyGenerator: cacheKeyGenerator, moc: moc) {
            return fallbackCachedResponse
        }
        
        return nil
    }
}
