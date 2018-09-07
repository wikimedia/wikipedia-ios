public struct WikidataAPI {
    public static let host = "wikidata.org"
    public static let path = "/w/api.php"
    public static let scheme = "https"
}

enum WikidataAPIError: String, LocalizedError {
    case missingToken = "notoken"

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

    @objc public func publish(newWikidataDescription: String, forPageWithTitle title: String, in language: String, completion: @escaping (_ error: Error?) -> Void) {
        guard !isBlacklisted(language) else {
            print("Attempting to publish a wikidata description in a blacklisted language; aborting")
            return
        }
        let _ = Session.shared.jsonCodableTask(host: WikidataAPI.host, scheme: WikidataAPI.scheme, method: .post, path: WikidataAPI.path, queryParameters: ["action": "wbsetdescription", "language": language, "title": title, "value": newWikidataDescription, "format": "json"]) { (result: WikidataAPIResult?, response, error) in
            completion(WikidataAPIError(from: result))
        }
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
