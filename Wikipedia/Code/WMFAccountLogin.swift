
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
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, captchaID: String?, captchaWord: String?, siteURL: URL, reattemptOn401Response: Bool = false, success: @escaping WMFAccountLoginResultBlock, failure: @escaping WMFErrorHandler){
        
        var parameters = [
            "action": "clientlogin",
            "username": username,
            "password": password,
            "loginreturnurl": "https://www.wikipedia.org",
            "rememberMe": "1",
            "format": "json"
        ]
        
        if let retypePassword = retypePassword {
            parameters["retype"] = retypePassword
            parameters["logincontinue"] = "1"
        }

        if let oathToken = oathToken {
            parameters["OATHToken"] = oathToken
            parameters["logincontinue"] = "1"
        }
        
        if let captchaID = captchaID {
            parameters["captchaId"] = captchaID
        }
        if let captchaWord = captchaWord {
            parameters["captchaWord"] = captchaWord
        }

        performTokenizedMediaWikiAPIPOST(tokenType: .login, to: siteURL, with: parameters, reattemptLoginOn401Response:  reattemptOn401Response) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let clientlogin = result?["clientlogin"] as? [String : Any],
                let status = clientlogin["status"] as? String
                else {
                    failure(WMFAccountLoginError.cannotExtractLoginStatus)
                    return
            }
            let message = clientlogin["message"] as? String ?? nil
            guard status == "PASS" else {
                
                if let messageCode = clientlogin["messagecode"] as? String {
                    switch(messageCode) {
                    case "wrongpassword":
                        failure(WMFAccountLoginError.wrongPassword(message))
                        return
                    case "oathauth-login-failed":
                        failure(WMFAccountLoginError.wrongToken)
                        return
                    default: break
                    }
                }

                if
                    status == "UI",
                    let requests = clientlogin["requests"] as? [AnyObject]
                {
                    if let passwordAuthRequest = requests.first(where: { request in
                        guard let id = request["id"] as? String else {
                            return false
                        }
                        return id.hasSuffix("PasswordAuthenticationRequest")
                    }),
                        let fields = passwordAuthRequest["fields"] as? [String : AnyObject],
                        let _ = fields["password"] as? [String : AnyObject],
                        let _ = fields["retype"] as? [String : AnyObject]
                    {
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
                        let _ = fields["OATHToken"] as? [String : AnyObject]
                    {
                        failure(WMFAccountLoginError.needsOathTokenFor2FA(message))
                        return
                    }
                }
                
                failure(WMFAccountLoginError.statusNotPass(message))
                return
            }
            let normalizedUsername = clientlogin["username"] as? String ?? username
            success(WMFAccountLoginResult.init(status: status, username: normalizedUsername, message: message))
        }
    }
}
