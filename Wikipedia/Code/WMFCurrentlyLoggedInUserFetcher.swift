
@objc public enum WMFCurrentlyLoggedInUserFetcherErrorType: Int {
    case cannotExtractUserInfo
    case userIsAnonymous
    case blankUsernameOrPassword
}

// A CustomNSError's localized description survives @objc bridging
// TODO: once WMFAuthenticationManager is converted to Swift we can go
// back to using "public enum WMFCurrentlyLoggedInUserFetcherError: LocalizedError".
public class WMFCurrentlyLoggedInUserFetcherError: CustomNSError {
    let type: WMFCurrentlyLoggedInUserFetcherErrorType
    let localizedDescription: String?
    public required init(type:WMFCurrentlyLoggedInUserFetcherErrorType, localizedDescription: String?) {
        self.type = type
        self.localizedDescription = localizedDescription
    }
    public static var errorDomain: String {
        return String(describing:self)
    }
    public var errorCode: Int {
        return type.rawValue
    }
    public var errorUserInfo: [String : Any] {
        var userInfo = [String: Any]()
        if let localizedDescription = self.localizedDescription {
            userInfo[NSLocalizedDescriptionKey] = localizedDescription
        }
        return userInfo
    }
}

public typealias WMFCurrentlyLoggedInUserBlock = (WMFCurrentlyLoggedInUser) -> Void

@objc public class WMFCurrentlyLoggedInUser: NSObject {
    var userID: Int
    var name: String
    init(userID: Int, name: String) {
        self.userID = userID
        self.name = name
    }
}

public class WMFCurrentlyLoggedInUserFetcher: NSObject {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    public func fetch(siteURL: URL, success: @escaping WMFCurrentlyLoggedInUserBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        
        let parameters = [
            "action": "query",
            "meta": "userinfo",
            "format": "json"
        ]
        
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: {
            (_, response: Any?) in
            guard
                let response = response as? [String : AnyObject],
                let query = response["query"] as? [String : AnyObject],
                let userinfo = query["userinfo"] as? [String : AnyObject],
                let userID = userinfo["id"] as? Int,
                let userName = userinfo["name"] as? String
                else {
                    failure(WMFCurrentlyLoggedInUserFetcherError.init(type:.cannotExtractUserInfo, localizedDescription: "Could not extract user info"))
                    return
            }
            guard (userinfo["anon"] == nil) else {
                failure(WMFCurrentlyLoggedInUserFetcherError.init(type:.userIsAnonymous, localizedDescription: "User is anonymous"))
                return
            }
            success(WMFCurrentlyLoggedInUser.init(userID: userID, name: userName))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
