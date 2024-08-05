import WMFData

public enum ArticleDescriptionSource: String {
    case none
    case unknown
    case central
    case local
    
    public static func from(string: String?) -> ArticleDescriptionSource {
        guard let sourceString = string else {
            return .none
        }
        guard let source = ArticleDescriptionSource(rawValue: sourceString) else {
            return .unknown
        }
        return source
    }
}

@objc public final class WikidataFetcher: Fetcher {
    
// MARK: Get Blocked Info Models & Methods
    
    public struct WikidataErrorsResult: Decodable {

        struct Query: Codable {
            struct Page: Codable {
                let title: String?
                let actions: [String: [MediaWikiAPIError]]?
            }
            
            let pages: [Page]?
        }
        
        let query: Query?
    }
    
    public func wikidataBlockedInfo(forEntity entity: String, completion: @escaping (MediaWikiAPIDisplayError?) -> Void) {
        
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions|info",
            "rvprop": "content|ids",
            "rvlimit": 1,
            "rvslots": "main",
            "titles": entity,
            "inprop": "protection",
            "meta": "userinfo", // we need the local user ID for event logging
            "continue": "",
            "format": "json",
            "formatversion": 2,
            "errorformat": "html",
            "errorsuselocal": "1",
            "intestactions": "edit", // needed for fully resolved protection error.
            "intestactionsdetail": "full" // needed for fully resolved protection error.
        ]
        
        let components = configuration.wikidataAPIURLComponents(with: parameters)
        let wikidataURL = components.url
        
        performDecodableMediaWikiAPIGET(for: wikidataURL, with: parameters) { [weak self] (result: Result<WikidataErrorsResult, Error>) in
            
            switch result {
            case .success(let result):
                guard
                    let self,
                    let siteURL = wikidataURL?.wmf_site,
                    let page = result.query?.pages?.first else {
                        completion(nil)
                        return
                }
                
                guard let editErrors = page.actions?["edit"] as? [MediaWikiAPIError] else {
                    completion(nil)
                    return
                }
                
                self.resolveMediaWikiError(from: editErrors, siteURL: siteURL, completion: completion)
            default:
                completion(nil)
            }
        }
    }
    
// MARK: Publish New Description Models & Methods
    
    static let DidMakeAuthorizedWikidataDescriptionEditNotification = NSNotification.Name(rawValue: "WMFDidMakeAuthorizedWikidataDescriptionEdit")
    
    public enum WikidataPublishingError: LocalizedError {
        case invalidArticleURL
        case apiResultNotParsedCorrectly
        case notEditable
        case apiBlocked(error: MediaWikiAPIDisplayError)
        case apiAbuseFilterDisallow(error: MediaWikiAPIDisplayError)
        case apiAbuseFilterWarn(error: MediaWikiAPIDisplayError)
        case apiAbuseFilterOther(error: MediaWikiAPIDisplayError)
        case apiOther(error: MediaWikiAPIError)
        case unknown
        
        public var errorDescription: String? {
            switch self {
            case .apiBlocked(let blockedError):
                return blockedError.messageHtml
            case .apiOther(let error):
                return error.html
            default:
                return CommonStrings.unknownError
            }
        }
    }
    
    public struct WikidataAPIPublishResult: Decodable {
        let errors: [MediaWikiAPIError]?
        let success: Int?
        
        var succeeded: Bool {
            return success == 1
        }
    }
    
    struct MediaWikiSiteInfoResult: Decodable {
        struct MediaWikiQueryResult: Decodable {
            struct MediaWikiGeneralResult: Decodable {
                let lang: String
            }
            let general: MediaWikiGeneralResult
        }
        let query: MediaWikiQueryResult
    }
    
    /// Publish new wikidata description.
    ///
    /// - Parameters:
    ///   - newWikidataDescription: new wikidata description to be published, e.g., "Capital of England and the United Kingdom".
    ///   - source: description source; none, central or local.
    ///   - wikidataID: id for the Wikidata entity including the prefix
    ///   - languageCode: language code of the page's wiki, e.g., "en".
    ///   - completion: completion block called when operation is completed.

    public func publish(newWikidataDescription: String, from source: ArticleDescriptionSource, forWikidataID wikidataID: String, languageCode: String, editTags: [WMFEditTag]?, completion: @escaping (Error?) -> Void) {
        guard source != .local else {
            completion(WikidataPublishingError.notEditable)
            return
        }
        
        let languageCodeParameters = WikipediaSiteInfo.defaultRequestParameters

        let languageCodeComponents = configuration.mediaWikiAPIURLForLanguageCode(languageCode, queryParameters: languageCodeParameters)
        
        session.jsonDecodableTask(with: languageCodeComponents.url) { (siteInfo: MediaWikiSiteInfoResult?, _, _) in
            
            let normalizedLanguage = siteInfo?.query.general.lang ?? "en"
            var queryParameters: [String: Any] = ["action": "wbsetdescription",
                                   "errorformat": "html",
                                   "erroruselocal": 1,
                                   "format": "json",
                                   "formatversion": "2"]
            
            if let editTags,
               !editTags.isEmpty {
                queryParameters["matags"] = editTags.map { $0.rawValue }.joined(separator: ",")
            }
            
            let components = self.configuration.wikidataAPIURLComponents(with: queryParameters)
            let wikidataURL = components.url
            self.requestMediaWikiAPIAuthToken(for: wikidataURL, type: .csrf) { (result) in
                switch result {
                case .failure(let error):
                    completion(error)
                case .success(let token):
                    let bodyParameters = ["language": normalizedLanguage,
                                          "uselang": normalizedLanguage,
                                          "id": wikidataID,
                                          "value": newWikidataDescription,
                                          "token": token.value]
                    self.session.jsonDecodableTask(with: wikidataURL, method: .post, bodyParameters: bodyParameters, bodyEncoding: .form) { (result: WikidataAPIPublishResult?, response, networkError) in
                        
                        self.processResponse(result: result, response: response, isAuthorized: token.isAuthorized, networkError: networkError, siteURL: wikidataURL?.wmf_site, completion: completion)
                    }
                }
            }
        }
    }
    
    private func processResponse(result: WikidataAPIPublishResult?, response: URLResponse?, isAuthorized: Bool?, networkError: Error?, siteURL: URL?, completion: @escaping (Error?) -> Void) {
        
        if let networkError = networkError {
            completion(networkError)
            return
        }

        guard let result = result else {
            completion(WikidataPublishingError.apiResultNotParsedCorrectly)
            return
        }

        if let errors = result.errors,
           let siteURL = siteURL {
            
            self.resolveMediaWikiError(from: errors, siteURL: siteURL) { displayError in
                
                guard let displayError else {
                    if let firstError = errors.first {
                        
                        completion(WikidataPublishingError.apiOther(error: firstError))
                    } else {
                        completion(WikidataPublishingError.unknown)
                    }
                    
                    return
                }
                
                if displayError.code.contains("block") {
                    completion(WikidataPublishingError.apiBlocked(error: displayError))
                } else if displayError.code.contains("abusefilter") {
                    switch displayError.code {
                    case "abusefilter-disallowed":
                        completion(WikidataPublishingError.apiAbuseFilterDisallow(error: displayError))
                    case "abusefilter-warning":
                        completion(WikidataPublishingError.apiAbuseFilterWarn(error: displayError))
                    default:
                        completion(WikidataPublishingError.apiAbuseFilterOther(error: displayError))
                    }
                }
            }
            
            return
        }
        
        completion(nil)
        
        if isAuthorized ?? false, (result.errors ?? []).count == 0 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: WikidataFetcher.DidMakeAuthorizedWikidataDescriptionEditNotification, object: nil)
            }
        }
    }
}
