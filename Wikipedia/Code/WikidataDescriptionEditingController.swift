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

struct WikidataAPIResult: Decodable {
    struct Error: Decodable {
        let code, info: String?
    }
    let error: Error?
    let success: Int?
}

extension WikidataAPIResult.Error: LocalizedError {
    var errorDescription: String? {
        return info
    }
}

extension WikidataAPIResult {
    var succeeded: Bool {
        return success == 1
    }
}

enum WikidataPublishingError: LocalizedError {
    case invalidArticleURL
    case apiResultNotParsedCorrectly
    case blacklistedLanguage
    case unknown
}

@objc public final class WikidataDescriptionEditingController: NSObject {
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

    public typealias Success = () -> Void
    public typealias Failure = (Error) -> Void

    @objc(publishNewWikidataDescription:forArticle:success:failure:)
    public func publish(newWikidataDescription: String, for articleURL: URL, success: @escaping Success, failure: @escaping Failure) {
        guard let title = articleURL.wmf_title,
        let language = articleURL.wmf_language,
        let wiki = articleURL.wmf_wiki else {
            failure(WikidataPublishingError.invalidArticleURL)
            return
        }
        publish(newWikidataDescription: newWikidataDescription, forPageWithTitle: title, language: language, wiki: wiki, success: success, failure: failure)
    }

    /// Publish new wikidata description.
    ///
    /// - Parameters:
    ///   - newWikidataDescription: new wikidata description to be published, e.g., "Capital of England and the United Kingdom".
    ///   - title: title of the page to be updated with new wikidata description, e.g., "London".
    ///   - language: language code of the page's wiki, e.g., "en".
    ///   - wiki: wiki of the page to be updated, e.g., "enwiki"
    ///   - completion: completion block called when operation is completed.
    private func publish(newWikidataDescription: String, forPageWithTitle title: String, language: String, wiki: String, success: @escaping Success, failure: @escaping Failure) {
        guard !isBlacklisted(language) else {
            //DDLog("Attempting to publish a wikidata description in a blacklisted language; aborting")
            failure(WikidataPublishingError.blacklistedLanguage)
            return
        }
        let requestWithCSRFCompletion: (WikidataAPIResult?, URLResponse?, Error?) -> Void = { result, response, error in
            if let error = error {
                failure(error)
                return
            }
            guard let result = result else {
                failure(WikidataPublishingError.apiResultNotParsedCorrectly)
                return
            }
            if let error = result.error {
                failure(error)
                return
            }
            guard result.succeeded else {
                failure(WikidataPublishingError.unknown)
                return
            }
            success()
        }
        let queryParameters = ["action": "wbsetdescription",
                               "format": "json",
                               "formatversion": "2"]
        let bodyParameters = ["language": language,
                              "uselang": language,
                              "site": wiki,
                              "title": title,
                              "value": newWikidataDescription]
        let _ = Session.shared.requestWithCSRF(type: CSRFTokenJSONDecodableOperation.self, scheme: WikidataAPI.scheme, host: WikidataAPI.host, path: WikidataAPI.path, method: .post, queryParameters: queryParameters, bodyParameters: bodyParameters, bodyEncoding: .form, tokenContext: CSRFTokenOperation.TokenContext(tokenName: "token", tokenPlacement: .body, shouldPercentEncodeToken: true), completion: requestWithCSRFCompletion)
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
