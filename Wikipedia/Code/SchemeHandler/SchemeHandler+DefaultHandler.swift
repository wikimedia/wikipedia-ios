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
        
        func dataTaskForRequest(_ request: URLRequest, callback: Session.Callback) -> URLSessionTask {
            let task = session.dataTask(with: request, callback: callback)
            return task
        }
    }
}
