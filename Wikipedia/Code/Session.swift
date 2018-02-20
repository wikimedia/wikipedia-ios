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
        return dataTask(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, completionHandler: { (data, response, error) in
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
        })
    }
}
