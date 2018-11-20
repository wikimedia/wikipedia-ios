import Foundation

extension URLComponents {
     static func with(host: String, scheme: String = "https", path: String = "/", queryParameters: [String: Any]? = nil) -> URLComponents {
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        components.path = path
        components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
        return components
    }
    
    private func percentEncodedQueryStringFrom(_ queryParameters: [String: Any]) -> String {
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
        return query
    }
    
    mutating func appendQueryParametersToPercentEncodedQuery(_ queryParameters: [String: Any]?) {
        guard let queryParameters = queryParameters else {
            return
        }
        var newPEQ = ""
        if let existing = percentEncodedQuery {
            newPEQ = existing + "&"
        }
        newPEQ = newPEQ + percentEncodedQueryStringFrom(queryParameters)
        percentEncodedQuery = newPEQ
    }
    
    mutating func replacePercentEncodedQueryWithQueryParameters(_ queryParameters: [String: Any]?) {
        guard let queryParameters = queryParameters else {
            percentEncodedQuery = nil
            return
        }
        percentEncodedQuery = percentEncodedQueryStringFrom(queryParameters)
    }
    
    mutating func replacePercentEncodedPathWithPathComponents(_ pathComponents: [String]?) {
        guard let pathComponents = pathComponents else {
            percentEncodedPath = "/"
            return
        }
        let characterSet = NSCharacterSet.wmf_URLPathComponentAllowed() ?? CharacterSet.urlPathAllowed
        let encodedPathComponents = ([""] + pathComponents).compactMap { (component) -> String? in
            assert(!component.contains("/"))
            return component.addingPercentEncoding(withAllowedCharacters: characterSet)
        }
        percentEncodedPath = encodedPathComponents.joined(separator: "/") // NSString.path(with: components) removes the trailing slash that the reading list API needs
    }
}
