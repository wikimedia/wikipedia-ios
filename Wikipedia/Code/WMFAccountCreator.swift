
public enum WMFAccountCreatorError: LocalizedError {
    case cannotExtractStatus
    case statusNotPass(String?)
    case wrongCaptcha
    case usernameUnavailable
    public var errorDescription: String? {
        switch self {
        case .cannotExtractStatus:
            return "Could not extract status"
        case .statusNotPass(let message?):
            return message
        case .wrongCaptcha:
            return localizedStringForKeyFallingBackOnEnglish("field-alert-captcha-invalid")
        case .usernameUnavailable:
            return localizedStringForKeyFallingBackOnEnglish("field-alert-username-unavailable")
        default:
            return "Unable to create account: Reason unknown"
        }
    }
}

public typealias WMFAccountCreatorResultBlock = (WMFAccountCreatorResult) -> Void

public struct WMFAccountCreatorResult {
    var status: String
    var username: String
    var message: String?
    init(status: String, username: String, message: String?) {
        self.status = status
        self.username = username
        self.message = message
    }
}

public class WMFAccountCreator {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager.operationQueue.operationCount > 0
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
        
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: { (_, response) in
         
            guard
                let response = response as? [String : AnyObject],
                let createaccount = response["createaccount"] as? [String : AnyObject],
                let status = createaccount["status"] as? String
                else {
                    failure(WMFAccountCreatorError.cannotExtractStatus)
                    return
            }
            let message = createaccount["message"] as? String ?? ""
            guard status == "PASS" else {
                if let messageCode = createaccount["messagecode"] as? String {
                    switch messageCode {
                    case "captcha-createaccount-fail":
                        failure(WMFAccountCreatorError.wrongCaptcha)
                        return
                    case "userexists":
                        failure(WMFAccountCreatorError.usernameUnavailable)
                        return
                    default: break
                    }
                }
                failure(WMFAccountCreatorError.statusNotPass(message))
                return
            }
            let normalizedUsername = createaccount["username"] as? String ?? username
            success(WMFAccountCreatorResult.init(status: status, username: normalizedUsername, message: message))
        }, failure: { (_, error) in
            failure(error)
        })
    }
}
