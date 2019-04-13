import Foundation

extension SchemeHandler {
    final class DefaultHandler: BaseSubHandler {
        
        let session: Session
        
        required init(session: Session) {
            self.session = session
        }
        
        override class var basePath: String? {
            return nil
        }
        
        //todo: this signature is terrible
        func dataTaskForPathComponents(_ pathComponents: [String], requestUrl: URL, cachedCompletionHandler: (URLResponse, Data) -> Void, callback: Session.Callback) -> (error: Error?, task: URLSessionTask?) {
            guard let proxiedUrl = (requestUrl as NSURL).wmf_originalURLFromAppScheme() else {
                return (SchemeHandlerError.invalidParameters, nil)
            }
            
            let request = NSURLRequest(url: proxiedUrl)
            let urlCache = URLCache.shared
            let cachedResponse = urlCache.cachedResponse(for: request as URLRequest)
            if let response = cachedResponse?.response, let data = cachedResponse?.data {
                cachedCompletionHandler(response, data)
                return (nil, nil)
            } else {
                let task = session.dataTask(with: request as URLRequest, callback: callback)
                return (nil, task)
            }
        }
    }
}
