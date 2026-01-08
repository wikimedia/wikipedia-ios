import WMFData

public enum WMFAccountLoginError: LocalizedError {
    case cannotExtractLoginStatus
    case statusNotPass(String?)
    case temporaryPasswordNeedsChange(String?)
    case needsOathTokenFor2FA(String?)
    case needsEmailAuthToken(String?)
    case wrongPassword(String?)
    case wrongToken
    case captchaRequired(String?)
    case authManagerInfoRequired(String?, [String: Any])
    case failedToParseAuthManagerInfo
    case invalidSiteURL

    public var errorDescription: String? {
        switch self {
        case .cannotExtractLoginStatus:
            return "Could not extract login status"
        case .statusNotPass(let message?),
             .temporaryPasswordNeedsChange(let message?),
             .needsOathTokenFor2FA(let message?),
             .needsEmailAuthToken(let message?),
             .wrongPassword(let message?),
             .captchaRequired(let message?),
             .authManagerInfoRequired(let message?, _):
            return message
        case .wrongToken:
            return WMFLocalizedString("field-alert-token-invalid", value:"Invalid code", comment:"Alert shown if token is not correct")
        default:
            return "Unable to login: Reason unknown"
        }
    }
}

public typealias Username = String

public class WMFAccountLoginLogoutFetcher: Fetcher {
    
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, emailAuthCode: String?, captchaID: String?, captchaWord: String?, siteURL: URL, reattemptOn401Response: Bool = false, attempt: Int = 0, newModule: String? = nil, success: @escaping (Username) -> Void, failure: @escaping WMFErrorHandler) {
        
        let attempt = attempt + 1

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

        if let emailAuthCode {
            parameters["token"] = emailAuthCode
            parameters["logincontinue"] = "1"
        }

        if let captchaID = captchaID {
            parameters["captchaId"] = captchaID
        }
        if let captchaWord = captchaWord {
            parameters["captchaWord"] = captchaWord
        }
        
        if let newModule {
            parameters["newModule"] = newModule
            parameters["logincontinue"] = "1"
        }

        if WMFDeveloperSettingsDataController.shared.forceEmailAuth {
            self.session.injectEmailAuthCookie()
        }
        
        performTokenizedMediaWikiAPIPOST(tokenType: .login, to: siteURL, with: parameters, reattemptLoginOn401Response:  reattemptOn401Response) { [weak self] (result, response, error) in
            
            guard let self else { return }
            
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
                if status == "FAIL" {
                    self.fetchAuthManagerInfo(from: siteURL) { result in
                        switch result {
                        case .failure(let error):
                            failure(error)
                        case .success(let authInfo):
                            guard let requests = authInfo["requests"] as? [[String: Any]] else {
                                failure(WMFAccountLoginError.failedToParseAuthManagerInfo)
                                return
                            }

                            if let captchaRequest = requests.first(where: { ($0["id"] as? String)?.hasSuffix("CaptchaAuthenticationRequest") == true }),
                               let fields = captchaRequest["fields"] as? [String: Any],
                               let captchaField = fields["captchaId"] as? [String: Any],
                               let captchaId = captchaField["value"] as? String {
                                failure(WMFAccountLoginError.captchaRequired(captchaId))
                                return
                            }

                            failure(WMFAccountLoginError.statusNotPass(message))
                        }
                    }
                    return
                }
                
                if let messageCode = clientlogin["messagecode"] as? String {
                    switch messageCode {
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
                    let requests = clientlogin["requests"] as? [AnyObject] {
                    
                    if let passwordAuthRequest = requests.first(where: { request in
                        guard let id = request["id"] as? String else {
                            return false
                        }
                        return id.hasSuffix("PasswordAuthenticationRequest")
                    }),
                        let fields = passwordAuthRequest["fields"] as? [String : AnyObject],
                        fields["password"] is [String : AnyObject],
                        fields["retype"] is [String : AnyObject] {
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
                        fields["OATHToken"] is [String : AnyObject] {
                        failure(WMFAccountLoginError.needsOathTokenFor2FA(message))
                        return
                    }
                    
                    if let twoFactorModuleSelectRequest = requests.first(where: { request in
                        guard let id = request["id"] as? String else {
                            return false
                        }
                        return id.hasSuffix("TwoFactorModuleSelectAuthenticationRequest")
                    }),
                       let metadata = twoFactorModuleSelectRequest["metadata"] as? [String: Any],
                       let allowedModules = metadata["allowedModules"] as? [String],
                       allowedModules.contains("totp"),
                       attempt == 1 {
                        // repeat call once, passing in "newModule=totp" https://phabricator.wikimedia.org/T399654#11133473
                        login(username: username, password: password, retypePassword: retypePassword, oathToken: oathToken, emailAuthCode: emailAuthCode, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL, attempt: attempt, newModule: "totp", success: success, failure: failure)
                        return
                    }

                    if let emailAuthRequests = requests.first(where: { request in
                        guard let id = request["id"] as? String else {
                            return false
                        }
                        return id.hasSuffix("EmailAuthAuthenticationRequest")
                    }),
                       let fields = emailAuthRequests["fields"] as? [String : AnyObject],
                       fields["token"] is [String : AnyObject] { // email auth token
                        failure(WMFAccountLoginError.needsEmailAuthToken(message))
                        return
                    }
                }
                
                failure(WMFAccountLoginError.statusNotPass(message))
                return
            }
            let normalizedUsername = clientlogin["username"] as? String ?? username
            success(normalizedUsername)
        }
    }
    
    func logout(loginSiteURL: URL, reattemptOn401Response: Bool = false, completion: @escaping (Error?) -> Void) {
        performTokenizedMediaWikiAPIPOST(to: loginSiteURL, with: ["action": "logout", "format": "json"], reattemptLoginOn401Response: reattemptOn401Response) { (result, response, error) in
            completion(error)
        }
    }

    private func fetchAuthManagerInfo(from siteURL: URL, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let parameters = [
            "action": "query",
            "meta": "authmanagerinfo",
            "format": "json",
            "formatversion": "2",
            "amirequestsfor": "login",
            "amimergerequestfields": "1"
        ]

        _ = performMediaWikiAPIPOST(for: siteURL, with: parameters) { result, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard
                let result = result,
                let query = result["query"] as? [String: Any],
                let authManagerInfo = query["authmanagerinfo"] as? [String: Any]
            else {
                completion(.failure(WMFAccountLoginError.failedToParseAuthManagerInfo))
                return
            }

            completion(.success(authManagerInfo))
        }
    }
}
