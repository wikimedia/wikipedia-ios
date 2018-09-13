import Foundation

enum CSRFTokenOperationError: Error {
    case failedToRetrieveURLForTokenFetcher
}

public class CSRFTokenOperation: AsyncOperation {
    private let session: Session
    private let tokenFetcher: WMFAuthTokenFetcher
    
    private let scheme: String
    private let host: String
    private let path: String
    
    private let method: Session.Request.Method
    private let bodyParameters: [String: Any]?
    private let queryParameters: [String: Any]?
    private var completion: ((Any?, URLResponse?, Error?) -> Void)?

    }

    
    init(session: Session, tokenFetcher: WMFAuthTokenFetcher, scheme: String, host: String, path: String, method: Session.Request.Method, queryParameters: [String: Any]? = nil, bodyParameters: [String: Any]? = nil, delegate: CSRFTokenOperationDelegate? = nil, completion: @escaping (Any?, URLResponse?, Error?) -> Void) {
        self.session = session
        self.tokenFetcher = tokenFetcher
        self.scheme = scheme
        self.host = host
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.completion = completion
    }
    
    override public func finish(with error: Error) {
    }
    
    override public func cancel() {
        super.cancel()
        finish(with: AsyncOperationError.cancelled)
    }
    
    override public func execute() {
        let finish = {
            self.finish()
        }
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        guard
            let siteURL = components.url
            else {
                return
        }
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
                finish()
            }
        }) { (error) in
        }
    }
}
