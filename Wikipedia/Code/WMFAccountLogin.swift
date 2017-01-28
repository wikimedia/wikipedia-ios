
import Foundation

class WMFAccountLogin {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    func login(username: String, password: String, token: String, siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler)
    {
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        
        manager.responseSerializer = WMFMantleJSONResponseSerializer.init(forInstancesOf: WMFAccountLoginResult.self, fromKeypath: "clientlogin")
        
        let params = [
            "action": "clientlogin",
            "username": username,
            "password": password,
            "loginreturnurl": "https://www.wikipedia.org",
            "logintoken": token,
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: completion, failure: failure)
    }
}
