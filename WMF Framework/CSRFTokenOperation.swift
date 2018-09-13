import Foundation


public protocol CSRFTokenOperationDelegate: class {
    func CSRFTokenOperationDidFailToRetrieveURLForTokenFetcher(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
    func CSRFTokenOperationDidFetchToken(_ operation: CSRFTokenOperation, token: WMFAuthToken, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
    func CSRFTokenOperationDidFailToFetchToken(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
    func CSRFTokenOperationWillFinish(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void)
}

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

    public weak var delegate: CSRFTokenOperationDelegate?
    
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
                delegate?.CSRFTokenOperationDidFailToRetrieveURLForTokenFetcher(self, error: CSRFTokenOperationError.failedToRetrieveURLForTokenFetcher, context: context) {
                    self.completion = nil
                    finish()
                }
                return
        }
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
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
