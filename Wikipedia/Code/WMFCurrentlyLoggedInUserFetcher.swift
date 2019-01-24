
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

public class WMFCurrentlyLoggedInUserFetcher: Fetcher {
    public func fetch(siteURL: URL, success: @escaping WMFCurrentlyLoggedInUserBlock, failure: @escaping WMFErrorHandler){
        let parameters = [
            "action": "query",
            "meta": "userinfo",
            "format": "json"
        ]
        
        performMediaWikiAPIPOST(for: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let query = result?["query"] as? [String : Any],
                let userinfo = query["userinfo"] as? [String : Any],
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
        }
    }
}
