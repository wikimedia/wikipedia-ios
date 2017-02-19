
public enum WMFAuthAccountCreationError: LocalizedError {
    case cannotExtractInfo
    case cannotCreateAccountsNow
    public var errorDescription: String? {
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
    let captcha: WMFCaptcha?
    init(canCreateAccounts:Bool, captcha:WMFCaptcha?) {
        self.canCreateAccounts = canCreateAccounts
        self.captcha = captcha
    }
}

public class WMFAuthAccountCreationInfoFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager.operationQueue.operationCount > 0
    }
    public func fetchAccountCreationInfoForSiteURL(_ siteURL: URL, success: @escaping WMFAuthAccountCreationInfoBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        let parameters = [
            "action": "query",
            "meta": "authmanagerinfo",
            "amirequestsfor": "create",
            "format": "json"
        ]
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: { (_, response) in            
            guard
                let response = response as? [String : AnyObject],
                let query = response["query"] as? [String : AnyObject],
                let authmanagerinfo = query["authmanagerinfo"] as? [String : AnyObject],
                let requests = authmanagerinfo["requests"] as? [[String : AnyObject]]
                else {
                    failure(WMFAuthAccountCreationError.cannotExtractInfo)
                    return
            }
            guard authmanagerinfo["cancreateaccounts"] != nil else {
                failure(WMFAuthAccountCreationError.cannotCreateAccountsNow)
                return
            }
            success(WMFAuthAccountCreationInfo.init(canCreateAccounts: true, captcha: WMFCaptcha.captcha(from: requests)))
        }, failure: { (_, error) in
            failure(error)
        })
    }
}
