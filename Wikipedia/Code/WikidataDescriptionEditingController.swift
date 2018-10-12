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
    case notEditable
    case unknown
}

@objc public final class WikidataDescriptionEditingController: NSObject {
    weak var dataStore: MWKDataStore?

    @objc public init(with dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }

    public func publish(newWikidataDescription: String, from source: ArticleDescriptionSource, for articleURL: URL, completion: @escaping (Error?) -> Void) {
        guard let title = articleURL.wmf_title,
        let language = articleURL.wmf_language,
        let wiki = articleURL.wmf_wiki else {
            completion(WikidataPublishingError.invalidArticleURL)
            return
        }
        publish(newWikidataDescription: newWikidataDescription, from: source, forPageWithTitle: title, language: language, wiki: wiki, completion: completion)
    }

    /// Publish new wikidata description.
    ///
    /// - Parameters:
    ///   - newWikidataDescription: new wikidata description to be published, e.g., "Capital of England and the United Kingdom".
    ///   - title: title of the page to be updated with new wikidata description, e.g., "London".
    ///   - language: language code of the page's wiki, e.g., "en".
    ///   - wiki: wiki of the page to be updated, e.g., "enwiki"
    ///   - completion: completion block called when operation is completed.
    private func publish(newWikidataDescription: String, from source: ArticleDescriptionSource, forPageWithTitle title: String, language: String, wiki: String, completion: @escaping (Error?) -> Void) {
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
                    self.madeAuthorizedWikidataDescriptionEdit = authorized
                }
            }
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

    // MARK: - WMFKeyValue

    static let DidMakeAuthorizedWikidataDescriptionEditNotification = NSNotification.Name(rawValue: "WMFDidMakeAuthorizedWikidataDescriptionEdit")
    private let madeAuthorizedWikidataDescriptionEditKey = "WMFMadeAuthorizedWikidataDescriptionEditKey"
    @objc public private(set) var madeAuthorizedWikidataDescriptionEdit: Bool {
        set {
            assertMainThreadAndDataStore()
            guard madeAuthorizedWikidataDescriptionEdit != newValue, let dataStore = dataStore else {
                return
            }
            dataStore.viewContext.wmf_setValue(NSNumber(value: newValue), forKey: madeAuthorizedWikidataDescriptionEditKey)
            dataStore.remoteNotificationsController.toggle(on: newValue)
        }
        get {
            assertMainThreadAndDataStore()
            guard let keyValue = dataStore?.viewContext.wmf_keyValue(forKey: madeAuthorizedWikidataDescriptionEditKey) else {
                return false
            }
            guard let value = keyValue.value as? NSNumber else {
                assertionFailure("Expected value of keyValue \(madeAuthorizedWikidataDescriptionEditKey) to be of type NSNumber")
                return false
            }
            return value.boolValue
        }
    }

    private func assertMainThreadAndDataStore() {
        assert(Thread.isMainThread)
        assert(dataStore != nil)
    }
}

public extension MWKArticle {
    @objc var isWikidataDescriptionEditable: Bool {
        return descriptionSource != .local
    }
}
