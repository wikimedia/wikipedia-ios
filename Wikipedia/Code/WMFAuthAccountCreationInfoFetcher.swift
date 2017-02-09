
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

public class WMFAuthAccountCreationInfo: NSObject {
    let canCreateAccounts:Bool
    let captchaID: String
    let captchaURLFragment: String
    init(canCreateAccounts:Bool, captchaID:String, captchaURLFragment:String) {
        self.canCreateAccounts = canCreateAccounts
        self.captchaID = captchaID
        self.captchaURLFragment = captchaURLFragment
    }    
    var captchaImageURL: URL? {
        guard let appLang = MWKLanguageLinkController.sharedInstance().appLanguage else {
            return nil
        }
        let siteURL = appLang.siteURL() as NSURL
        guard let domain = siteURL.wmf_domain else {
            return nil
        }
        let url = URL.init(string: "https://\(appLang.languageCode).m.\(domain)\(captchaURLFragment)")
        return url
    }
}

public class WMFAuthAccountCreationInfoFetcher: NSObject {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
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
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: {
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
            
            success(WMFAuthAccountCreationInfo.init(canCreateAccounts: true, captchaID: captchaIdValue, captchaURLFragment: captchaInfoValue))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
