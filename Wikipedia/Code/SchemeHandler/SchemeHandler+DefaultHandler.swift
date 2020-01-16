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
        
        func dataTaskForURL(_ url: URL, callback: Session.Callback) -> URLSessionTask {
            let request = URLRequest(url: url)
            let task = session.dataTask(with: request as URLRequest, callback: callback)
            return task
        }
    }
}
