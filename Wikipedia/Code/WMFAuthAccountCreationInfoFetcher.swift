
import Foundation

enum WMFAuthAccountCreationError: LocalizedError {
    case cannotExtractInfo
    case cannotCreateAccountsNow
    var errorDescription: String? {
        switch self {
        case .cannotExtractInfo:
            return "Could not extract account creation info"
        case .cannotCreateAccountsNow:
            return "Unable to create accounts at this time"
        }
    }
}

public typealias WMFAuthAccountCreationInfoBlock = (WMFAuthAccountCreationInfo) -> Void

public struct WMFAuthAccountCreationInfo {
    let canCreateAccounts:Bool
    let captchaID: String
    let captchaURL: String
    init(canCreateAccounts:Bool, captchaID:String, captchaURL:String) {
        self.canCreateAccounts = canCreateAccounts
        self.captchaID = captchaID
        self.captchaURL = captchaURL
    }
}

class WMFAuthAccountCreationInfoFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    public func fetchAccountCreationInfoForSiteURL(_ siteURL: URL, completion: @escaping WMFAuthAccountCreationInfoBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        let params = [
            "action": "query",
            "meta": "authmanagerinfo",
            "amirequestsfor": "create",
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: {
            (_, response: Any?) in
            
            guard
                let response = response as? [String : AnyObject],
                let query = response["query"] as? [String : AnyObject],
                let authmanagerinfo = query["authmanagerinfo"] as? [String : AnyObject],
                let requests = authmanagerinfo["requests"] as? [[String : AnyObject]],
                let captchaAuthenticationRequest = requests.first(where:{$0["id"]! as! String == "CaptchaAuthenticationRequest"}),
                let fields = captchaAuthenticationRequest["fields"] as? [String : AnyObject],
                let captchaId = fields["captchaId"] as? [String : AnyObject],
                let captchaInfo = fields["captchaInfo"] as? [String : AnyObject],
                let captchaIdValue = captchaId["value"] as? String,
                let captchaInfoValue = captchaInfo["value"] as? String
                else {
                    failure(WMFAuthAccountCreationError.cannotExtractInfo)
                    return
            }
            
            guard authmanagerinfo["cancreateaccounts"] != nil else {
                failure(WMFAuthAccountCreationError.cannotCreateAccountsNow)
                return
            }
            
            completion(WMFAuthAccountCreationInfo.init(canCreateAccounts: true, captchaID: captchaIdValue, captchaURL: captchaInfoValue))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
