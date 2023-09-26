import Foundation

/// Use this service for the most basic networking service calls. It does not handle authentication.
///
public final class WKBasicService: WKService {
    
    private let urlSession: WKURLSession
    init(urlSession: WKURLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    public func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        
        let completion: ((Data?, URLResponse?, Error?) -> Void) = { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data else {
                completion(.failure(WKServiceError.missingData))
                return
            }
            
            if data.isEmpty {
                completion(.failure(WKServiceError.missingData))
                return
            }
            
            do {
                let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                completion(.success(dictionary))
            } catch let error {
                completion(.failure(error))
            }
        }
        
        switch request.method {
        case .GET:
            performGET(request: request, completion: completion)
        case .POST:
            performPOST(request: request, completion: completion)
        default:
            assertionFailure("Unhandled request method")
        }
    }
    
    private func performPOST<R: WKServiceRequest>(request: R, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        guard let url = request.url,
              request.method == .POST else {
            completion(nil, nil, WKServiceError.invalidRequest)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        
        if let bodyContentType = request.bodyContentType {
            switch bodyContentType {
            case .form:
                
                if let encodedParameters = request.parameters?.encodedForAPI() {
                    var body = ""
                    for (key, value) in encodedParameters {
                        
                        if body != "" {
                            body.append("&")
                        }
                        
                        body.append("\(key)=\(value)")
                    }
                    urlRequest.httpBody = body.data(using: String.Encoding.utf8)
                }
                
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            case .json:
                
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request.parameters as Any, options: [])
                } catch let error {
                    completion(nil, nil, error)
                    return
                }
                
                urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
        }
        
        let task = urlSession.wkDataTask(with: urlRequest) { data, response, error in
            
            if let error {
                completion(nil, nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, nil, WKServiceError.invalidHttpResponse(nil))
                return
            }
            
            guard httpResponse.isSuccessStatusCode else {
                completion(nil, nil, WKServiceError.invalidHttpResponse(httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                completion(nil, nil, WKServiceError.missingData)
                return
            }
            
            completion(data, response, error)
        }
        task.resume()
    }
    
    private func performGET<R: WKServiceRequest>(request: R, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
         
        guard let url = request.url,
              request.method == .GET else {
            completion(nil, nil, WKServiceError.invalidRequest)
            return
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let parameters = request.parameters?.encodedForAPI() {
            var queryItems: [URLQueryItem] = []
            for (name, value) in parameters {
                
                guard let valueString = value as? String else {
                    continue
                }
                
                queryItems.append(URLQueryItem(name: name, value: valueString))
            }
            components?.percentEncodedQueryItems = queryItems.sorted { $0.name < $1.name }
        }
        
        guard let url = components?.url else {
            completion(nil, nil, WKServiceError.invalidRequest)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let task = urlSession.wkDataTask(with: urlRequest) { data, response, error in
            
            if let error {
                completion(nil, nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, nil, WKServiceError.invalidHttpResponse(nil))
                return
            }
            
            guard httpResponse.isSuccessStatusCode else {
                completion(nil, nil, WKServiceError.invalidHttpResponse(httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                completion(nil, nil, WKServiceError.missingData)
                return
            }
            
            completion(data, response, error)
        }
        task.resume()
    }
    
    public func performDecodableGET<R: WKServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        performGET(request: request) { data, response, error in
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data else {
                completion(.failure(WKServiceError.missingData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result: T = try decoder.decode(T.self, from: data)
                completion(.success(result))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    public func performDecodablePOST<R: WKServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        performPOST(request: request) { data, response, error in
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data else {
                completion(.failure(WKServiceError.missingData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result: T = try decoder.decode(T.self, from: data)
                completion(.success(result))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}
