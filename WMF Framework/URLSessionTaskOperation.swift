import Foundation

class URLSessionTaskOperation: AsyncOperation {
    let task: URLSessionTask
    init(task: URLSessionTask) {
        self.task = task
    }
    
    var observation: NSKeyValueObservation?
    override func execute() {
        observation = task.observe(\.state, changeHandler: { (task, change) in
            switch task.state {
            case .completed:
                self.finish()
            default:
                break
            }
        })
        task.resume()
    }
}


class CRSFTokenOperation: AsyncOperation {
    let session: Session
    let tokenFetcher: WMFAuthTokenFetcher
    
    let scheme: String
    let host: String
    let fullPath: String
    
    let method: Session.Request.Method
    let bodyParameters: [String: Any]?
    let completion: ([String: Any]?, URLResponse?, Error?) -> Void
    
    init(session: Session, tokenFetcher: WMFAuthTokenFetcher, scheme: String, host: String, fullPath: String, method: Session.Request.Method, bodyParameters: [String: Any]? = nil, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        self.session = session
        self.tokenFetcher = tokenFetcher
        self.scheme = scheme
        self.host = host
        self.fullPath = fullPath
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
            self.session.jsonDictionaryTask(host: self.host, method: self.method, path: self.fullPath, queryParameters: ["csrf_token": token.token], bodyParameters: self.bodyParameters) { (result , response, error) in
                if let apiErrorType = result?["title"] as? String, let apiError = APIReadingListError(rawValue: apiErrorType) {
                    self.completion(result, nil, apiError)
                } else {
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
