
public enum WMFCurrentlyLoggedInUserFetcherError: LocalizedError {
    case cannotExtractUserInfo
    case userIsAnonymous
    case blankUsernameOrPassword
    public var errorDescription: String? {
        switch self {
        case .cannotExtractUserInfo:
            return "Could not extract user info"
        case .userIsAnonymous:
            return "User is anonymous"
        case .blankUsernameOrPassword:
            return "Blank username or password"
        }
    }
}

public typealias WMFCurrentlyLoggedInUserBlock = (WMFCurrentlyLoggedInUser) -> Void

@objc public class WMFCurrentlyLoggedInUser: NSObject {
    @objc var userID: Int
    @objc var name: String
    init(userID: Int, name: String) {
        self.userID = userID
        self.name = name
    }
}

public class WMFCurrentlyLoggedInUserFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager.operationQueue.operationCount > 0
    }
    
    public func fetch(siteURL: URL, success: @escaping WMFCurrentlyLoggedInUserBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        
        let parameters = [
            "action": "query",
            "meta": "userinfo",
            "format": "json"
        ]
        
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: { (_, response) in
            guard
                let response = response as? [String : AnyObject],
                let query = response["query"] as? [String : AnyObject],
                let userinfo = query["userinfo"] as? [String : AnyObject],
                let userID = userinfo["id"] as? Int,
                let userName = userinfo["name"] as? String
                else {
                    failure(WMFCurrentlyLoggedInUserFetcherError.cannotExtractUserInfo)
                    return
            }
            guard (userinfo["anon"] == nil) else {
                failure(WMFCurrentlyLoggedInUserFetcherError.userIsAnonymous)
                return
            }
            success(WMFCurrentlyLoggedInUser.init(userID: userID, name: userName))
        }, failure: { (_, error) in
            failure(error)
        })
    }
}
