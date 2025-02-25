import Foundation
import Combine

/// Utility for making API calls that update prebuilt lists of information about different language Wikipedias
class WikipediaLanguageCommandLineUtilityAPI {
    // We can't use codable because this API's response has a dictionary with arbitrary keys mapped to values of mixed type.
    // For example, the mixing of ints and dictionaries in "sitematrix":
    // "sitematrix": {
    //    "count": 951,
    //    "0": {
    //      "code": "aa",
    //      "name": "Qaf\u00e1r af",
    //      ...
    //     },
    //    "1":  {
    //      "code": "ab",
    //      "name":"аԥсшәа",
    //      ...
    //     },
    //     ...
    // }
    func getSites() -> AnyPublisher<[Wikipedia], Error> {
        let sitematrixURL = URL(string: "https://meta.wikimedia.org/w/api.php?action=sitematrix&smsiteprop=url%7Cdbname%7Ccode%7Csitename%7Clang&format=json&formatversion=2&origin=*")!
        return URLSession.shared
            .dataTaskPublisher(for: sitematrixURL)
            .tryMap { result -> [String: Any] in
                /// See above as to why all of this is necessary instead of using codable
                guard let jsonObject = try JSONSerialization.jsonObject(with: result.data, options: .allowFragments) as? [String: Any] else {
                    throw WikipediaLanguageUtilityAPIError.generic
                }
                return jsonObject
        }
        .map { jsonObject -> [Wikipedia] in
            /// See above as to why all of this is necessary instead of using codable
            guard let sitematrix = jsonObject["sitematrix"] as? [String: Any] else {
                return []
            }
            var wikipedias = sitematrix.compactMap { (kv) -> Wikipedia? in
                guard
                    let result = kv.value as? [String: Any],
                    let code = result["code"] as? String,
                    let name = result["name"] as? String,
                    let localname = result["localname"] as? String
                    else {
                        return nil
                }
                
                guard code != "no" else {
                    // Norwegian (Bokmål) has a different ISO code than it's subdomain, which is useful to reference in some instances (prepopulating preferredLanguages from iOS device languages, and choosing the correct alternative article language from the langlinks endpoint).
                    // https://phabricator.wikimedia.org/T276645
                    // https://phabricator.wikimedia.org/T272193
                    return Wikipedia(languageCode: code, languageName: name, localName: localname, altISOCode: "nb")
                }
                
                // If there's a site array populated with a subdomain that does NOT equal languageCode, skip. It might show up as a dupe in the languages list.
                // TODO: This is a temporary workaround to remove duplicated languages, but eventually a proper data migration for the user might need to occur to switch from the old language code to the new.
                if let sites = result["site"] as? [[String : Any]] {
                    let site = sites.first
                    
                    if let siteURLString = site?["url"] as? String,
                       let components = URLComponents(string: siteURLString),
                       let host = components.host,
                       let hostLangCode = host.components(separatedBy: ".").first {
                        
                        if siteURLString.hasSuffix("wikipedia.org") {
                            if code != hostLangCode && code != "yue" { // Cantonese has already slipped in here twice, so leaving it in as a dupe until we can clean up user databases.
                                return nil
                            }
                        }
                        
                    }
                }
                
                return Wikipedia(languageCode: code, languageName: name, localName: localname, altISOCode: nil)
            }
            // Add testwiki and test2wiki, they are not returned by the site matrix
            wikipedias.append(Wikipedia(languageCode: "test", languageName: "Test", localName: "Test", altISOCode: nil))
            wikipedias.append(Wikipedia(languageCode: "test2", languageName: "Test 2", localName: "Test 2", altISOCode: nil))
            return wikipedias
        }.eraseToAnyPublisher()
    }
    
    func getSiteInfo(with languageCode: String) -> AnyPublisher<SiteInfo, Error> {
        let siteInfoURL = URL(string: "https://\(languageCode).wikipedia.org/w/api.php?action=query&format=json&prop=&list=&meta=siteinfo&siprop=namespaces%7Cgeneral%7Cnamespacealiases%7Cmagicwords&formatversion=2&origin=*")!
        return URLSession.shared
            .dataTaskPublisher(for: siteInfoURL)
            .tryMap { (result) -> SiteInfo in
                try JSONDecoder().decode(SiteInfo.self, from: result.data)
        }.eraseToAnyPublisher()
    }
    
    private let jsonExtractionRegex = try! NSRegularExpression(pattern: #"(?:mw\.config\.set\()(.*?)(?:\)\n*;\n*\}\);)"#, options: [.dotMatchesLineSeparators])
    
    private func extractJSONString(from responseString: String) -> String? {
        let results = jsonExtractionRegex.matches(in: responseString, range: NSRange(responseString.startIndex..., in: responseString))
        guard
            results.count == 1,
            let firstResult = results.first,
            firstResult.numberOfRanges == 2,
            let soughtCaptureGroupRange = Range(firstResult.range(at: 1), in: responseString)
            else {
                return nil
        }
        return String(responseString[soughtCaptureGroupRange])
    }
    
}

enum WikipediaLanguageUtilityAPIError: Error {
    case generic
}

struct SiteInfo: Codable {
    struct Namespace: Codable {
        let id: Int
        let name: String
        let canonical: String?
    }
    struct NamespaceAlias: Codable {
        let id: Int
        let alias: String
    }
    struct General: Codable {
        let mainpage: String
    }
    struct Query: Codable {
        let general: General
        let namespaces: [String: Namespace]
        let namespacealiases: [NamespaceAlias]
        let magicwords: [MagicWord]
    }
    let query: Query
}
