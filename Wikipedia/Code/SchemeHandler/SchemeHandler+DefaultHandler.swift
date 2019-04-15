import Foundation

extension SchemeHandler {
    final class DefaultHandler: BaseSubHandler, RemoteSubHandler {
        
        let session: Session
        
        required init(session: Session) {
            self.session = session
        }
        
        override class var basePath: String? {
            return nil
        }
        
        func urlForPathComponents(_ pathComponents: [String], requestURL: URL) -> URL? {
            return (requestURL as NSURL).wmf_originalURLFromAppScheme()
        }
        
        func cachedResponseForURL(_ url: URL) -> CachedURLResponse? {
            let request = NSURLRequest(url: url)
            let urlCache = URLCache.shared
            return urlCache.cachedResponse(for: request as URLRequest)
        }
        
        func dataTaskForURL(_ url: URL, callback: Session.Callback) -> URLSessionTask {
            let request = URLRequest(url: url)
            let task = session.dataTask(with: request as URLRequest, callback: callback)
            return task
        }
    }
}
