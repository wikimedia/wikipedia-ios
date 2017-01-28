
import Foundation

enum WMFTokenType: String {
    case csrf, login, createaccount
}

class WMFTokensFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    func fetchTokens(tokens: [WMFTokenType], siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        
        manager.responseSerializer = WMFMantleJSONResponseSerializer.init(forInstancesOf: WMFTokens.self, fromKeypath: "query.tokens")
        
        let params = [
            "action": "query",
            "meta": "tokens",
            "type": tokens.map({$0.rawValue}).joined(separator:"|"),
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: completion, failure: failure)
    }
}
