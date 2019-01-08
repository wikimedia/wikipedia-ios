struct WikidataAPIResult: Decodable {
    struct Error: Decodable {
        let code, info: String?
    }
    let error: Error?
    let success: Int?
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
    case notEditable
    case unknown
}

@objc public final class WikidataDescriptionEditingController: Fetcher {
    static let DidMakeAuthorizedWikidataDescriptionEditNotification = NSNotification.Name(rawValue: "WMFDidMakeAuthorizedWikidataDescriptionEdit")

    /// Publish new wikidata description.
    ///
    /// - Parameters:
    ///   - newWikidataDescription: new wikidata description to be published, e.g., "Capital of England and the United Kingdom".
    ///   - source: description source; none, central or local.
    ///   - wikidataID: id for the Wikidata entity including the prefix
    ///   - language: language code of the page's wiki, e.g., "en".
    ///   - completion: completion block called when operation is completed.
    public func publish(newWikidataDescription: String, from source: ArticleDescriptionSource, forWikidataID wikidataID: String, language: String, completion: @escaping (Error?) -> Void) {
        guard source != .local else {
            completion(WikidataPublishingError.notEditable)
            return
        }
        let requestWithCSRFCompletion: (WikidataAPIResult?, URLResponse?, Bool?, Error?) -> Void = { result, response, authorized, error in
            if let error = error {
                completion(error)
            }
            guard let result = result else {
                completion(WikidataPublishingError.apiResultNotParsedCorrectly)
                return
            }

            completion(result.error)

            if let authorized = authorized, authorized, result.error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: WikidataDescriptionEditingController.DidMakeAuthorizedWikidataDescriptionEditNotification, object: nil)
                }
            }
        }
        
        let languageCodeParameters = [
            "action": "query",
            "meta": "siteinfo",
            "format": "json",
            "formatversion": "2"]

        let languageCodeComponents = configuration.mediaWikiAPIURForWikiLanguage(language, with: languageCodeParameters)
        session.jsonDecodableTask(with: languageCodeComponents.url) { (siteInfo: MediaWikiSiteInfoResult?, response, authorized, error) in
            let normalizedLanguage = siteInfo?.query.general.lang ?? "en"
            let queryParameters = ["action": "wbsetdescription",
                                   "format": "json",
                                   "formatversion": "2"]
            let bodyParameters = ["language": normalizedLanguage,
                                  "uselang": normalizedLanguage,
                                  "id": wikidataID,
                                  "value": newWikidataDescription]
            let components = self.configuration.wikidataAPIURLComponents(with: queryParameters)
            self.session.requestWithCSRF(type: CSRFTokenJSONDecodableOperation.self, components: components, method: .post, bodyParameters: bodyParameters, bodyEncoding: .form, tokenContext: CSRFTokenOperation.TokenContext(tokenName: "token", tokenPlacement: .body), completion: requestWithCSRFCompletion)
        }
    }
}

public extension MWKArticle {
    @objc var isWikidataDescriptionEditable: Bool {
        return wikidataId != nil && descriptionSource != .local
    }
}
