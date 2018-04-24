import Foundation

class CSRFTokenOperation: AsyncOperation {
    private let session: Session
    private let tokenFetcher: WMFAuthTokenFetcher
    
    private let scheme: String
    private let host: String
    private let path: String
    
    private let method: Session.Request.Method
    private let bodyParameters: [String: Any]?
    private var completion: (([String: Any]?, URLResponse?, Error?) -> Void)?
    
    init(session: Session, tokenFetcher: WMFAuthTokenFetcher, scheme: String, host: String, path: String, method: Session.Request.Method, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        self.session = session
        self.tokenFetcher = tokenFetcher
        self.scheme = scheme
        self.host = host
        self.path = path
        self.method = method
        self.bodyParameters = bodyParameters
        self.completion = completion
    }
    
    override func finish(with error: Error) {
        completion?(nil, nil, error)
        completion = nil
        super.finish(with: error)
    }
    
    override func cancel() {
        super.cancel()
        finish(with: AsyncOperationError.cancelled)
    }
    
    override func execute() {
        let finish = {
            self.finish()
        }
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        guard
            let siteURL = components.url
            else {
                completion?(nil, nil, APIReadingListError.generic)
                completion = nil
                finish()
                return
        }
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: self.host, method: self.method, path: self.path, queryParameters: ["csrf_token": token.token], bodyParameters: self.bodyParameters) { (result , response, error) in
                if let apiErrorType = result?["title"] as? String, let apiError = APIReadingListError(rawValue: apiErrorType), apiError != .alreadySetUp {
                    DDLogDebug("RLAPI FAILED: \(self.method.stringValue) \(self.path) \(apiError)")
                    self.completion?(result, nil, apiError)
                } else {
                    #if DEBUG
                    if let error = error {
                        DDLogDebug("RLAPI FAILED: \(self.method.stringValue) \(self.path) \(error)")
                    } else {
                        DDLogDebug("RLAPI: \(self.method.stringValue) \(self.path)")
                    }
                    #endif
                    self.completion?(result, response, error)
                }
                self.completion = nil
                finish()
                }?.resume()
        }) { (failure) in
            self.completion?(nil, nil, failure)
            self.completion = nil
            finish()
        }
    }
}
