import CocoaLumberjackSwift

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
    @objc public var userID: Int
    @objc public var name: String
    @objc public var groups: [String]
    init(userID: Int, name: String, groups: [String]) {
        self.userID = userID
        self.name = name
        self.groups = groups
    }
}

public class WMFCurrentlyLoggedInUserFetcher: Fetcher {
    public func fetch(siteURL: URL, success: @escaping WMFCurrentlyLoggedInUserBlock, failure: @escaping WMFErrorHandler) {
        
        DDLogError("Notifications_Auth_Debug - entering fetch for WMFCurrentlyLoggedInUserFetcher")
        let parameters = [
            "action": "query",
            "meta": "userinfo",
            "uiprop": "groups",
            "format": "json"
        ]
        
        DDLogError("Notifications_Auth_Debug - performing fetch POST in WMFCurrentlyLoggedInUserFetcher")
        performMediaWikiAPIPOST(for: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                DDLogError("Notifications_Auth_Debug - error in fetch POST for WMFCurrentlyLoggedInUserFetcher. \(error)")
                failure(error)
                return
            }
            guard
                let query = result?["query"] as? [String : Any],
                let userinfo = query["userinfo"] as? [String : Any],
                let userID = userinfo["id"] as? Int,
                let userName = userinfo["name"] as? String
                else {
                    DDLogError("Notifications_Auth_Debug - failure extracting user info fetch POST for WMFCurrentlyLoggedInUserFetcher.")
                    failure(WMFCurrentlyLoggedInUserFetcherError.cannotExtractUserInfo)
                    return
            }
            guard userinfo["anon"] == nil else {
                DDLogError("Notifications_Auth_Debug - fetch POST, userIsAnonymous. for WMFCurrentlyLoggedInUserFetcher.")
                failure(WMFCurrentlyLoggedInUserFetcherError.userIsAnonymous)
                return
            }
            let groups = userinfo["groups"] as? [String] ?? []
            DDLogError("Notifications_Auth_Debug - fetch POST, success. groups: \(groups.count). for WMFCurrentlyLoggedInUserFetcher.")
            success(WMFCurrentlyLoggedInUser.init(userID: userID, name: userName, groups: groups))
        }
    }
}
