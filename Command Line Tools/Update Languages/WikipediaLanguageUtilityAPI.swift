import Foundation
import Combine

/// **THIS IS NOT PART OF THE MAIN APP - IT'S A COMMAND LINE UTILITY**
///
/// Utility for making API calls that update prebuilt lists of information about different language Wikipedias
class WikipediaLanguageUtilityAPI {
    // We can't use codable becuase this API's resposne format has no concrete type structure
    // For example, the mixing of ints and dictionaries here:
    // "sitematrix": {
    //    "count": 951,
    //    "0": {
    //      "code": "aa",
    //      "name": "Qaf\u00e1r af",
    //       "localname": "Afar"
    //     },
    func getSites() -> AnyPublisher<[Wikipedia], Error> {
        let sitematrixURL = URL(string: "https://meta.wikimedia.org/w/api.php?action=sitematrix&format=json&formatversion=2&origin=*")!
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
                    let localname = result["localname"] as? String,
                    let sites = result["site"] as? [[String: Any]]
                    else {
                        return nil
                }
                guard
                    let wikipedia = sites.first(where: { (site) -> Bool in
                        site["code"] as? String == "wiki"
                    }),
                    let sitename = wikipedia["sitename"] as? String
                    else {
                        return nil
                }
                return Wikipedia(languageCode: code, languageName: name, localName: localname, siteName: sitename)
            }
            // Add testwiki, it's not returned by the site matrix
            wikipedias.append(Wikipedia(languageCode: "test", languageName: "Test", localName: "Test", siteName: "Test Wikipedia"))
            return wikipedias
        }.eraseToAnyPublisher()
    }
    
    func getSiteInfo(with languageCode: String) -> AnyPublisher<SiteInfo, Error> {
        let siteInfoURL = URL(string: "https://\(languageCode).wikipedia.org/w/api.php?action=query&format=json&prop=&list=&meta=siteinfo&siprop=namespaces%7Cgeneral%7Cnamespacealiases&formatversion=2&origin=*")!
        return URLSession.shared
            .dataTaskPublisher(for: siteInfoURL)
            .tryMap { (result) -> SiteInfo in
                try JSONDecoder().decode(SiteInfo.self, from: result.data)
        }.eraseToAnyPublisher()
    }
    
    func getCodeMirrorConfigJSON(for wikiLanguage: String) -> AnyPublisher<String, Error> {
        let codeMirrorConfigURL = URL(string: "http://\(wikiLanguage).wikipedia.org/w/load.php?debug=false&lang=en&modules=ext.CodeMirror.data")!
        return URLSession.shared.dataTaskPublisher(for: codeMirrorConfigURL)
            .tryMap { (result) -> String in
                guard
                    let responseString = String(data: result.data, encoding: .utf8),
                    let soughtSubstring = self.extractJSONString(from: responseString)
                    else {
                        throw WikipediaLanguageUtilityAPIError.generic
                }
                return soughtSubstring.replacingOccurrences(of: "!0", with: "true")
        }.eraseToAnyPublisher()
    }
    
    private let jsonExtractionRegex = try! NSRegularExpression(pattern: #"(?:mw\.config\.set\()(.*?)(?:\);\n*\}\);)"#, options: [.dotMatchesLineSeparators])
    
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
    }
    let query: Query
}
