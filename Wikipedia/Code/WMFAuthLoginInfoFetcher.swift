
public enum WMFAuthLoginError: LocalizedError {
    case cannotExtractInfo
    case cannotAuthenticateNow
    public var errorDescription: String? {
        switch self {
        case .cannotExtractInfo:
            return "Could not extract login info"
        case .cannotAuthenticateNow:
            return "Unable to login at this time"
        }
    }
}

public typealias WMFAuthLoginInfoBlock = (WMFAuthLoginInfo) -> Void

public struct WMFAuthLoginInfo {
    let canAuthenticateNow:Bool
    let captcha: WMFCaptcha?
    init(canAuthenticateNow:Bool, captcha:WMFCaptcha?) {
        self.canAuthenticateNow = canAuthenticateNow
        self.captcha = captcha
    }
}

public class WMFAuthLoginInfoFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager.operationQueue.operationCount > 0
    }
    public func fetchLoginInfoForSiteURL(_ siteURL: URL, success: @escaping WMFAuthLoginInfoBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        let parameters = [
            "action": "query",
            "meta": "authmanagerinfo",
            "amirequestsfor": "login",
            "format": "json"
        ]
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: { (_, response) in
            
            guard
                let response = response as? [String : AnyObject],
                let query = response["query"] as? [String : AnyObject],
                let authmanagerinfo = query["authmanagerinfo"] as? [String : AnyObject],
                let requests = authmanagerinfo["requests"] as? [[String : AnyObject]]
                else {
                    failure(WMFAuthLoginError.cannotExtractInfo)
                    return
            }
            guard authmanagerinfo["canauthenticatenow"] != nil else {
                failure(WMFAuthLoginError.cannotAuthenticateNow)
                return
            }
            
            success(WMFAuthLoginInfo.init(canAuthenticateNow: true, captcha: WMFCaptcha.captcha(from: requests)))
        }, failure: { (_, error) in
            failure(error)
        })
    }
}
