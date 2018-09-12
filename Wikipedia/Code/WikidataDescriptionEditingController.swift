public struct WikidataAPI {
    public static let host = "www.wikidata.org"
    public static let path = "/w/api.php"
    public static let scheme = "https"

    public static var urlWithoutAPIPath: URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        return components.url
    }
}

enum WikidataAPIError: String, LocalizedError {
    case missingToken = "notoken"
    case invalidToken = "badtoken"
    case permissionDenied = "permissiondenied"

    init?(from wikidataAPIResult: WikidataAPIResult?) {
        guard let errorCode = wikidataAPIResult?.error?.code else {
            return nil
        }
        self.init(rawValue: errorCode)
    }

    var localizedDescription: String {
        return "TODO 🚧"
    }

    var errorDescription: String? {
        return "TODO 🚧"
    }
}

struct WikidataAPIResult: Decodable {
    struct Error: Decodable {
        let code, info: String?
    }
    let error: Error?
    let success: Int?
}

@objc public class WikidataDescriptionEditingController: NSObject {
    private var blacklistedLanguages = Set<String>()

    @objc public func setBlacklistedLanguages(_ blacklistedLanguagesFromRemoteConfig: Array<String>) {
        blacklistedLanguages = Set(blacklistedLanguagesFromRemoteConfig)
    }

    public func isBlacklisted(_ languageCode: String) -> Bool {
        guard !blacklistedLanguages.isEmpty else {
            return false
        }
        return blacklistedLanguages.contains(languageCode)
    }

    @objc(publishNewWikidataDescription:forArticle:completion:)
    public func publish(newWikidataDescription: String, for article: MWKArticle, completion: @escaping (_ error: Error?) -> Void) {
        guard let title = article.displaytitle,
        let language = article.url.wmf_language,
        let wiki = article.url.wmf_wiki else {
            assertionFailure()
            return
        }
        publish(newWikidataDescription: newWikidataDescription, forPageWithTitle: title, language: language, wiki: wiki, completion: completion)
    }

    /// Publish new wikidata description.
    ///
    /// - Parameters:
    ///   - newWikidataDescription: new wikidata description to be published, e.g., "Capital of England and the United Kingdom".
    ///   - title: title of the page to be updated with new wikidata description, e.g., "London".
    ///   - language: language code of the page's wiki, e.g., "en".
    ///   - wiki: wiki of the page to be updated, e.g., "enwiki"
    ///   - completion: completion block called when operation is completed.
    private func publish(newWikidataDescription: String, forPageWithTitle title: String, language: String, wiki: String, completion: @escaping (_ error: Error?) -> Void) {
        guard !isBlacklisted(language) else {
            //DDLog("Attempting to publish a wikidata description in a blacklisted language; aborting")
            return
        }
        let queryParameters = ["action": "wbsetdescription",
                               "format": "json",
                               "formatversion": "2"]
        let bodyParameters = ["language": language,
                              "uselang": language,
                              "site": wiki,
                              "title": title,
                              "value": newWikidataDescription,
                              "assert": "user"]
        let _ = Session.shared.requestWithCSRF(scheme: WikidataAPI.scheme, host: WikidataAPI.host, path: WikidataAPI.path, method: .post, queryParameters: queryParameters, bodyParameters: bodyParameters, delegate: self) { (result, response, error) in
            guard error == nil else {
                completion(error)
                return
            }
            guard let result = result as? WikidataAPIResult else {
                assertionFailure()
                return
            }
            completion(WikidataAPIError(from: result))
        }
    }
}

extension WikidataDescriptionEditingController: CSRFTokenOperationDelegate {
    public func CSRFTokenOperationDidFetchToken(_ operation: CSRFTokenOperation, token: WMFAuthToken, context: CSRFTokenOperationContext, completion: @escaping () -> Void) {
        var bodyParameters = context.bodyParameters
        bodyParameters?["token"] = token.token.wmf_UTF8StringWithPercentEscapes()
        Session.shared.jsonCodableTask(host: context.host, scheme: context.scheme, method: context.method, path: context.path, queryParameters: context.queryParameters, bodyParameters: bodyParameters, bodyEncoding: .form) { (result: WikidataAPIResult?, response, error) in
            context.completion?(result, response, error)
        }
    }

    public func CSRFTokenOperationDidFailToRetrieveURLForTokenFetcher(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void) {
        context.completion?(nil, nil, error)
        completion()
    }

    public func CSRFTokenOperationWillFinish(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void) {
        context.completion?(nil, nil, error)
        completion()
    }

    public func CSRFTokenOperationDidFailToFetchToken(_ operation: CSRFTokenOperation, error: Error, context: CSRFTokenOperationContext, completion: @escaping () -> Void) {
        context.completion?(nil, nil, error)
        completion()
    }
}

public extension MWKArticle {
    @objc var isWikidataDescriptionEditable: Bool {
        guard let dataStore = dataStore, let language = self.url.wmf_language else {
            return false
        }
        return dataStore.wikidataDescriptionEditingController.isBlacklisted(language)
    }
}
