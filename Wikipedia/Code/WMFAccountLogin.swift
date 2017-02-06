
@objc public enum WMFAccountLoginErrorType: Int {
    case cannotExtractLoginStatus
    case statusNotPass
    case temporaryPasswordNeedsChange
}

// A CustomNSError's localized description survives @objc bridging
// TODO: once WMFAuthenticationManager is converted to Swift we can go
// back to "public enum WMFAccountLoginError: LocalizedError" before this commit.
public class WMFAccountLoginError: CustomNSError {
    let type: WMFAccountLoginErrorType
    let localizedDescription: String?
    public required init(type:WMFAccountLoginErrorType, localizedDescription: String?) {
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

public typealias WMFAccountLoginResultBlock = (WMFAccountLoginResult) -> Void

public class WMFAccountLoginResult: NSObject {
    var status: String
    var username: String
    var message: String?
    init(status: String, username: String, message: String?) {
        self.status = status
        self.username = username
        self.message = message
    }
}

public class WMFAccountLogin: NSObject {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    public func login(username: String, password: String, retypePassword: String?, token: String, siteURL: URL, completion: @escaping WMFAccountLoginResultBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        
        var parameters = [
            "action": "clientlogin",
            "username": username,
            "password": password,
            "loginreturnurl": "https://www.wikipedia.org",
            "logintoken": token,
            "format": "json"
        ]
        
        if let retypePassword = retypePassword {
            parameters["retype"] = retypePassword
            parameters["logincontinue"] = "1"
        }

        _ = manager.wmf_apiPOSTWithParameters(parameters, success: {
            (_, response: Any?) in
            guard
                let response = response as? [String : AnyObject],
                let clientlogin = response["clientlogin"] as? [String : AnyObject],
                let status = clientlogin["status"] as? String
                else {
                    failure(WMFAccountLoginError.init(type:.cannotExtractLoginStatus, localizedDescription: "Could not extract login status"))
                    return
            }
            let message = clientlogin["message"] as? String ?? nil
            guard status == "PASS" else {
                
                if
                    status == "UI",
                    let requests = clientlogin["requests"] as? [AnyObject],
                    let passwordAuthRequest = requests.first(where:{$0["id"]! as! String == "MediaWiki\\Auth\\PasswordAuthenticationRequest"}),
                    let fields = passwordAuthRequest["fields"] as? [String : AnyObject],
                    let _ = fields["password"] as? [String : AnyObject],
                    let _ = fields["retype"] as? [String : AnyObject]
                {
                    failure(WMFAccountLoginError.init(type:.temporaryPasswordNeedsChange, localizedDescription: message))
                    return
                }
                
                failure(WMFAccountLoginError.init(type:.statusNotPass, localizedDescription: message))
                return
            }
            let normalizedUsername = clientlogin["username"] as? String ?? username
            completion(WMFAccountLoginResult.init(status: status, username: normalizedUsername, message: message))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
