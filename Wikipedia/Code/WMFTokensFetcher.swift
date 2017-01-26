
import Foundation

enum WMFApiToken: String {
    case csrf, login, createaccount
}

enum WMFZeroLengthStringError: LocalizedError {
    case invalidString
    var errorDescription: String? {
        return "No valid string value fetched"
    }
}

class WMFApiTokens: MTLModel, MTLJSONSerializing {
    var csrf: String?
    var login: String?
    var createaccount: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return [
            "csrf": "csrftoken",
            "login": "logintoken",
            "createaccount": "createaccounttoken"
        ]
    }
    
    private func validateNotZeroLengthString(_ string: String?) throws {
        if let string = string {
            guard string.characters.count > 0 else {
                throw WMFZeroLengthStringError.invalidString
            }
        }
    }

    override func validate() throws {
        try validateNotZeroLengthString(csrf)
        try validateNotZeroLengthString(login)
        try validateNotZeroLengthString(createaccount)
    }
}

class WMFTokensFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    func fetchTokens(tokens: [WMFApiToken], siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        
        manager.responseSerializer = WMFMantleJSONResponseSerializer.init(forInstancesOf: WMFApiTokens.self, fromKeypath: "query.tokens")
        
        let params = [
            "action": "query",
            "meta": "tokens",
            "type": tokens.map({$0.rawValue}).joined(separator:"|"),
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: completion, failure: failure)
    }
}
