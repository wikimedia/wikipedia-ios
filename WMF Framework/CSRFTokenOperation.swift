import Foundation

enum CSRFTokenOperationError: Error {
    case failedToRetrieveURLForTokenFetcher
}

public class CSRFTokenOperation<Result>: AsyncOperation {
    let session: Session
    private let fetcher: Fetcher
    
    var components: URLComponents
    
    let method: Session.Request.Method
    var bodyParameters: [String: Any]?
    let bodyEncoding: Session.Request.Encoding
    var completion: ((Result?, URLResponse?, Error?) -> Void)?

    public struct TokenContext {
        let tokenName: String
        let tokenPlacement: TokenPlacement
    }

    let tokenContext: TokenContext

    enum TokenPlacement {
        case body
        case query
    }

    required init(session: Session, fetcher: Fetcher, components: URLComponents, method: Session.Request.Method, bodyParameters: [String: Any]? = [:], bodyEncoding: Session.Request.Encoding = .json, tokenContext: TokenContext, completion: @escaping (Result?, URLResponse?, Error?) -> Void) {
        self.session = session
        self.fetcher = fetcher
        self.components = components
        self.method = method
        self.bodyParameters = bodyParameters
        self.bodyEncoding = bodyEncoding
        self.tokenContext = tokenContext
        self.completion = completion
    }
    
    override public func finish(with error: Error) {
        super.finish(with: error)
        completion?(nil, nil, error)
        completion = nil
    }
    
    override public func cancel() {
        super.cancel()
        finish(with: AsyncOperationError.cancelled)
    }
    
    override public func execute() {
        let finish: (Result?, URLResponse?, Error?) -> Void  = { (result, response, error) in
            self.completion?(result, response, error)
            self.completion = nil
            self.finish()
        }
        guard
            let siteURL = components.url
            else {
                finish(nil, nil, CSRFTokenOperationError.failedToRetrieveURLForTokenFetcher)
                return
        }
        fetcher.requestMediaWikiAPIAuthToken(for: siteURL, type: .csrf) { (result) in
            switch result {
            case .failure(let error):
                finish(nil, nil, error)
            case .success(let token):
                self.addTokenToRequest(token)
                self.didFetchToken(token, completion: finish)
            }
        }
    }

    private func addTokenToRequest(_ token: Token) {
        let tokenValue = token.token
        switch tokenContext.tokenPlacement {
        case .body:
            bodyParameters?[tokenContext.tokenName] = tokenValue.wmf_UTF8StringWithPercentEscapes()
        case .query:
            components.appendQueryParametersToPercentEncodedQuery([tokenContext.tokenName: tokenValue])
        }
    }

    open func didFetchToken(_ token: Token, completion: @escaping (Result?, URLResponse?, Error?) -> Void) {
        assertionFailure("Subclasses should override")
    }
}

public class CSRFTokenJSONDictionaryOperation: CSRFTokenOperation<[String: Any]> {
    public override func didFetchToken(_ token: Token, completion: @escaping ([String: Any]?, URLResponse?, Error?) -> Void) {
        self.session.jsonDictionaryTask(with: components.url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, completionHandler: completion)?.resume()
    }
}

public class CSRFTokenJSONDecodableOperation<Result: Decodable>: CSRFTokenOperation<Result> {
    public override func didFetchToken(_ token: Token, completion: @escaping (Result?, URLResponse?, Error?) -> Void) {
        self.session.jsonDecodableTask(with: components.url, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, authorized: token.isAuthorized, completionHandler: completion)
    }
}
