import Foundation
import WMF

class TalkPageArchivesFetcher: Fetcher {

    struct APIResponse: Codable {
        struct Query: Codable {
            let pages: [Page]?
        }
        struct Continue: Codable {
            let gpsOffset: Int?
            
            enum CodingKeys: String, CodingKey {
                case gpsOffset = "gpsoffset"
            }
        }
        
        struct Page: Codable {
            let pageID: Int?
            let ns: Int?
            let title: String?
            let displayTitle: String?
            
            enum CodingKeys: String, CodingKey {
                case pageID = "pageid"
                case ns = "ns"
                case title = "title"
                case displayTitle = "displaytitle"
            }
        }
        
        let `continue`: Continue?
        let query: Query?
    }
    
    private let siteURL: URL
    private let pageTitle: String
    private var gpsOffset: Int?
    
    required init(siteURL: URL, pageTitle: String) {
        self.siteURL = siteURL
        self.pageTitle = pageTitle
        
        let dataStore = MWKDataStore.shared()
        super.init(session: dataStore.session, configuration: dataStore.configuration)
    }
    
    @objc required init(session: Session, configuration: Configuration) {
        fatalError("init(session:configuration:) has not been implemented")
    }
    
    func fetchFirstPage() async throws -> APIResponse {
        
        gpsOffset = nil
        
        let result = try await fetchArchives(pageTitle: pageTitle, siteURL: siteURL, gpsOffset: nil)
        gpsOffset = result.continue?.gpsOffset
        return result
    }
    
    func fetchNextPage() async throws -> APIResponse? {
        
        guard let gpsOffset else {
            return nil
        }
        
        let result = try await fetchArchives(pageTitle: pageTitle, siteURL: siteURL, gpsOffset: gpsOffset)
        self.gpsOffset = result.continue?.gpsOffset
        return result
    }
    
    private func fetchArchives(pageTitle: String, siteURL: URL, gpsOffset: Int?) async throws -> APIResponse {
        var parameters: [String: Any] = [
            "action": "query",
            "prop": "info",
            "generator": "prefixsearch",
            "inprop": "varianttitles|displaytitle",
            "gpssearch": "\(pageTitle)/",
            "gpslimit": 30,
            "errorformat": "html",
            "errorsuselocal": 1,
            "format": "json",
            "formatversion": 2
        ]
        
        if let gpsOffset {
            parameters["gpslimit"] = 10
            parameters["gpsoffset"] = gpsOffset
        }

        let result: APIResponse = try await performDecodableMediaWikiAPIGet(for: siteURL, with: parameters)
        return result
    }
}
