import Foundation

public struct CSRFTokenOperationContext {
    let scheme: String
    let host: String
    let path: String
    let method: Session.Request.Method
    let queryParameters: [String: Any]?
    let bodyParameters: [String: Any]?
    let completion: ((Any?, URLResponse?, Error?) -> Void)?
}

public protocol CSRFTokenOperationDelegate: class {
    func CSRFTokenOperationDidFailToRetrieveURLForTokenFetcher(_ operation: CSRFTokenOperation, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
    func CSRFTokenOperationDidFetchToken(_ operation: CSRFTokenOperation, token: WMFAuthToken, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
    func CSRFTokenOperationDidFailToFetchToken(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
    func CSRFTokenOperationWillFinish(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
}

public class CSRFTokenOperation: AsyncOperation {
    private let session: Session
    private let tokenFetcher: WMFAuthTokenFetcher
    
    private let scheme: String
    private let host: String
    private let path: String
    
    private let method: Session.Request.Method
    private let bodyParameters: [String: Any]?
    private var queryParameters: [String: Any] = [:]
    private var completion: ((Any?, URLResponse?, Error?) -> Void)?

    private var context: CSRFTokenOperationContext {
        return CSRFTokenOperationContext(scheme: self.scheme, host: self.host, path: self.path, method: self.method, queryParameters: self.queryParameters, bodyParameters: self.bodyParameters, completion: self.completion)
    }

    public weak var delegate: CSRFTokenOperationDelegate?
    
    init(session: Session, tokenFetcher: WMFAuthTokenFetcher, scheme: String, host: String, path: String, method: Session.Request.Method, queryParameters: [String: Any] = [:], bodyParameters: [String: Any]? = nil, delegate: CSRFTokenOperationDelegate? = nil, completion: @escaping (Any?, URLResponse?, Error?) -> Void) {
        self.session = session
        self.tokenFetcher = tokenFetcher
        self.scheme = scheme
        self.host = host
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.completion = completion
        self.delegate = delegate
    }
    
    override public func finish(with error: Error) {
        delegate?.CSRFTokenOperationWillFinish(self, error: error, context: context) {
            self.completion = nil
            super.finish(with: error)
        }
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
                delegate?.CSRFTokenOperationDidFailToRetrieveURLForTokenFetcher(self, context: context) {
                    self.completion = nil
                    finish()
                }
                return
        }
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.queryParameters["csrf_token"] = token.token
            self.delegate?.CSRFTokenOperationDidFetchToken(self, token: token, context: self.context) {
                self.completion = nil
                finish()
            }
        }) { (error) in
            self.delegate?.CSRFTokenOperationDidFailToFetchToken(self, error: error, context: self.context) {
                self.completion = nil
                finish()
            }
        }
    }
}
