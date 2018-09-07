public struct WikidataAPI {
    public static let host = "www.wikidata.org"
    public static let path = "/w/api.php"
    public static let scheme = "https"
}

enum WikidataAPIError: String, LocalizedError {
    case missingToken = "notoken"
    case invalidToken = "badtoken"
    case failedToRetrieveToken

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

    // TODO: If necessary, modify to pass one of the article types (WMFArticle, MWKArticle) instead.
    @objc public func publish(newWikidataDescription: String, forPageWithTitle title: String, in language: String, completion: @escaping (_ error: Error?) -> Void) {
        guard !isBlacklisted(language) else {
            print("Attempting to publish a wikidata description in a blacklisted language; aborting")
            return
        }
        let _ = Session.shared.requestWithCSRF(scheme: WikidataAPI.scheme, host: WikidataAPI.host, path: WikidataAPI.path, method: .post, queryParameters: ["action": "wbsetdescription", "language": language, "title": title, "value": newWikidataDescription, "format": "json"], delegate: self) { (result, response, error) in
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
        Session.shared.jsonCodableTask(host: context.host, scheme: context.scheme, method: context.method, path: context.path, queryParameters: context.queryParameters, bodyParameters: ["token": token.token], bodyEncoding: .form) { (result: WikidataAPIResult?, response, error) in
            context.completion?(result, response, error)
        }
    }

    public func CSRFTokenOperationDidFailToRetrieveURLForTokenFetcher(_ operation: CSRFTokenOperation, context: CSRFTokenOperationContext, completion: @escaping () -> Void) {
        context.completion?(nil, nil, WikidataAPIError.failedToRetrieveToken)
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
