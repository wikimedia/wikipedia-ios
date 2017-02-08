
@objc public enum WMFAccountCreatorErrorType: Int {
    case cannotExtractStatus
    case statusNotPass
    case needsCaptcha
}

// A CustomNSError's localized description survives @objc bridging
// TODO: once WMFAuthenticationManager is converted to Swift we can go 
// back to "public enum WMFAccountCreatorError: LocalizedError" before this commit.
public class WMFAccountCreatorError: CustomNSError {
    let type: WMFAccountCreatorErrorType
    let localizedDescription: String?
    public required init(type:WMFAccountCreatorErrorType, localizedDescription: String?) {
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

public typealias WMFAccountCreatorResultBlock = (WMFAccountCreatorResult) -> Void

public class WMFAccountCreatorResult: NSObject {
    var status: String
    var username: String
    var message: String?
    init(status: String, username: String, message: String?) {
        self.status = status
        self.username = username
        self.message = message
    }
}

public class WMFAccountCreator: NSObject {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    public func createAccount(username: String, password: String, retypePassword: String, email: String?, captchaID: String?, captchaWord: String?, token: String, siteURL: URL, success: @escaping WMFAccountCreatorResultBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        
        var parameters = [
            "action": "createaccount",
            "username": username,
            "password": password,
            "retype": retypePassword,
            "createreturnurl": "https://www.wikipedia.org",
            "email": email,
            "createtoken": token,
            "format": "json"
        ]
        if let captchaID = captchaID {
            parameters["captchaId"] = captchaID
        }
        if let captchaWord = captchaWord {
            parameters["captchaWord"] = captchaWord
        }
        
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: {
            (_, response: Any?) in
         
            guard
                let response = response as? [String : AnyObject],
                let createaccount = response["createaccount"] as? [String : AnyObject],
                let status = createaccount["status"] as? String
                else {
                    failure(WMFAccountCreatorError.init(type:.cannotExtractStatus, localizedDescription: "Could not extract status"))
                    return
            }
            let message = createaccount["message"] as? String ?? ""
            guard status == "PASS" else {
                if message.lowercased().range(of:"missing captcha") != nil {
                    // Note: must check the message because no other checkable info is returned indicating a captcha is needed.
                    failure(WMFAccountCreatorError.init(type:.needsCaptcha, localizedDescription: "Needs captcha"))
                }else{
                    failure(WMFAccountCreatorError.init(type:.statusNotPass, localizedDescription: message))
                }
                return
            }
            let normalizedUsername = createaccount["username"] as? String ?? username
            success(WMFAccountCreatorResult.init(status: status, username: normalizedUsername, message: message))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
