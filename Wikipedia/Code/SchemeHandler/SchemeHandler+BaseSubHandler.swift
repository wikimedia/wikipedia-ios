import Foundation

extension SchemeHandler {
    class BaseSubHandler {
        
        class var basePath: String? {
            fatalError("Subclasses must implement basePath)")
        }
        
        static var baseURLComponents: URLComponents {
            var components = URLComponents()
            components.scheme = WMFURLSchemeHandlerScheme
            components.host = "host"
            return components
        }
        
        static func appSchemeURL(for path: String, fragment: String?) -> URL? {
            
            guard let basePath = basePath else {
                return nil
            }
            
            var components = baseURLComponents
            components.path = NSString.path(withComponents: ["/", basePath, path])
            components.fragment = fragment
            return components.url
        }
    }
}
