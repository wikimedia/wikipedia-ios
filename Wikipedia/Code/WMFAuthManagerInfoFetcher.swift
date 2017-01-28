
import Foundation

extension WMFAuthManagerInfo2 {
    func captchaId() -> String? {
        return requests?.first(where:{$0.id! == "CaptchaAuthenticationRequest"})?.fields?.captchaId?.value
        
    }
    func captchaInfo() -> String? {
        return requests?.first(where:{$0.id! == "CaptchaAuthenticationRequest"})?.fields?.captchaInfo?.value
    }
}

class WMFAuthManagerInfoFetcher2 {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    func fetchAuthManagerCreationAvailableForSiteURL(_ siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        fetchAuthManagerAvailableForSiteURL(siteURL, type: "create", completion: completion, failure: failure)
    }

    func fetchAuthManagerLoginAvailableForSiteURL(_ siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        fetchAuthManagerAvailableForSiteURL(siteURL, type: "login", completion: completion, failure: failure)
    }
    
    private func fetchAuthManagerAvailableForSiteURL(_ siteURL: URL, type: String, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        
        manager.responseSerializer = WMFMantleJSONResponseSerializer.init(forInstancesOf: WMFAuthManagerInfo2.self, fromKeypath: "query.authmanagerinfo")
        
        let params = [
            "action": "query",
            "meta": "authmanagerinfo",
            "amirequestsfor": type,
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: completion, failure: failure)
    }
}
