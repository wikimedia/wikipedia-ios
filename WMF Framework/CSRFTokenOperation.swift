import Foundation

enum CSRFTokenOperationError: Error {
    case failedToRetrieveURLForTokenFetcher
}

public class CSRFTokenOperation<Result>: AsyncOperation {
    let session: Session
    private let tokenFetcher: WMFAuthTokenFetcher
    
    let scheme: String
    let host: String
    let path: String
    
    let method: Session.Request.Method
    var bodyParameters: [String: Any]?
    let bodyEncoding: Session.Request.Encoding
    var queryParameters: [String: Any]?
    var operationCompletion: ((Result?, URLResponse?, Error?) -> Void)?
    var didFetchTokenTaskCompletion: ((Result?, URLResponse?, Error?) -> Void)?

    public struct TokenContext {
        let tokenName: String
        let tokenPlacement: TokenPlacement
        let shouldPercentEncodeToken: Bool
    }

    
    init(session: Session, tokenFetcher: WMFAuthTokenFetcher, scheme: String, host: String, path: String, method: Session.Request.Method, queryParameters: [String: Any]? = nil, bodyParameters: [String: Any]? = nil, delegate: CSRFTokenOperationDelegate? = nil, completion: @escaping (Any?, URLResponse?, Error?) -> Void) {
    let tokenContext: TokenContext

    enum TokenPlacement {
        case body
        case query
    }

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
