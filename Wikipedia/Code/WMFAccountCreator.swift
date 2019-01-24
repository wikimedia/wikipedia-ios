
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
            return WMFLocalizedString("field-alert-captcha-invalid", value:"Invalid CAPTCHA", comment:"Alert shown if CAPTCHA is not correct")
        case .usernameUnavailable:
            return WMFLocalizedString("field-alert-username-unavailable", value:"Username not available", comment:"Alert shown if new username is not available")
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

public class WMFAccountCreator: Fetcher {
    public func createAccount(username: String, password: String, retypePassword: String, email: String?, captchaID: String?, captchaWord: String?, siteURL: URL, success: @escaping WMFAccountCreatorResultBlock, failure: @escaping WMFErrorHandler){
        var parameters: [String: String] = [
            "action": "createaccount",
            "username": username,
            "password": password,
            "retype": retypePassword,
            "createreturnurl": "https://www.wikipedia.org",
            "format": "json"
        ]
        if let email = email {
            parameters["email"] = email
        }
        if let captchaID = captchaID {
            parameters["captchaId"] = captchaID
        }
        if let captchaWord = captchaWord {
            parameters["captchaWord"] = captchaWord
        }
        
        performTokenizedMediaWikiAPIPOST(tokenType: .createAccount, to: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let createaccount = result?["createaccount"] as? [String : AnyObject],
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
        }
    }
}
