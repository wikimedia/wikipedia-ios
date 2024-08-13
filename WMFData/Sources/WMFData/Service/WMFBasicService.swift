import Foundation

/// Use this service for the most basic networking service calls. It does not handle authentication.
public final class WMFBasicService: WMFService {
    
    private let urlSession: WMFURLSession
    
    init(urlSession: WMFURLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        
        let completion: ((Data?, URLResponse?, Error?) -> Void) = { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data,
                  !data.isEmpty else {
                completion(.failure(WMFServiceError.missingData))
                return
            }
            
            completion(.success(data))
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
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        
        let completion: ((Result<Data, any Error>) -> Void) = { result in
            switch result {
            case .success(let data):
                
                do {
                    let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    completion(.success(dictionary))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        perform(request: request, completion: completion)
    }
    
    private func performPOST<R: WMFServiceRequest>(request: R, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        guard let basicRequest = request as? WMFBasicServiceRequest,
              let url = request.url,
              request.method == .POST else {
            completion(nil, nil, WMFServiceError.invalidRequest)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        
        if let contentType = basicRequest.contentType {
            switch contentType {
            case .form:
                
                if let encodedParameters = request.parameters?.encodedForAPI() {
                    var body = ""
                    let sortedParameters = encodedParameters.sorted( by: { $0.0 < $1.0 })
                    for (key, value) in sortedParameters {
                        
                        if body != "" {
                            body.append("&")
                        }
                        
                        body.append("\(key)=\(value)")
                    }
                    urlRequest.httpBody = body.data(using: String.Encoding.utf8)
                }
                
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                urlRequest.populateCommonHeaders(request: basicRequest)
            case .json:
                
                do {
                    if let encodedParameters = request.parameters?.encodedForAPI() {
                        let sortedParameters = encodedParameters.sorted( by: { $0.0 < $1.0 })
                        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: sortedParameters as Any, options: [])
                    }
                } catch let error {
                    completion(nil, nil, error)
                    return
                }
                
                urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                urlRequest.populateCommonHeaders(request: basicRequest)
            }
        }
        
        let task = urlSession.wmfDataTask(with: urlRequest) { data, response, error in
            
            if let error {
                completion(nil, nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, nil, WMFServiceError.invalidHttpResponse(nil))
                return
            }
            
            guard httpResponse.isSuccessStatusCode else {
                completion(nil, nil, WMFServiceError.invalidHttpResponse(httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                completion(nil, nil, WMFServiceError.missingData)
                return
            }
            
            completion(data, response, error)
        }
        task.resume()
    }
    
    private func performGET<R: WMFServiceRequest>(request: R, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
         
        guard let basicRequest = request as? WMFBasicServiceRequest,
              let url = request.url,
              request.method == .GET else {
            completion(nil, nil, WMFServiceError.invalidRequest)
            return
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let parameters = request.parameters?.encodedForAPI() {
            let sortedParameters = parameters.sorted( by: { $0.0 < $1.0 })
            var queryItems: [URLQueryItem] = []
            for (name, value) in sortedParameters {
                
                guard let valueString = value as? String else {
                    continue
                }
                
                queryItems.append(URLQueryItem(name: name, value: valueString))
            }
            components?.percentEncodedQueryItems = queryItems.sorted { $0.name < $1.name }
        }
        
        guard let url = components?.url else {
            completion(nil, nil, WMFServiceError.invalidRequest)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.populateCommonHeaders(request: basicRequest)
        
        let task = urlSession.wmfDataTask(with: urlRequest) { data, response, error in
            
            if let error {
                completion(nil, nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, nil, WMFServiceError.invalidHttpResponse(nil))
                return
            }
            
            guard httpResponse.isSuccessStatusCode else {
                completion(nil, nil, WMFServiceError.invalidHttpResponse(httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                completion(nil, nil, WMFServiceError.missingData)
                return
            }
            
            completion(data, response, error)
        }
        task.resume()
    }
    
    public func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        performGET(request: request) { data, response, error in
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data else {
                completion(.failure(WMFServiceError.missingData))
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
    
    public func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        performPOST(request: request) { data, response, error in
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data else {
                completion(.failure(WMFServiceError.missingData))
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

private extension URLRequest {
    mutating func populateCommonHeaders(request: WMFBasicServiceRequest) {
        if let userAgent = WMFDataEnvironment.current.userAgentUtility?() {
            setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        
        if let appInstallID = WMFDataEnvironment.current.appInstallIDUtility?() {
            setValue(appInstallID, forHTTPHeaderField: "X-WMF-UUID")
        }
        
        let acceptLanguage = request.languageVariantCode ?? WMFDataEnvironment.current.acceptLanguageUtility?()
        if let acceptLanguage {
            setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
        }
        
        switch request.acceptType {
        case .json:
            setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        case .none:
            setValue("*/*", forHTTPHeaderField: "Accept")
        }
    }
}
