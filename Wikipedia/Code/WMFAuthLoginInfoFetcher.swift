
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
    public let captcha: WMFCaptcha?
    init(canAuthenticateNow:Bool, captcha:WMFCaptcha?) {
        self.canAuthenticateNow = canAuthenticateNow
        self.captcha = captcha
    }
}

public class WMFAuthLoginInfoFetcher: Fetcher {
    public func fetchLoginInfoForSiteURL(_ siteURL: URL, success: @escaping WMFAuthLoginInfoBlock, failure: @escaping WMFErrorHandler){
        let parameters = [
            "action": "query",
            "meta": "authmanagerinfo",
            "amirequestsfor": "login",
            "format": "json"
        ]
        
        performMediaWikiAPIPOST(for: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let query = result?["query"] as? [String : Any],
                let authmanagerinfo = query["authmanagerinfo"] as? [String : Any],
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
        }
    }
}
