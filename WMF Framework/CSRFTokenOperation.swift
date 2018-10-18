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
    var completion: ((Result?, URLResponse?, Bool?, Error?) -> Void)?

    public struct TokenContext {
        let tokenName: String
        let tokenPlacement: TokenPlacement
        let shouldPercentEncodeToken: Bool
    }

    let tokenContext: TokenContext

    enum TokenPlacement {
        case body
        case query
    }

    required init(session: Session, tokenFetcher: WMFAuthTokenFetcher, scheme: String, host: String, path: String, method: Session.Request.Method, queryParameters: [String: Any]? = [:], bodyParameters: [String: Any]? = [:], bodyEncoding: Session.Request.Encoding = .json, tokenContext: TokenContext, completion: @escaping (Result?, URLResponse?, Bool?, Error?) -> Void) {
        self.session = session
        self.tokenFetcher = tokenFetcher
        self.scheme = scheme
        self.host = host
        self.path = path
        self.method = method
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.bodyEncoding = bodyEncoding
        self.tokenContext = tokenContext
        self.completion = completion
    }
    
    override public func finish(with error: Error) {
        super.finish(with: error)
        completion?(nil, nil, nil, error)
        completion = nil
    }
    
    override public func cancel() {
        super.cancel()
        finish(with: AsyncOperationError.cancelled)
    }
    
    override public func execute() {
        let finish: (Result?, URLResponse?, Bool?, Error?) -> Void  = { (result, response, authorized, error) in
            self.completion?(result, response, authorized, error)
            self.completion = nil
            self.finish()
        }
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        guard
            let siteURL = components.url
            else {
                finish(nil, nil, nil, CSRFTokenOperationError.failedToRetrieveURLForTokenFetcher)
                return
        }
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.addTokenToRequest(token)
            self.didFetchToken(token, completion: finish)
        }) { (error) in
            finish(nil, nil, nil, error)
        }
    }

    private func addTokenToRequest(_ token: WMFAuthToken) {
        let tokenValue = token.token
        let maybePercentEncodedTokenValue = tokenContext.shouldPercentEncodeToken ? tokenValue.wmf_UTF8StringWithPercentEscapes() : tokenValue
        switch tokenContext.tokenPlacement {
        case .body:
            bodyParameters?[tokenContext.tokenName] = maybePercentEncodedTokenValue
        case .query:
            queryParameters?[tokenContext.tokenName] = maybePercentEncodedTokenValue
        }
    }

    open func didFetchToken(_ token: WMFAuthToken, completion: @escaping (Result?, URLResponse?, Bool?, Error?) -> Void) {
        assertionFailure("Subclasses should override")
    }
}

public class CSRFTokenJSONDictionaryOperation: CSRFTokenOperation<[String: Any]> {
    public override func didFetchToken(_ token: WMFAuthToken, completion: @escaping ([String: Any]?, URLResponse?, Bool?, Error?) -> Void) {
        self.session.jsonDictionaryTask(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, authorized: token.isAuthorized, completionHandler: completion)?.resume()
    }
}

public class CSRFTokenJSONDecodableOperation<Result: Decodable>: CSRFTokenOperation<Result> {
    public override func didFetchToken(_ token: WMFAuthToken, completion: @escaping (Result?, URLResponse?, Bool?, Error?) -> Void) {
        self.session.jsonDecodableTask(host: host, scheme: scheme, method: method, path: path, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, authorized: token.isAuthorized, completionHandler: completion)
    }
}
