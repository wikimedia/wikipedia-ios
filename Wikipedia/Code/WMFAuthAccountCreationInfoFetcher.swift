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
}

public class WMFAuthAccountCreationInfoFetcher: Fetcher {
    public func fetchAccountCreationInfoForSiteURL(_ siteURL: URL, success: @escaping WMFAuthAccountCreationInfoBlock, failure: @escaping WMFErrorHandler) {
        let parameters = [
            "action": "query",
            "meta": "authmanagerinfo",
            "amirequestsfor": "create",
            "format": "json"
        ]
        
        performMediaWikiAPIPOST(for: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let query = result?["query"] as? [String : AnyObject],
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
        }
    }
}
