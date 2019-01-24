import UIKit

public enum FetcherError: LocalizedError {
    case unexpectedResponse
    public var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return WMFLocalizedString("fetcher-error-unexpected-response", value: "The app received an unexpected response from the server. Please try again later.", comment: "Error shown to the user for unexpected server responses.")
        }
    }
}

@objc(WMFTokenType)
public enum TokenType: Int {
    case csrf, login, createAccount
    var stringValue: String {
        switch self {
        case .login:
            return "login"
        case .createAccount:
            return "createAccount"
        case .csrf:
            return "csrf"
        }
    }
    var parameterName: String {
        switch self {
        case .login:
            return "logintoken"
        case .createAccount:
            return "createtoken"
        default:
            return "token"
        }
    }
}

@objc(WMFToken)
public class Token: NSObject {
    @objc public var token: String
    @objc public var type: TokenType
    public var isAuthorized: Bool
    @objc init(token: String, type: TokenType) {
        self.token = token
        self.type = type
        self.isAuthorized = token != "+\\"
    }
}

public enum FetcherResult<Success, Error> {
    case success(Success)
    case failure(Error)
}

@objc(WMFFetcher)
open class Fetcher: NSObject {
    @objc public let configuration: Configuration
    @objc public let session: Session

    public typealias CancellationKey = String
    
    private var tasks = [String: URLSessionTask]()
    private let semaphore = DispatchSemaphore.init(value: 1)
    
    @objc override public convenience init() {
        self.init(session: Session.shared, configuration: Configuration.current)
    }
    
    @objc required public init(session: Session, configuration: Configuration) {
        self.session = session
        self.configuration = configuration
    }
    
    @discardableResult public func requestMediaWikiAPIAuthToken(for URL: URL?, type: TokenType, cancellationKey: CancellationKey? = nil, completionHandler: @escaping (FetcherResult<Token, Error>) -> Swift.Void) -> URLSessionTask? {
        let parameters = [
            "action": "query",
            "meta": "tokens",
            "type": type.stringValue,
            "format": "json"
        ]
        return performMediaWikiAPIPOST(for: URL, with: parameters) { (result, response, error) in
            if let error = error {
                completionHandler(FetcherResult.failure(error))
                return
            }
            guard
                let query = result?["query"] as? [String: Any],
                let tokens = query["tokens"] as? [String: Any],
                let token = tokens[type.stringValue + "token"] as? String
                else {
                    completionHandler(FetcherResult.failure(FetcherError.unexpectedResponse))
                    return
            }
            guard token.count > 0 else {
                completionHandler(FetcherResult.failure(FetcherError.unexpectedResponse))
                return
            }
            completionHandler(FetcherResult.success(Token(token: token, type: type)))
        }
    }
    
    
    @objc(requestMediaWikiAPIAuthToken:withType:cancellationKey:completionHandler:)
    @discardableResult public func requestMediaWikiAPIAuthToken(for URL: URL?, with type: TokenType, cancellationKey: CancellationKey? = nil, completionHandler: @escaping (Token?, Error?) -> Swift.Void) -> URLSessionTask? {
        return requestMediaWikiAPIAuthToken(for: URL, type: type, cancellationKey: cancellationKey) { (result) in
            switch result {
            case .failure(let error):
                completionHandler(nil, error)
            case .success(let token):
                completionHandler(token, nil)
            }
        }
    }
    
    @objc(performTokenizedMediaWikiAPIPOSTWithTokenType:toURL:withBodyParameters:cancellationKey:completionHandler:)
    @discardableResult public func performTokenizedMediaWikiAPIPOST(tokenType: TokenType = .csrf, to URL: URL?, with bodyParameters: [String: String]?, cancellationKey: CancellationKey? = nil, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> CancellationKey? {
        let key = cancellationKey ?? UUID().uuidString
        let task = requestMediaWikiAPIAuthToken(for: URL, type: tokenType, cancellationKey: key) { (result) in
            switch result {
            case .failure(let error):
                completionHandler(nil, nil, error)
                self.untrack(taskFor: key)
            case .success(let token):
                var mutableBodyParameters = bodyParameters ?? [:]
                mutableBodyParameters[tokenType.parameterName] = token.token
                self.performMediaWikiAPIPOST(for: URL, with: mutableBodyParameters, cancellationKey: key, completionHandler: completionHandler)
            }
        }
        track(task: task, for: key)
        return key
    }
    
    @discardableResult public func requestWithCSRF<R, O: CSRFTokenOperation<R>>(type operationType: O.Type, components: URLComponents, method: Session.Request.Method, bodyParameters: [String: Any]? = [:], bodyEncoding: Session.Request.Encoding = .json, tokenContext: CSRFTokenOperation<R>.TokenContext, completion: @escaping (R?, URLResponse?, Error?) -> Void) -> Operation {
        let op = operationType.init(session: session, fetcher: self, components: components, method: method, bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, tokenContext: tokenContext, completion: completion)
        session.queue.addOperation(op)
        return op
    }
    
    @objc(performMediaWikiAPIPOSTForURL:withBodyParameters:cancellationKey:completionHandler:)
    @discardableResult public func performMediaWikiAPIPOST(for URL: URL?, with bodyParameters: [String: String]?, cancellationKey: CancellationKey? = nil, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        let components = configuration.mediaWikiAPIURForHost(URL?.host)
        let key = cancellationKey ?? UUID().uuidString
        let task = session.postFormEncodedBodyParametersToURL(to: components.url, bodyParameters: bodyParameters) { (result, response, error) in
            completionHandler(result, response, error)
            self.untrack(taskFor: key)
        }
        track(task: task, for: key)
        return task
    }

    @objc(performMediaWikiAPIGETForURL:withQueryParameters:cancellationKey:completionHandler:)
    @discardableResult public func performMediaWikiAPIGET(for URL: URL?, with queryParameters: [String: Any]?, cancellationKey: CancellationKey?, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        let components = configuration.mediaWikiAPIURForHost(URL?.host, with: queryParameters)
        let key = cancellationKey ?? UUID().uuidString
        let task = session.getJSONDictionary(from: components.url) { (result, response, error) in
            completionHandler(result, response, error)
            self.untrack(taskFor: key)
        }
        track(task: task, for: key)
        return task
    }
    
    @objc(trackTask:forKey:)
    public func track(task: URLSessionTask?, for key: String) {
        guard let task = task else {
            return
        }
        semaphore.wait()
        tasks[key] = task
        semaphore.signal()
    }
    
    @objc(untrackTaskForKey:)
    public func untrack(taskFor key: String) {
        semaphore.wait()
        tasks.removeValue(forKey: key)
        semaphore.signal()
    }
    
    @objc(cancelTaskForKey:)
    public func cancel(taskFor key: String) {
        semaphore.wait()
        tasks[key]?.cancel()
        tasks.removeValue(forKey: key)
        semaphore.signal()
    }
    
    @objc(cancelAllTasks)
    public func cancelAllTasks() {
        semaphore.wait()
        for (_, task) in tasks {
            task.cancel()
        }
        tasks.removeAll(keepingCapacity: true)
        semaphore.signal()
    }
}
