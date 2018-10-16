import Foundation

@objc(WMFSession) public class Session: NSObject {
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
    
    private static let defaultCookieStorage: HTTPCookieStorage = {
        let storage = HTTPCookieStorage.shared
        storage.cookieAcceptPolicy = .always
        return storage
    }()
    
    public func cloneCentralAuthCookies() {
        // centralauth_ cookies work for any central auth domain - this call copies the centralauth_* cookies from .wikipedia.org to an explicit list of domains. This is  hardcoded because we only want to copy ".wikipedia.org" cookies regardless of WMFDefaultSiteDomain
        defaultURLSession.configuration.httpCookieStorage?.copyCookiesWithNamePrefix("centralauth_", for: ".wikipedia.org", to: [".wikidata.org", ".mediawiki.org"])
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
    }
    
    @objc public static var defaultConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = Session.defaultCookieStorage
        return config
    }
    
    @objc public static let urlSession: URLSession = {
        return URLSession(configuration: Session.defaultConfiguration)
    }()
    
    @objc public static let shared = Session()
    
    public let defaultURLSession = Session.urlSession
    
    public let wifiOnlyURLSession: URLSession = {
        var config = Session.defaultConfiguration
        config.allowsCellularAccess = false
        return URLSession(configuration: config)
    }()
    
    private lazy var tokenFetcher: WMFAuthTokenFetcher = {
        return WMFAuthTokenFetcher()
    }()
    
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 16
        return queue
    }()

    public func mediaWikiAPITask(host: String, scheme: String = "https", method: Session.Request.Method = .get, queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Bool?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        return jsonDictionaryTask(host: host, scheme: scheme, method: method, path: WMFAPIPath, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: .form, completionHandler: completionHandler)
    }
    
    public func requestWithCSRF<R, O: CSRFTokenOperation<R>>(type operationType: O.Type, scheme: String, host: String, path: String, method: Session.Request.Method, queryParameters: [String: Any]? = [:], bodyParameters: [String: Any]? = [:], bodyEncoding: Session.Request.Encoding = .json, tokenContext: CSRFTokenOperation<R>.TokenContext, completion: @escaping (R?, URLResponse?, Bool?, Error?) -> Void) -> Operation {
        let op = operationType.init(session: self, tokenFetcher: tokenFetcher, scheme: scheme, host: host, path: path, method: method, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, tokenContext: tokenContext, completion: completion)
        queue.addOperation(op)
        return op
    }

    public func request(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json) -> URLRequest? {
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        components.path = path
        
        if let queryParameters = queryParameters {
            var query = ""
            for (name, value) in queryParameters {
                guard
                    let encodedName = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.wmf_urlQueryAllowed),
                    let encodedValue = String(describing: value).addingPercentEncoding(withAllowedCharacters: CharacterSet.wmf_urlQueryAllowed) else {
                        continue
                }
                if query != "" {
                    query.append("&")
                }
                
                query.append("\(encodedName)=\(encodedValue)")
            }
            components.percentEncodedQuery = query
        }
        
        guard let requestURL = components.url else {
            return nil
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.stringValue
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")
        if let parameters = bodyParameters {
            if bodyEncoding == .json {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                } catch let error {
                    DDLogError("error serializing JSON: \(error)")
                }
            } else {
                if let queryParams = parameters as? [String: Any] {
                    var bodyComponents = URLComponents()
                    var queryItems: [URLQueryItem] = []
                    for (name, value) in queryParams {
                        queryItems.append(URLQueryItem(name: name, value: String(describing: value)))
                    }
                    bodyComponents.queryItems = queryItems
                    if let query = bodyComponents.query {
                        request.httpBody = query.data(using: String.Encoding.utf8)
                        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    }
                }
                
            }
            
        }
        
        return request
    }
    
    public func jsonDictionaryTask(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, authorized: Bool? = nil, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Bool?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let request = request(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding) else {
            return nil
        }
        return jsonDictionaryTask(with: request, completionHandler: { (result, response, error) in
            completionHandler(result, response as? HTTPURLResponse, authorized, error)
        })
    }
    
    public func dataTask(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let request = request(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding) else {
            return nil
        }
        return defaultURLSession.dataTask(with: request, completionHandler: completionHandler)
    }
    
    /**
     Creates a URLSessionTask that will handle the response by decoding it to the codable type T. If the response isn't 200, or decoding to T fails, it'll attempt to decode the response to codable type E (typically an error response).
     - parameters:
         - host: The host for the request
         - scheme: The scheme for the request
         - method: The HTTP method for the request
         - path: The path for the request
         - queryParameters: The query parameters for the request
         - bodyParameters: The body parameters for the request
         - bodyEncoding: The body encoding for the request body parameters
         - completionHandler: Called after the request completes
         - result: The result object decoded from JSON
         - errorResult: The error result object decoded from JSON
         - response: The URLResponse
         - error: Any network or parsing error
     */
    public func jsonCodableTask<T, E>(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping (_ result: T?, _ errorResult: E?, _ response: URLResponse?, _ error: Error?) -> Swift.Void) -> URLSessionDataTask? where T : Decodable, E : Decodable {
        guard let task = dataTask(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, nil, response, error)
                return
            }
            let decoder = JSONDecoder()
            let handleErrorResponse = {
                do {
                    let errorResult: E = try decoder.decode(E.self, from: data)
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
                let result: T = try decoder.decode(T.self, from: data)
                completionHandler(result, nil, response, error)
            } catch let resultParsingError {
                DDLogError("Error parsing codable response: \(resultParsingError)")
                handleErrorResponse()
            }
        }) else {
            return nil
        }
        let op = URLSessionTaskOperation(task: task)
        queue.addOperation(op)
        return task
    }

    public func jsonDecodableTask<T: Decodable>(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, authorized: Bool? = nil, completionHandler: @escaping (_ result: T?, _ response: URLResponse?,_ authorized: Bool?,  _ error: Error?) -> Swift.Void) {
        guard let task = dataTask(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, response, authorized, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completionHandler(nil, response, authorized, nil)
                return
            }
            do {
                let decoder = JSONDecoder()
                let result: T = try decoder.decode(T.self, from: data)
                completionHandler(result, response, authorized, error)
            } catch let resultParsingError {
                DDLogError("Error parsing codable response: \(resultParsingError)")
                completionHandler(nil, response, authorized, resultParsingError)
            }
        }) else {
            return
        }
        let op = URLSessionTaskOperation(task: task)
        queue.addOperation(op)
    }
    
    @objc public func jsonDictionaryTask(with request: URLRequest, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        return defaultURLSession.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, response, error)
                return
            }
            do {
                guard data.count > 0, let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completionHandler(nil, response, nil)
                    return
                }
                completionHandler(responseObject, response, nil)
            } catch let error {
                DDLogError("Error parsing JSON: \(error)")
                completionHandler(nil, response, error)
            }
        })
    }
    
    public func apiTask(with articleURL: URL, path: String, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let siteURL = articleURL.wmf_site, let title = articleURL.wmf_titleWithUnderscores else {
            return nil
        }
        
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.wmf_urlPathComponentAllowed) ?? title
        let percentEncodedPath = NSString.path(withComponents: ["/api", "rest_v1", path, encodedTitle])
        guard var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.percentEncodedPath = percentEncodedPath
        guard let summaryURL = components.url else {
            return nil
        }
        
        var request = URLRequest(url: summaryURL)
        //The accept profile is case sensitive https://gerrit.wikimedia.org/r/#/c/356429/
        request.setValue("application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Summary/1.1.2\"", forHTTPHeaderField: "Accept")
        return jsonDictionaryTask(with: request, completionHandler: completionHandler)
    }
    
    @objc(fetchAPIPath:withArticleURL:priority:completionHandler:)
    public func fetchAPI(path: String, with articleURL: URL, priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) {
        guard let task = apiTask(with: articleURL, path: path, completionHandler: completionHandler) else {
            completionHandler(nil, nil, NSError.wmf_error(with: .invalidRequestParameters))
            return
        }
        task.priority = priority
        let operation = URLSessionTaskOperation(task: task)
        queue.addOperation(operation)
    }
    
    @objc(fetchMediaForArticleURL:priority:completionHandler:)
    public func fetchMedia(for articleURL: URL, priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) {
        return fetchAPI(path: "page/media", with: articleURL, completionHandler: completionHandler)
    }
    
    @objc(fetchSummaryForArticleURL:priority:completionHandler:)
    public func fetchSummary(for articleURL: URL, priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) {
        return fetchAPI(path: "page/summary", with: articleURL, completionHandler: completionHandler)
    }
    
    public func fetchArticleSummaryResponsesForArticles(withURLs articleURLs: [URL], priority: Float = URLSessionTask.defaultPriority, completion: @escaping ([String: [String: Any]]) -> Void) {
        let queue = DispatchQueue(label: "ArticleSummaryFetch-" + UUID().uuidString)
        let taskGroup = WMFTaskGroup()
        var summaryResponses: [String: [String: Any]] = [:]
        for articleURL in articleURLs {
            guard let key = articleURL.wmf_articleDatabaseKey else {
                continue
            }
            taskGroup.enter()
            fetchSummary(for: articleURL, priority: priority, completionHandler: { (responseObject, response, error) in
                guard let responseObject = responseObject else {
                    taskGroup.leave()
                    return
                }
                queue.async {
                    summaryResponses[key] = responseObject
                    taskGroup.leave()
                }
            })
        }
        
        taskGroup.waitInBackgroundAndNotify(on: queue) {
            completion(summaryResponses)
        }
    }
    
    @objc public var shouldSendUsageReports: Bool = false {
        didSet {
            guard shouldSendUsageReports, let appInstallID = EventLoggingService.shared?.appInstallID else {
                return
            }
            defaultURLSession.configuration.httpAdditionalHeaders = ["X-WMF-UUID": appInstallID]
        }
    }
    
}
