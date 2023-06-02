import CocoaLumberjackSwift

public enum WMFAccountLoginError: LocalizedError {
    case cannotExtractLoginStatus
    case statusNotPass(String?)
    case temporaryPasswordNeedsChange(String?)
    case needsOathTokenFor2FA(String?)
    case wrongPassword(String?)
    case wrongToken
    public var errorDescription: String? {
        switch self {
        case .cannotExtractLoginStatus:
            return "Could not extract login status"
        case .statusNotPass(let message?):
            return message
        case .temporaryPasswordNeedsChange(let message?):
            return message
        case .needsOathTokenFor2FA(let message?):
            return message
        case .wrongPassword(let message?):
            return message
        case .wrongToken:
            return WMFLocalizedString("field-alert-token-invalid", value:"Invalid code", comment:"Alert shown if token is not correct")
        default:
            return "Unable to login: Reason unknown"
        }
    }
}

public typealias WMFAccountLoginResultBlock = (WMFAccountLoginResult) -> Void

public class WMFAccountLoginResult: NSObject {
    public struct Status {
        static let offline = "offline"
    }
    @objc var status: String
    @objc var username: String
    @objc var message: String?
    @objc init(status: String, username: String, message: String?) {
        self.status = status
        self.username = username
        self.message = message
    }
}

public class WMFAccountLogin: Fetcher {
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, captchaID: String?, captchaWord: String?, siteURL: URL, reattemptOn401Response: Bool = false, success: @escaping WMFAccountLoginResultBlock, failure: @escaping WMFErrorHandler) {
        
        DDLogError("Notifications_Auth_Debug - entering login. WMFAccountLogin")
        
        var parameters = [
            "action": "clientlogin",
            "username": username,
            "password": password,
            "loginreturnurl": "https://www.wikipedia.org",
            "rememberMe": "1",
            "format": "json"
        ]
        
        if let retypePassword = retypePassword {
            DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. retypePassword populated.")
            parameters["retype"] = retypePassword
            parameters["logincontinue"] = "1"
        }

        if let oathToken = oathToken {
            DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. oathToken populated.")
            parameters["OATHToken"] = oathToken
            parameters["logincontinue"] = "1"
        }
        
        if let captchaID = captchaID {
            DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. captchaID populated.")
            parameters["captchaId"] = captchaID
        }
        if let captchaWord = captchaWord {
            DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. captchaWord populated.")
            parameters["captchaWord"] = captchaWord
        }

        DDLogError("Notifications_Auth_Debug - performing Login POST. WMFAccountLogin")
        performTokenizedMediaWikiAPIPOST(tokenType: .login, to: siteURL, with: parameters, reattemptLoginOn401Response:  reattemptOn401Response) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let clientlogin = result?["clientlogin"] as? [String : Any],
                let status = clientlogin["status"] as? String
                else {
                    DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. Unable to extract login status. ")
                    failure(WMFAccountLoginError.cannotExtractLoginStatus)
                    return
            }
            let message = clientlogin["message"] as? String ?? nil
            guard status == "PASS" else {
                DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. status not PASS")
                if let messageCode = clientlogin["messagecode"] as? String {
                    switch messageCode {
                    case "wrongpassword":
                        DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. status not PASS. wrongpassword messagecode")
                        failure(WMFAccountLoginError.wrongPassword(message))
                        return
                    case "oathauth-login-failed":
                        DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. status not PASS. oathauth-login-failed messagecode")
                        failure(WMFAccountLoginError.wrongToken)
                        return
                    default:
                        DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. status not PASS. unknown messagecode")
                    }
                }

                if
                    status == "UI",
                    let requests = clientlogin["requests"] as? [AnyObject]
                {
                    DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. status not PASS. status UI with requests")
                    if let passwordAuthRequest = requests.first(where: { request in
                        guard let id = request["id"] as? String else {
                            return false
                        }
                        return id.hasSuffix("PasswordAuthenticationRequest")
                    }),
                        let fields = passwordAuthRequest["fields"] as? [String : AnyObject],
                        fields["password"] as? [String : AnyObject] != nil,
                        fields["retype"] as? [String : AnyObject] != nil {
                        DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. status UI with requests: temporaryPasswordNeedsChange")
                        failure(WMFAccountLoginError.temporaryPasswordNeedsChange(message))
                        return
                    }
                    if let OATHTokenRequest = requests.first(where: { request in
                        guard let id = request["id"] as? String else {
                            return false
                        }
                        return id.hasSuffix("TOTPAuthenticationRequest")
                    }),
                        let fields = OATHTokenRequest["fields"] as? [String : AnyObject],
                        fields["OATHToken"] as? [String : AnyObject] != nil {
                        DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. status UI with requests: needsOathTokenFor2FA")
                        failure(WMFAccountLoginError.needsOathTokenFor2FA(message))
                        return
                    }
                }
                
                DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. Passing back statusNotPass.")
                failure(WMFAccountLoginError.statusNotPass(message))
                return
            }
            let normalizedUsername = clientlogin["username"] as? String ?? username
            DDLogError("Notifications_Auth_Debug - logging in on WMFAccountLogin. success.")
            success(WMFAccountLoginResult.init(status: status, username: normalizedUsername, message: message))
        }
    }
}
