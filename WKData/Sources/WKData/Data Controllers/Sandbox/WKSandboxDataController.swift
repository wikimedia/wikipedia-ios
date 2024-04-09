import Foundation

public final class WKSandboxDataController {
    
    struct LintAPIResponse: Codable {
        
        struct Query: Codable {
            
            struct Item: Codable {
                let pageid: Int
                let namespace: Int
                let title: String
                let lintId: Int
                let category: String
                let location: [Int]
            }
            
            let linterrors: [Item]
        }
        
        let query: Query?
    }
    
    struct WikitextAPIResponse: Codable {
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
                
                let title: String?
                let revisions: [Revision]?
            }
            
            let pages: [Page]?
        }
        
        let query: Query?
    }
    
    struct SandboxesAPIResponse: Codable {
        struct Query: Codable {
            let pages: [Page]?
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
        
        let query: Query?
    }
    
    var service = WKDataEnvironment.current.mediaWikiService
    
    public init() {
        
    }
    
    func getLinterErrors(project: WKProject, title: String, completion: @escaping (Result<LintAPIResponse, Error>) -> Void) {
        var parameters = [
                    "action": "query",
                    "list": "linterrors",
                    "lnttitle": "lnttitle",
                    "errorsuselocal": "1",
                    "errorformat": "html",
                    "format": "json",
                    "formatversion": "2"
                ]
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            return
        }
        
        parameters["variant"] = project.languageVariantCode

        let request = WKMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        service?.performDecodableGET(request: request, completion: completion)
    }
    
    public func getWikitext(project: WKProject, title: String, completion: @escaping(Result<String, Error>) -> Void) {
        
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions|info",
            "rvprop": "content|ids",
            "rvlimit": 1,
            "rvslots": "main",
            "titles": title,
            "format": "json",
            "formatversion": 2
        ]
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            return
        }
        
        let request = WKMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        service?.performDecodableGET(request: request, completion: { (result: Result<WikitextAPIResponse, Error>) in
        
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let apiResponse):
                guard
                    let page = apiResponse.query?.pages?.first,
                    let wikitext = page.revisions?.first?.slots?["main"]?.content
                else {
                    completion(.failure(WKDataControllerError.unexpectedResponse))
                    return
                }
                
                completion(.success(wikitext))
            }
            
        })
    }
    
    public func saveWikitextToSandbox(project: WKProject, username: String, sandboxTitle: String, wikitext: String, completion: @escaping(Result<Void, Error>) -> Void) {
        let parameters: [String: String] = [
            "action": "edit",
            "title": "User:\(username.spacesToUnderscores)/AppsOffsite2024/\(sandboxTitle)",
            "appendtext": wikitext,
            "recreate": "true",
            "format": "json",
            "formatversion": "2"
        ]
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            return
        }
        
        let request = WKMediaWikiServiceRequest(url: url, method: .POST, backend: .mediaWiki, tokenType: .csrf, parameters: parameters)
        service?.perform(request: request) { result in
            switch result {
            case .success(let response):
                guard let edit = response?["edit"] as? [String: Any],
                      let success = edit["result"] as? String,
                      success == "Success" else {
                    completion(.failure(WKDataControllerError.unexpectedResponse))
                    return
                }

                completion(.success(()))
            case .failure(let error):
                completion(.failure(WKDataControllerError.serviceError(error)))
            }
        }
    }
    
    public func fetchSandboxArticles(project: WKProject, username: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "info",
            "generator": "prefixsearch",
            "inprop": "varianttitles|displaytitle",
            "gpssearch": "User:\(username)/AppsOffsite2024/",
            "gpslimit": 30,
            "errorformat": "html",
            "errorsuselocal": 1,
            "format": "json",
            "formatversion": 2
        ]
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            return
        }
        
        let request = WKMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        service?.performDecodableGET(request: request, completion: { (result: Result<SandboxesAPIResponse, Error>) in
        
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let apiResponse):
                
                let titles = apiResponse.query?.pages?.compactMap {  $0.title } ?? []
                completion(.success(titles))
            }
        })
    }
}
