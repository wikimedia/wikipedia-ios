import Foundation

class CRSFTokenOperation: AsyncOperation {
    private let session: Session
    private let tokenFetcher: WMFAuthTokenFetcher
    
    private let scheme: String
    private let host: String
    private let path: String
    
    private let method: Session.Request.Method
    private let bodyParameters: [String: Any]?
    private let completion: ([String: Any]?, URLResponse?, Error?) -> Void
    
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
                completion(nil, nil, APIReadingListError.generic)
                finish()
                return
        }
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: self.host, method: self.method, path: self.path, queryParameters: ["csrf_token": token.token], bodyParameters: self.bodyParameters) { (result , response, error) in
                if let apiErrorType = result?["title"] as? String, let apiError = APIReadingListError(rawValue: apiErrorType) {
                    DDLogDebug("RLAPI FAILED: \(self.method.stringValue) \(self.path) \(apiError)")
                    self.completion(result, nil, apiError)
                } else {
                    #if DEBUG
                    if let error = error {
                        DDLogDebug("RLAPI FAILED: \(self.method.stringValue) \(self.path) \(error)")
                    } else {
                        DDLogDebug("RLAPI: \(self.method.stringValue) \(self.path)")
                    }
                    #endif
                    self.completion(result, response, error)
                }
                finish()
                }?.resume()
        }) { (failure) in
            self.completion(nil, nil, failure)
            finish()
        }
    }
}
