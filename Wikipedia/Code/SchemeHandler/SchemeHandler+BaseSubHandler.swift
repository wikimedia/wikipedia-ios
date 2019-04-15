import Foundation

extension SchemeHandler {
    class BaseSubHandler {
        
        class var basePath: String? {
            fatalError("Subclasses must implement basePath)")
        }
        
        static var baseUrlComponents: URLComponents {
            var components = URLComponents()
            components.scheme = SchemeHandler.defaultScheme
            components.host = "host"
            return components
        }
        
        static func appSchemeUrl(for path: String, fragment: String?) -> URL? {
            
            guard let basePath = basePath else {
                return nil
            }
            
            var components = baseUrlComponents
            components.path = NSString.path(withComponents: ["/", basePath, path])
            components.fragment = fragment
            return components.url
        }
    }
}
