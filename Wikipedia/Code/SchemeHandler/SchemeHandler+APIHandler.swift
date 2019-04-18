import Foundation

extension SchemeHandler {
    final class APIHandler: BaseSubHandler, RemoteSubHandler {
        
        let session: Session
        
        override class var basePath: String? {
            return "APIProxy"
        }
        
        required init(session: Session) {
            self.session = session
        }
        
        func urlForPathComponents(_ pathComponents: [String], requestURL: URL) -> URL? {
            guard pathComponents.count == 5 else {
                assertionFailure("Expected 5 components when using APIProxy base path")
                return nil
            }
            
            guard var apiProxyURLComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
                return nil
            }
            
            // APIURL is APIProxyURL with components[3] as the host, components[4..5] as the path.
            apiProxyURLComponents.path = NSString.path(withComponents: ["/", pathComponents[3], pathComponents[4]])
            apiProxyURLComponents.host = pathComponents[2]
            apiProxyURLComponents.scheme = "https"
            
            return apiProxyURLComponents.url
        }
        
        func dataTaskForURL(_ url: URL, callback: Session.Callback) -> URLSessionTask {
            
            var request = URLRequest(url: url)
            request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")
            
            let apiRequestTask = session.dataTask(with: request, callback: callback)
            apiRequestTask.priority = URLSessionTask.lowPriority
            return apiRequestTask
        }
    }
}
