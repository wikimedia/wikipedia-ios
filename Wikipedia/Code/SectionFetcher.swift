class SectionFetcher: Fetcher {
    struct Protection: Codable {
        let type: String?
        let level: String?
        let expiry: String?
    }
    
    struct APIResponse: Codable {
        struct Query: Codable {
            let pages: [String: Page]?
        }
        struct Page: Codable {
            let pageid: Int?
            let ns: Int?
            let title: String?
            let revisions: [Revision]?
            let protection: [Protection]?
        }
        struct Revision: Codable  {
            let slots: [String: Slot]?
        }
        struct Slot: Codable {
            let contentmodel: String?
            let contentformat: String?
            let asterisk: String?
            enum CodingKeys: String, CodingKey {
                case contentmodel
                case contentformat
                case asterisk = "*"
            }
        }
        let query: Query?
    }
    
    struct Response {
        let wikitext: String
        let protection: [Protection]
    }
    
    func fetchSection(with sectionID: Int, articleURL: URL, completion: @escaping (Result<Response, Error>) -> Void) {
        guard let title = articleURL.wmf_title else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions|info",
            "rvprop": "content",
            "rvlimit": 1,
            "rvslots": "main",
            "rvsection": sectionID,
            "titles": title,
            "inprop": "protection",
            "meta": "userinfo", // we need the local user ID for event logging
            "continue": "",
            "format": "json"
        ]
        performDecodableMediaWikiAPIGET(for: articleURL, with: parameters) { (result: Result<APIResponse, Error>)  in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let apiResponse):
                guard
                    let page = apiResponse.query?.pages?.first?.value,
                    let wikitext = page.revisions?.first?.slots?["main"]?.asterisk,
                    let protection = page.protection
                else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                completion(.success(Response(wikitext: wikitext, protection: protection)))
            }
        }
        
    }
}
