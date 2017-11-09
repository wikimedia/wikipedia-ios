import Foundation



public class Session {
    public struct Request {
        public enum Method {
            case get
            case post
            case put
            
            var stringValue: String {
                switch self {
                case .post:
                    return "POST"
                case .put:
                    return "PUT"
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

    public static let shared = Session()
    
    fileprivate let session = URLSession.shared
    
    public func mediaWikiAPITask(host: String, scheme: String = "https", method: Session.Request.Method = .get, queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        return jsonDictionaryTask(host: host, scheme: scheme, method: method, path: WMFAPIPath, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: .form, completionHandler: completionHandler)
    }
    
    public func jsonDictionaryTask(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        if method == .post && queryParameters?["csrf_token"] == nil {
            return mediaWikiAPITask(host: host, queryParameters: ["action": "query", "meta": "tokens", "type": "csrf", "format": "json"]) { (result, response, error) in
                guard
                    let query = result?["query"] as? [String: Any],
                    let tokens = query["tokens"] as? [String: Any],
                    let token =  tokens["csrftoken"] as? String
                    else {
                        completionHandler(nil, nil, NSError.wmf_error(with: .unexpectedResponseType))
                        return
                }
                var newQueryParams = queryParameters ?? [:]
                newQueryParams["csrf_token"] = token
                _ = self.jsonDictionaryTask(host: host, scheme: scheme, method: method, path: path, queryParameters: newQueryParams, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, completionHandler: completionHandler)?.resume()
            }
        }

        
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        components.path = path
        
        if let queryParameters = queryParameters {
            var queryItems: [URLQueryItem] = []
            for (name, value) in queryParameters {
                queryItems.append(URLQueryItem(name: name, value: String(describing: value)))
            }
            components.queryItems = queryItems
        }
        
        guard let requestURL = components.url else {
            return nil
        }
        print("requesting: \(requestURL)")
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.stringValue
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
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
        return jsonDictionaryTask(with: request, completionHandler: completionHandler)
    }
    
    public func jsonDictionaryTask(with request: URLRequest, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, response, error)
                return
            }
            do {
                guard let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
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
    
    
    public func wmf_summaryTask(with articleURL: URL, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let siteURL = articleURL.wmf_site, let title = articleURL.wmf_titleWithUnderscores else {
            return nil
        }
        
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.wmf_urlPathComponentAllowed) ?? title
        let percentEncodedPath = NSString.path(withComponents: ["/api", "rest_v1", "page", "summary", encodedTitle])
        
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
    
    //@objc(fetchSummaryWithArticleURL:completionHandler:)
    public func fetchSummary(with articleURL: URL, completionHandler: @escaping ([String: Any]?, URLResponse?, Error?) -> Swift.Void) {
        guard let task = wmf_summaryTask(with: articleURL, completionHandler: completionHandler) else {
            completionHandler(nil, nil, NSError.wmf_error(with: .invalidRequestParameters))
            return
        }
        task.resume()
    }
}
