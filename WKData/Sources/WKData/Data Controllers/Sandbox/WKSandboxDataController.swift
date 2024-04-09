import Foundation

final class WKSandboxDataController {
    
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
    
    var service = WKDataEnvironment.current.mediaWikiService
    
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
}
