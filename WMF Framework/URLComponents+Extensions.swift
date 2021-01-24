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
    
    public static func percentEncodedQueryStringFrom(_ queryParameters: [String: Any]) -> String {
        var query = ""
        
        //sort query parameters by key, this allows for consistency when itemKeys are generated for the persistent cache.
        struct KeyValue {
            let key: String
            let value: Any
        }
        
        var unorderedKeyValues: [KeyValue] = []
        
        for (name, value) in queryParameters {
            
            unorderedKeyValues.append(KeyValue(key: name, value: value))
        }
        
        let orderedKeyValues = unorderedKeyValues.sorted { (lhs, rhs) -> Bool in
            return lhs.key < rhs.key
        }
        
        for keyValue in orderedKeyValues {
            guard
                let encodedName = keyValue.key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryComponentAllowed),
                let encodedValue = String(describing: keyValue.value).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryComponentAllowed) else {
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
        newPEQ = newPEQ + URLComponents.percentEncodedQueryStringFrom(queryParameters)
        percentEncodedQuery = newPEQ
    }
    
    mutating func replacePercentEncodedQueryWithQueryParameters(_ queryParameters: [String: Any]?) {
        guard let queryParameters = queryParameters else {
            percentEncodedQuery = nil
            return
        }
        percentEncodedQuery = URLComponents.percentEncodedQueryStringFrom(queryParameters)
    }
    
    mutating func replacePercentEncodedPathWithPathComponents(_ pathComponents: [String]?) {
        guard let pathComponents = pathComponents else {
            percentEncodedPath = "/"
            return
        }
        let fullComponents = [""] + pathComponents
        #if DEBUG
        for component in fullComponents {
            assert(!component.contains("/"))
        }
        #endif
        percentEncodedPath = fullComponents.joined(separator: "/") // NSString.path(with: components) removes the trailing slash that the reading list API needs
    }
    
    public func wmf_URLWithLanguageVariantCode(_ code: String?) -> URL? {
        return (self as NSURLComponents).wmf_URL(withLanguageVariantCode: code)
    }

}
