import Foundation
import WMF

class TalkPageArchivesFetcher: Fetcher {
    
    struct APIResponse: Codable {
        struct Query: Codable {
            let pages: [Page]?
        }
        struct Page: Codable {
            let pageid: Int?
            let ns: Int?
            let title: String?
            let displaytitle: String?
        }
        let query: Query?
    }
    
    func fetchArchives(pageTitle: String, siteURL: URL) async throws -> APIResponse {

        let parameters: [String: Any] = [
            "action": "query",
            "prop": "info",
            "generator": "prefixsearch",
            "inprop": "varianttitles|displaytitle",
            "gpssearch": pageTitle,
            "gpslimit": 30,
            "errorformat": "html",
            "errorsuselocal": 1,
            "format": "json",
            "formatversion": 2
        ]
        
        let result: APIResponse = try await performDecodableMediaWikiAPIGet(for: siteURL, with: parameters)
        return result
    }
}
