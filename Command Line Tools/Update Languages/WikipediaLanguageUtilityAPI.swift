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
            return sitematrix.compactMap { (kv) -> Wikipedia? in
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
                    let sitename = wikipedia["sitename"] as? String,
                    let dbname = wikipedia["dbname"] as? String
                else {
                    return nil
                }
                return Wikipedia(languageCode: code, languageName: name, localName: localname, siteName: sitename, dbName:dbname)
            }
        }.eraseToAnyPublisher()
    }
    
    func getSiteInfo(with languageCode: String, completion: @escaping (Result<SiteInfo, Error>) -> Void) {
        let siteInfoURL = URL(string: "https://\(languageCode).wikipedia.org/w/api.php?action=query&format=json&prop=&list=&meta=siteinfo&siprop=namespaces%7Cgeneral%7Cnamespacealiases&formatversion=2&origin=*")!
        URLSession.shared.dataTask(with: siteInfoURL) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(WikipediaLanguageUtilityAPIError.generic))
                return
            }
            do {
                let result = try JSONDecoder().decode(SiteInfo.self, from: data)
                completion(.success(result))
            } catch let error {
                completion(.failure(error))
            }
        }.resume()
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
    struct General: Codable {
        let mainpage: String
    }
    struct Query: Codable {
        let general: General
        let namespaces: [String: Namespace]
    }
    let query: Query
}
