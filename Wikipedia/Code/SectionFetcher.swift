import WMF

class SectionFetcher: Fetcher {
    
    typealias Protection = SectionFetcher.APIResponse.Query.Page.Protection
    
    struct APIResponse: Codable {
        struct Query: Codable {
            struct Page: Codable {
                struct Revision: Codable {
                    struct Slot: Codable {
                        let contentModel: String?
                        let contentFormat: String?
                        let content: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case contentModel = "contentmodel"
                            case contentFormat = "contentformat"
                            case content
                        }
                    }
                    
                    let revid: Int
                    let slots: [String: Slot]?
                }
                
                struct Protection: Codable {
                    let type: String?
                    let level: String?
                    let expiry: String?
                }
                
                let title: String?
                let revisions: [Revision]?
                let protection: [Protection]?
                let restrictionTypes: [String]?
                let actions: [String: [MediaWikiAPIError]]?
                
                enum CodingKeys: String, CodingKey {
                    case title
                    case revisions
                    case protection
                    case restrictionTypes = "restrictiontypes"
                    case actions
                }
            }
            
            let pages: [Page]?
        }
        
        let query: Query?
    }
    
    struct Response {
        let wikitext: String
        let revisionID: Int
        let protection: [Protection]
        let blockedError: MediaWikiAPIDisplayError?
    }
    
    func fetchSection(with sectionID: Int, articleURL: URL, completion: @escaping (Result<Response, Error>) -> Void) {
        guard let title = articleURL.wmf_title else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions|info",
            "rvprop": "content|ids",
            "rvlimit": 1,
            "rvslots": "main",
            "rvsection": sectionID,
            "titles": title,
            "inprop": "protection",
            "meta": "userinfo", // we need the local user ID for event logging
            "continue": "",
            "format": "json",
            "formatversion": 2,
            "errorformat": "html",
            "errorsuselocal": "1",
            "intestactions": "edit", // needed for fully resolved protection error.
            "intestactionsdetail": "full" // needed for fully resolved protection error.
        ]

        performDecodableMediaWikiAPIGET(for: articleURL, with: parameters) { [weak self] (result: Result<APIResponse, Error>) in
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let apiResponse):
                guard
                    let self,
                    let page = apiResponse.query?.pages?.first,
                    let wikitext = page.revisions?.first?.slots?["main"]?.content,
                    let protection = page.protection,
                    let revisionID = page.revisions?.first?.revid
                else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                
                guard let editErrors = page.actions?["edit"] as? [MediaWikiAPIError] else {
                    completion(.success(Response(wikitext: wikitext, revisionID: revisionID, protection: protection, blockedError: nil)))
                    return
                }
                
                self.resolveMediaWikiError(from: editErrors, siteURL: articleURL) { blockedError in
                    
                    guard let blockedError else {
                        completion(.success(Response(wikitext: wikitext, revisionID: revisionID, protection: protection, blockedError: nil)))
                        return
                    }
                    
                    completion(.success(Response(wikitext: wikitext, revisionID: revisionID, protection: protection, blockedError: blockedError)))
                }
            }
        }
        
    }
}
