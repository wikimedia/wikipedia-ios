import Foundation

public class Session {
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

    public static let shared = Session()

    fileprivate let session = URLSession.shared

    public func mediaWikiAPITask(host: String, scheme: String = "https", method: Session.Request.Method = .get, queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        return jsonDictionaryTask(host: host, scheme: scheme, method: method, path: WMFAPIPath, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: .form, completionHandler: completionHandler)
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
    
    public func jsonDictionaryTask(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let request = request(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding) else {
            return nil
        }
        return session.wmf_jsonDictionaryTask(with: request, completionHandler: { (result, response, error) in
            completionHandler(result, response as? HTTPURLResponse, error)
        })
    }
    
    public func dataTask(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        guard let request = request(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding) else {
            return nil
        }
        return session.dataTask(with: request, completionHandler: completionHandler)
    }
    
    public func jsonCodableTask<T>(host: String, scheme: String = "https", method: Session.Request.Method = .get, path: String = "/", queryParameters: [String: Any]? = nil, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, completionHandler: @escaping (T?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? where T : Decodable {
        return dataTask(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, response, error)
                return
            }
            #if DEBUG
                let stringData = String(data: data, encoding: .utf8)
                DDLogDebug("codable response:\n\(String(describing:response?.url)):\n\(String(describing: stringData))")
            #endif
            let decoder = JSONDecoder()
            do {
                let result: T = try decoder.decode(T.self, from: data)
                completionHandler(result, response, error)
            } catch let error {
                completionHandler(nil, response, error)
            }
        })
    }
}
