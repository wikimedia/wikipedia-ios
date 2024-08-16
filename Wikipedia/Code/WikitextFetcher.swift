import WMF

class WikitextFetcher: Fetcher {
    
    typealias Protection = WikitextFetcher.APIResponse.Query.Page.Protection
    
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
            let userInfo: UserInfo?

            enum CodingKeys: String, CodingKey {
                case pages
                case userInfo = "userinfo"
            }
        }
        
        let query: Query?
    }
    
    struct Response {
        let wikitext: String
        let revisionID: Int
        let protection: [Protection]
        let apiError: MediaWikiAPIDisplayError?
        let userInfo: UserInfo?
    }

    struct UserInfo: Codable {
        let groups: [String]?
    }
    
    func fetchSection(with sectionID: Int?, articleURL: URL, revisionID: UInt64? = nil, completion: @escaping (Result<Response, Error>) -> Void) {
        
        let title = articleURL.wmf_title
        
        guard title != nil || revisionID != nil else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        var parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions|info",
            "rvprop": "content|ids",
            "rvslots": "main",
            "inprop": "protection",
            "meta": "userinfo", // we need the local user ID for event logging
            "uiprop": "groups",
            "continue": "",
            "format": "json",
            "formatversion": 2,
            "errorformat": "html",
            "errorsuselocal": "1",
            "intestactions": "edit", // needed for fully resolved protection error.
            "intestactionsdetail": "full" // needed for fully resolved protection error.
        ]
        
        if let title,
           revisionID == nil {
            parameters["titles"] = title
            parameters["rvlimit"] = 1
        }
        
        if let sectionID {
            parameters["rvsection"] = sectionID
        }
        
        if let revisionID {
            parameters["revids"] = revisionID
        }

        performDecodableMediaWikiAPIGET(for: articleURL, with: parameters) { [weak self] (result: Result<APIResponse, Error>) in
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let apiResponse):
                guard
                    let self,
                    let page = apiResponse.query?.pages?.first,
                    let userInfo = apiResponse.query?.userInfo,
                    let wikitext = page.revisions?.first?.slots?["main"]?.content,
                    let protection = page.protection,
                    let revisionID = page.revisions?.first?.revid
                else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }

                guard let editErrors = page.actions?["edit"] as? [MediaWikiAPIError] else {
                    completion(.success(Response(wikitext: wikitext, revisionID: revisionID, protection: protection, apiError: nil, userInfo: userInfo)))
                    return
                }
                
                self.resolveMediaWikiError(from: editErrors, siteURL: articleURL) { blockedError in
                    completion(.success(Response(wikitext: wikitext, revisionID: revisionID, protection: protection, apiError: blockedError, userInfo: userInfo)))
                }
            }
        }
        
    }
}
