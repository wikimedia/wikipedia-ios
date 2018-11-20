import Foundation

enum CSRFTokenOperationError: Error {
    case failedToRetrieveURLForTokenFetcher
}

public class CSRFTokenOperation<Result>: AsyncOperation {
    let session: Session
    private let tokenFetcher: WMFAuthTokenFetcher
    
    var components: URLComponents
    
    let method: Session.Request.Method
    var bodyParameters: [String: Any]?
    let bodyEncoding: Session.Request.Encoding
    var completion: ((Result?, URLResponse?, Bool?, Error?) -> Void)?

    public struct TokenContext {
        let tokenName: String
        let tokenPlacement: TokenPlacement
    }

    let tokenContext: TokenContext

    enum TokenPlacement {
        case body
        case query
    }

    required init(session: Session, tokenFetcher: WMFAuthTokenFetcher, components: URLComponents, method: Session.Request.Method, bodyParameters: [String: Any]? = [:], bodyEncoding: Session.Request.Encoding = .json, tokenContext: TokenContext, completion: @escaping (Result?, URLResponse?, Bool?, Error?) -> Void) {
        self.session = session
        self.tokenFetcher = tokenFetcher
        self.components = components
        self.method = method
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
        switch tokenContext.tokenPlacement {
        case .body:
            bodyParameters?[tokenContext.tokenName] = tokenValue.wmf_UTF8StringWithPercentEscapes()
        case .query:
            components.appendQueryParametersToPercentEncodedQuery([tokenContext.tokenName: tokenValue])
        }
    }

    open func didFetchToken(_ token: WMFAuthToken, completion: @escaping (Result?, URLResponse?, Bool?, Error?) -> Void) {
        assertionFailure("Subclasses should override")
    }
}

public class CSRFTokenJSONDictionaryOperation: CSRFTokenOperation<[String: Any]> {
    public override func didFetchToken(_ token: WMFAuthToken, completion: @escaping ([String: Any]?, URLResponse?, Bool?, Error?) -> Void) {
        self.session.jsonDictionaryTask(with: components.url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, authorized: token.isAuthorized, completionHandler: completion)?.resume()
    }
}

public class CSRFTokenJSONDecodableOperation<Result: Decodable>: CSRFTokenOperation<Result> {
    public override func didFetchToken(_ token: WMFAuthToken, completion: @escaping (Result?, URLResponse?, Bool?, Error?) -> Void) {
        self.session.jsonDecodableTask(with: components.url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, authorized: token.isAuthorized, completionHandler: completion)
    }
}
