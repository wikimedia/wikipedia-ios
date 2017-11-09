
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
    private let session = Session.shared
    
    public func fetch(siteURL: URL, success userSuccess: @escaping WMFCurrentlyLoggedInUserBlock, failure userFailure: @escaping WMFErrorHandler){
        let parameters = [
            "action": "query",
            "meta": "userinfo",
            "format": "json"
        ]
        
        let failure = { (error: Error) in
            DispatchQueue.main.async {
                userFailure(error)
            }
        }
        
        let success = { (result: WMFCurrentlyLoggedInUser) in
            DispatchQueue.main.async {
                userSuccess(result)
            }
        }
        _ = session.mediaWikiAPITask(host: siteURL.host ?? WMFDefaultSiteDomain, queryParameters: parameters, completionHandler: { (result, response, error) in
            guard
                error == nil,
                let result = result,
                let query = result["query"] as? [String : AnyObject],
                let userinfo = query["userinfo"] as? [String : AnyObject],
                let userID = userinfo["id"] as? Int,
                let userName = userinfo["name"] as? String
                else {
                    failure(error ?? WMFCurrentlyLoggedInUserFetcherError.cannotExtractUserInfo)
                    return
            }
            guard (userinfo["anon"] == nil) else {
                failure(WMFCurrentlyLoggedInUserFetcherError.userIsAnonymous)
                return
            }
            success(WMFCurrentlyLoggedInUser.init(userID: userID, name: userName))
        })?.resume()
    }
}
