import Foundation

// Base class for combining a Session and Configuration to make network requests
// Session handles constructing and making requests, Configuration handles url structure for the current target

// TODO: Standardize on returning CancellationKey or URLSessionTask
// TODO: Centralize cancellation and remove other cancellation implementations (ReadingListsAPI)
// TODO: Think about utilizing a request buildler instead of so many separate functions
// TODO: Utilize Result type where possible (Swift only)

@objc(WMFFetcher)
open class Fetcher: NSObject {
    @objc public let configuration: Configuration
    @objc public let session: Session

    public typealias CancellationKey = String
    
    private var tasks = [String: URLSessionTask]()
    private let semaphore = DispatchSemaphore.init(value: 1)
    
    @objc override public convenience init() {
        let dataStore = MWKDataStore.shared()
        self.init(session: dataStore.session, configuration: dataStore.configuration)
    }
    
    @objc required public init(session: Session, configuration: Configuration) {
        self.session = session
        self.configuration = configuration
    }
    
    @discardableResult public func requestMediaWikiAPIAuthToken(for URL: URL?, type: TokenType, cancellationKey: CancellationKey? = nil, completionHandler: @escaping (Result<Token, Error>) -> Swift.Void) -> URLSessionTask? {
        let parameters = [
            "action": "query",
            "meta": "tokens",
            "type": type.stringValue,
            "format": "json"
        ]
        return performMediaWikiAPIPOST(for: URL, with: parameters) { (result, response, error) in
            
            if let error = error {
                completionHandler(Result.failure(error))
                return
            }
            guard
                let query = result?["query"] as? [String: Any],
                let tokens = query["tokens"] as? [String: Any],
                let tokenValue = tokens[type.stringValue + "token"] as? String
                else {
                    completionHandler(Result.failure(RequestError.unexpectedResponse))
                    return
            }
            guard !tokenValue.isEmpty else {
                completionHandler(Result.failure(RequestError.unexpectedResponse))
                return
            }
            completionHandler(Result.success(Token(value: tokenValue, type: type)))
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
    
    @objc(performTokenizedMediaWikiAPIPOSTWithTokenType:toURL:withBodyParameters:cancellationKey:reattemptLoginOn401Response:completionHandler:)
    @discardableResult public func performTokenizedMediaWikiAPIPOST(tokenType: TokenType = .csrf, to URL: URL?, with bodyParameters: [String: String]?, cancellationKey: CancellationKey? = nil, reattemptLoginOn401Response: Bool = true, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> CancellationKey? {
        let key = cancellationKey ?? UUID().uuidString
        let task = requestMediaWikiAPIAuthToken(for: URL, type: tokenType, cancellationKey: key) { (result) in
            switch result {
            case .failure(let error):
                completionHandler(nil, nil, error)
                self.untrack(taskFor: key)
            case .success(let token):
                var mutableBodyParameters = bodyParameters ?? [:]
                mutableBodyParameters[tokenType.parameterName] = token.value
                self.performMediaWikiAPIPOST(for: URL, with: mutableBodyParameters, cancellationKey: key, reattemptLoginOn401Response: reattemptLoginOn401Response, completionHandler: completionHandler)
            }
        }
        track(task: task, for: key)
        return key
    }
    
    @objc(performMediaWikiAPIPOSTForURL:withBodyParameters:cancellationKey:reattemptLoginOn401Response:completionHandler:)
    @discardableResult public func performMediaWikiAPIPOST(for URL: URL?, with bodyParameters: [String: String]?, cancellationKey: CancellationKey? = nil, reattemptLoginOn401Response: Bool = true, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        let url = configuration.mediaWikiAPIURLForURL(URL, with: nil)
        let key = cancellationKey ?? UUID().uuidString
        let task = session.postFormEncodedBodyParametersToURL(to: url, bodyParameters: bodyParameters, reattemptLoginOn401Response:reattemptLoginOn401Response) { (result, response, error) in
            
            completionHandler(result, response, error)
            self.untrack(taskFor: key)
            self.session.cloneCentralAuthCookies()
        }
        track(task: task, for: key)
        return task
    }

    @objc(performMediaWikiAPIGETForURL:withQueryParameters:cancellationKey:completionHandler:)
    @discardableResult public func performMediaWikiAPIGET(for URL: URL?, with queryParameters: [String: Any]?, cancellationKey: CancellationKey?, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        let url = configuration.mediaWikiAPIURLForURL(URL, with: queryParameters)
        let key = cancellationKey ?? UUID().uuidString
        let task = session.getJSONDictionary(from: url) { (result, response, error) in
            let returnError = error ?? RequestError.from(result?["error"] as? [String : Any])
            completionHandler(result, response, returnError)
            self.untrack(taskFor: key)
        }
        track(task: task, for: key)
        return task
    }
    
    @objc(performMediaWikiAPIGETForURLRequest:cancellationKey:completionHandler:)
    @discardableResult public func performMediaWikiAPIGET(for urlRequest: URLRequest, cancellationKey: CancellationKey?, completionHandler: @escaping ([String: Any]?, HTTPURLResponse?, Error?) -> Swift.Void) -> URLSessionTask? {
        
        let key = cancellationKey ?? UUID().uuidString
        let task = session.getJSONDictionary(from: urlRequest) { (result, response, error) in
            let returnError = error ?? RequestError.from(result?["error"] as? [String : Any])
            completionHandler(result, response, returnError)
            self.untrack(taskFor: key)
        }
        track(task: task, for: key)
        return task
    }
    
// MARK: Resolving MediaWiki Errors For Display
    
    /// Chain from MediaWiki API response if you want to resolve a set of error messages into a full html string for display. Use this method for raw dictionary responses. For Swift Codable responses, use resolveMediaWikiBlockedError(from apiErrors: [MediaWikiAPIError]...).
    /// - Parameters:
    ///   - result: Serialized dictionary from MediaWiki API response
    ///   - completionHandler: Completion handler called when full html is determined, which is packaged up in a MediaWikiAPIDisplayError object.
    @objc(resolveMediaWikiApiErrorFromResult:siteURL:completionHandler:)
    func resolveMediaWikiApiErrorFromResult(_ result: [String: Any], siteURL: URL, completionHandler: @escaping (MediaWikiAPIDisplayError?) -> Void) {

        var apiErrors: [MediaWikiAPIError] = []
        
        guard let errorsDict = result["errors"] as? [[String: Any]] else {
            completionHandler(nil)
            return
        }
        
        for errorDict in errorsDict {
            if let error = MediaWikiAPIError(dict: errorDict) {
                apiErrors.append(error)
            }
        }
        
        resolveMediaWikiError(from: apiErrors, siteURL: siteURL, completion: completionHandler)
    }
    
    /// Chain from MediaWiki API response if you want to resolve a set of error messages into a full html string for display. Use from Swift Codable responses that capture a collection of [MediaWikiAPIError] items.
    /// - Parameters:
    ///   - apiErrors: Decoded MediaWikiAPIError items from API response
    ///   - completion: Called when full html is determined, which is packaged up in a MediaWikiAPIDisplayError object.
    public func resolveMediaWikiError(from apiErrors: [MediaWikiAPIError], siteURL: URL, completion: @escaping (MediaWikiAPIDisplayError?) -> Void) {

        let protectedPageError = apiErrors.filter { $0.code.contains("protectedpage") }
        let blockedApiErrors = apiErrors.filter { $0.code.contains("block") }
        let firstBlockedApiErrorWithInfo = blockedApiErrors.first(where: { $0.data?.blockInfo != nil })
        let fallbackBlockedApiError = blockedApiErrors.first(where: { !$0.html.isEmpty })
        
        let firstAbuseFilterError = apiErrors.first(where: { $0.code.contains("abusefilter") && !$0.html.isEmpty })
        let firstDisplayableError = apiErrors.first(where: { !$0.html.isEmpty })
        
        let fallbackCompletion: () -> Void = {
            
            guard let fallbackBlockedApiError else {
                
                guard let firstAbuseFilterError else {
                    
                    guard let firstDisplayableError else {
                        completion(nil)
                        return
                    }
                    
                    let displayError = MediaWikiAPIDisplayError(messageHtml: firstDisplayableError.html, linkBaseURL: siteURL, code: firstDisplayableError.code)
                    completion(displayError)
                    return
                }
                
                let displayError = MediaWikiAPIDisplayError(messageHtml: firstAbuseFilterError.html, linkBaseURL: siteURL, code: firstAbuseFilterError.code)
                completion(displayError)
                return
            }

            let displayError = MediaWikiAPIDisplayError(messageHtml: fallbackBlockedApiError.html, linkBaseURL: siteURL, code: fallbackBlockedApiError.code)
            completion(displayError)
            return
        }

        if let blockedApiError = firstBlockedApiErrorWithInfo,
        let blockedApiInfo = blockedApiError.data?.blockInfo {
            resolveMediaWikiApiBlockError(siteURL: siteURL, code: blockedApiError.code, html: blockedApiError.html, blockInfo: blockedApiInfo) { displayError in

                guard let displayError = displayError else {
                    fallbackCompletion()
                    return
                }
                completion(displayError)
            }

        } else if let protectedPageError = protectedPageError.first(where: {!$0.html.isEmpty}) {
            let displayError = MediaWikiAPIDisplayError(messageHtml: protectedPageError.html, linkBaseURL: siteURL, code: protectedPageError.code)
            completion(displayError)

        } else {
            fallbackCompletion()
        }
    }

    private func resolveMediaWikiApiBlockError(siteURL: URL, code: String, html: String, blockInfo: MediaWikiAPIError.Data.BlockInfo,  completionHandler: @escaping (MediaWikiAPIDisplayError?) -> Void) {
        
        // First turn blockReason into html, if needed
        let group = DispatchGroup()
        
        var blockReasonHtml: String?
        var templateHtml: String?
        var templateSiteURL: URL?
        
        group.enter()
        parseBlockReason(siteURL: siteURL, blockReason: blockInfo.blockReason) { text in
            blockReasonHtml = text
            group.leave()
        }
        
        group.enter()
        fetchBlockedTextTemplate(isPartial: blockInfo.blockPartial, siteURL: siteURL) { text, siteURL in
            templateHtml = text
            templateSiteURL = siteURL
            group.leave()
        }
    
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            
            guard var templateHtml = templateHtml else {
                completionHandler(nil)
                return
            }
            
            let linkBaseURL = templateSiteURL ?? siteURL
            
            // Replace encoded placeholders first, before replacing them with blocked text.
            templateHtml = templateHtml.replacingOccurrences(of: "%241", with: "$1")
            templateHtml = templateHtml.replacingOccurrences(of: "%242", with: "$2")
            templateHtml = templateHtml.replacingOccurrences(of: "%243", with: "") // stripped out below
            templateHtml = templateHtml.replacingOccurrences(of: "%244", with: "") // stripped out below
            templateHtml = templateHtml.replacingOccurrences(of: "%245", with: "$5")
            templateHtml = templateHtml.replacingOccurrences(of: "%246", with: "$6")
            templateHtml = templateHtml.replacingOccurrences(of: "%247", with: "$7")
            templateHtml = templateHtml.replacingOccurrences(of: "%248", with: "$8")
            
            // Replace placeholders with blocked text
            templateHtml = templateHtml.replacingOccurrences(of: "$1", with: blockInfo.blockedBy)
            
            if let blockReasonHtml {
                templateHtml = templateHtml.replacingOccurrences(of: "$2", with: blockReasonHtml)
            }
            
            templateHtml = templateHtml.replacingOccurrences(of: "$3", with: "") // IP Address
            templateHtml = templateHtml.replacingOccurrences(of: "$4", with: "") // unknown parameter (unused?)
            
            templateHtml = templateHtml.replacingOccurrences(of: "$5", with: String(blockInfo.blockID))
            
            let blockExpiryDisplayDate = self.blockedDateForDisplay(iso8601DateString: blockInfo.blockExpiry, siteURL: linkBaseURL)
            templateHtml = templateHtml.replacingOccurrences(of: "$6", with: blockExpiryDisplayDate)
            
            let username = MWKDataStore.shared().authenticationManager.authStatePermanentUsername ?? ""
            templateHtml = templateHtml.replacingOccurrences(of: "$7", with: username)

            let blockedTimestampDisplayDate = self.blockedDateForDisplay(iso8601DateString: blockInfo.blockedTimestamp, siteURL: linkBaseURL)
            templateHtml = templateHtml.replacingOccurrences(of: "$8", with: blockedTimestampDisplayDate)
            
            let displayError = MediaWikiAPIDisplayError(messageHtml: templateHtml, linkBaseURL: linkBaseURL, code: code)
            completionHandler(displayError)
        }
        
    }
    
    private func blockedDateForDisplay(iso8601DateString: String, siteURL: URL) -> String {
        var formattedDateString: String? = nil
        if let date = (iso8601DateString as NSString).wmf_iso8601Date() {
            
            let dateFormatter = DateFormatter.wmf_localCustomShortDateFormatterWithTime(for: NSLocale.wmf_locale(for: siteURL.wmf_languageCode))
            
            formattedDateString = dateFormatter?.string(from: date)
        }
        
        return formattedDateString ?? ""
    }
    
    private func parseBlockReason(attempt: Int = 1, siteURL: URL, blockReason: String, completion: @escaping (String?) -> Void) {
        
        let params: [String: Any] = [
            "action": "parse",
            "prop": "text",
            "mobileformat": 1,
            "text": blockReason,
            "errorformat": "html",
            "erroruselocal": 1,
            "format": "json",
            "formatversion": 2
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { [weak self] result, response, error in

            
            guard let parse = result?["parse"] as? [String: Any],
                  let text = parse["text"] as? String else {
                
                // If unable to find, try app language once. Otherwise return nil.
                guard attempt == 1 else {
                    completion(nil)
                    return
                }

                guard let appLangSiteURL = MWKDataStore.shared().languageLinkController.appLanguage?.siteURL else {
                    completion(nil)
                    return
                }
                
                self?.parseBlockReason(attempt: attempt + 1, siteURL: appLangSiteURL, blockReason: blockReason, completion: completion)
                return
            }
            
            completion(text)
        }
    }
    
    private func fetchBlockedTextTemplate(isPartial: Bool = false, attempt: Int = 1, siteURL: URL, completion: @escaping (String?, URL) -> Void) {
        
        // Note: Not enough languages seem to have MediaWiki:Blockedtext-partial, so forcing MediaWiki:Blockedtext for now.
        
        let templateName = "MediaWiki:Blockedtext"
        if let parseText = templateName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let params: [String: Any] = [
                "action": "parse",
                "prop": "text",
                "mobileformat": 1,
                "page": parseText,
                "errorformat": "html",
                "erroruselocal": 1,
                "format": "json",
                "formatversion": 2
            ]
            
            performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { [weak self] result, response, error in

                guard let parse = result?["parse"] as? [String: Any],
                      let text = parse["text"] as? String else {
                    
                    // If unable to find, try app language once. Otherwise return nil.
                    guard attempt == 1 else {
                        completion(nil, siteURL)
                        return
                    }

                    guard let appLangSiteURL = MWKDataStore.shared().languageLinkController.appLanguage?.siteURL else {
                        completion(nil, siteURL)
                        return
                    }
                    
                    self?.fetchBlockedTextTemplate(isPartial: isPartial, attempt: attempt + 1, siteURL: appLangSiteURL, completion: completion)
                    return
                }
                
                completion(text, siteURL)
            }
        }
    }
    
// MARK: Decodable
    
    @discardableResult public func performDecodableMediaWikiAPIGET<T: Decodable>(for URL: URL?, with queryParameters: [String: Any]?, cancellationKey: CancellationKey? = nil, completionHandler: @escaping (Result<T, Error>) -> Swift.Void) -> CancellationKey? {
        let url = configuration.mediaWikiAPIURLForURL(URL, with: queryParameters)
        let key = cancellationKey ?? UUID().uuidString
        let task = session.jsonDecodableTask(with: url) { (result: T?, response: URLResponse?, error: Error?) in
            guard let result = result else {
                let error = error ?? RequestError.unexpectedResponse
                completionHandler(.failure(error))
                return
            }
            completionHandler(.success(result))
            self.untrack(taskFor: key)
        }
        track(task: task, for: key)
        return key
    }
    
    /// Creates and kicks off a URLSessionTask, tracking it in case the session needs to cancel it later. From fetchers, prefer using this method over calling session.jsonDecodableTask directly as it ensures the task is tracked and uses the result type
    @discardableResult public func trackedJSONDecodableTask<T: Decodable>(with urlRequest: URLRequest, completionHandler: @escaping (Result<T, Error>, HTTPURLResponse?) -> Swift.Void) -> URLSessionTask? {
        
        let key = UUID().uuidString
        let task = session.jsonDecodableTask(with: urlRequest) { (result: T?, response: URLResponse?, error: Error?) in
            defer {
                 self.untrack(taskFor: key)
            }
            guard let result = result else {
                completionHandler(.failure(error ?? RequestError.unexpectedResponse), response as? HTTPURLResponse)
                return
            }
            completionHandler(.success(result), response as? HTTPURLResponse)
        }
        
        track(task: task, for: key)
        return task
    }
    
// MARK: Tracking
    
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

// MARK: Modern Swift Concurrency APIs

extension Fetcher {
    
    public func performDecodableMediaWikiAPIGet<T: Decodable>(for URL: URL, with queryParameters: [String: Any]?) async throws -> T {
        guard let url = configuration.mediaWikiAPIURLForURL(URL, with: queryParameters) else {
            throw RequestError.invalidParameters
        }

        let (data, response) = try await session.data(for: url)

        guard let httpResponse = (response as? HTTPURLResponse) else {
            throw RequestError.unexpectedResponse
        }

        guard HTTPStatusCode.isSuccessful(httpResponse.statusCode) else {
            throw RequestError.http(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// These are for bridging to Obj-C only
@objc public extension Fetcher {
    @objc class var unexpectedResponseError: NSError {
        return RequestError.unexpectedResponse as NSError
    }
    @objc class var invalidParametersError: NSError {
        return RequestError.invalidParameters as NSError
    }
    @objc class var noNewDataError: NSError {
        return RequestError.noNewData as NSError
    }
    @objc class var cancelledError: NSError {
        return NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: [NSLocalizedDescriptionKey: RequestError.unexpectedResponse.localizedDescription])
    }
}

@objc(WMFTokenType)
public enum TokenType: Int {
    case csrf, login, createAccount, watch, rollback
    var stringValue: String {
        switch self {
        case .login:
            return "login"
        case .createAccount:
            return "createaccount"
        case .csrf:
            return "csrf"
        case .watch:
            return "watch"
        case .rollback:
            return "rollback"
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
    @objc public var value: String
    @objc public var type: TokenType
    public var isAuthorized: Bool
    @objc init(value: String, type: TokenType) {
        self.value = value
        self.type = type
        self.isAuthorized = value != "+\\"
    }
}
