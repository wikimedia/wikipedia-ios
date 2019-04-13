import Foundation

extension SchemeHandler {
    final class APIHandler: BaseSubHandler {
        
        let session: Session
        
        override class var basePath: String? {
            return "APIProxy"
        }
        
        required init(session: Session) {
            self.session = session
        }
        
        func dataTaskForPathComponents(_ pathComponents: [String], requestUrl: URL, callback: Session.Callback) -> (error: Error?, task: URLSessionTask?) {
            guard pathComponents.count == 5 else {
                assertionFailure("Expected 5 components when using WMFAppSchemeAPIBasePath")
                return (SchemeHandlerError.invalidParameters, nil)
            }
            
            guard var apiProxyUrlComponents = URLComponents(url: requestUrl, resolvingAgainstBaseURL: false) else {
                return (SchemeHandlerError.invalidParameters, nil)
            }
            // APIURL is APIProxyURL with components[3] as the host, components[4..5] as the path.
            apiProxyUrlComponents.path = NSString.path(withComponents: [pathComponents[3], pathComponents[4]])
            apiProxyUrlComponents.host = pathComponents[2]
            apiProxyUrlComponents.scheme = "https"
            
            guard let apiUrl = apiProxyUrlComponents.url else {
                return (SchemeHandlerError.invalidParameters, nil)
            }
            
            var request = URLRequest(url: apiUrl)
            request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")
            
            let apiRequestTask = session.dataTask(with: request, callback: callback)
            apiRequestTask.priority = URLSessionTask.lowPriority
            return (nil, apiRequestTask)
        }
    }
}
