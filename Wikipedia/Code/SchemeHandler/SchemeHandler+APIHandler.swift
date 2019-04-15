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
        
        func urlForPathComponents(_ pathComponents: [String], requestUrl: URL) -> URL? {
            guard pathComponents.count == 5 else {
                assertionFailure("Expected 5 components when using APIProxy base path")
                return nil
            }
            
            guard var apiProxyUrlComponents = URLComponents(url: requestUrl, resolvingAgainstBaseURL: false) else {
                return nil
            }
            
            // APIURL is APIProxyURL with components[3] as the host, components[4..5] as the path.
            apiProxyUrlComponents.path = NSString.path(withComponents: [pathComponents[3], pathComponents[4]])
            apiProxyUrlComponents.host = pathComponents[2]
            apiProxyUrlComponents.scheme = "https"
            
            return apiProxyUrlComponents.url
        }
        
        func dataTaskForUrl(_ url: URL, callback: Session.Callback) -> URLSessionTask {
            
            var request = URLRequest(url: url)
            request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")
            
            let apiRequestTask = session.dataTask(with: request, callback: callback)
            apiRequestTask.priority = URLSessionTask.lowPriority
            return apiRequestTask
        }
    }
}
