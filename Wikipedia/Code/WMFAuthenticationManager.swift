
/**
 *  This class provides a simple interface for performing authentication tasks.
 */
public class WMFAuthenticationManager: NSObject {
    @objc public static let userLoggedInNotification = NSNotification.Name("WMFUserLoggedInNotification")
    
    /**
     *  The current logged in user. If nil, no user is logged in
     */
    @objc dynamic private(set) var loggedInUsername: String? = nil {
        didSet {
            SessionSingleton.sharedInstance().dataStore.readingListsController.authenticationDelegate = self
            if loggedInUsername != nil {
                NotificationCenter.default.post(name: WMFAuthenticationManager.userLoggedInNotification, object: nil)
            }
        }
    }
    
    /**
     *  Returns YES if a user is logged in, NO otherwise
     */
    @objc public var isLoggedIn: Bool {
        return (loggedInUsername != nil)
    }

    @objc public var hasKeychainCredentials: Bool {
        guard
            let userName = KeychainCredentialsManager.shared.username,
            userName.count > 0,
            let password = KeychainCredentialsManager.shared.password,
            password.count > 0
            else {
                return false
        }
        return true
    }
    
    fileprivate let loginInfoFetcher = WMFAuthLoginInfoFetcher()
    fileprivate let tokenFetcher = WMFAuthTokenFetcher()
    fileprivate let accountLogin = WMFAccountLogin()
    fileprivate let currentlyLoggedInUserFetcher = WMFCurrentlyLoggedInUserFetcher()
    
    /**
     *  Get the shared instance of this class
     *
     *  @return The shared Authentication Manager
     */
    @objc public static let sharedInstance = WMFAuthenticationManager()
    
    var loginSiteURL: URL {
        var baseURL: URL?
        if let host = KeychainCredentialsManager.shared.host {
            var components = URLComponents()
            components.host = host
            components.scheme = "https"
            baseURL = components.url
        }
        
        if baseURL == nil {
//            #if DEBUG
//                let loginHost = "readinglists.wmflabs.org"
//                let loginScheme = "https"
//                var components = URLComponents()
//                components.host = loginHost
//                components.scheme = loginScheme
//                baseURL = components.url
//            #else
                baseURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
//            #endif
        }
        
        return baseURL!
    }
    
    @objc public func attemptLogin(_ completion: @escaping () -> Void = {}, failure: @escaping (_ error: Error) -> Void = {_ in }) {
        let performCompletionOnTheMainThread = {
            DispatchQueue.main.async {
                completion()
            }
        }
        self.loginWithSavedCredentials(success: { (success) in
            DDLogDebug("\n\nSuccessfully logged in with saved credentials for user \(success.username).\n\n")
            performCompletionOnTheMainThread()
        }, userAlreadyLoggedInHandler: { (loggedIn) in
            DDLogDebug("\n\nUser \(loggedIn.name) is already logged in.\n\n")
            performCompletionOnTheMainThread()
        }, failure: { (error) in
            DDLogDebug("\n\nloginWithSavedCredentials failed with error \(error).\n\n")
            performCompletionOnTheMainThread()
            DispatchQueue.main.async {
                failure(error)
            }
        })
    }
    
    /**
     *  Login with the given username and password
     *
     *  @param username The username to authenticate
     *  @param password The password for the user
     *  @param retypePassword The password used for confirming password changes. Optional.
     *  @param oathToken Two factor password required if user's account has 2FA enabled. Optional.
     *  @param success  The handler for success - at this point the user is logged in
     *  @param failure     The handler for any errors
     */
    @objc public func login(username: String, password:String, retypePassword:String?, oathToken:String?, captchaID: String?, captchaWord: String?, success loginSuccess:@escaping WMFAccountLoginResultBlock, failure:@escaping WMFErrorHandler){
        let siteURL = loginSiteURL
        self.tokenFetcher.fetchToken(ofType: .login, siteURL: siteURL, success: { tokenBlock in
            self.accountLogin.login(username: username, password: password, retypePassword: retypePassword, loginToken: tokenBlock.token, oathToken: oathToken, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL, success: {result in
                let normalizedUserName = result.username
                self.loggedInUsername = normalizedUserName
                KeychainCredentialsManager.shared.username = normalizedUserName
                KeychainCredentialsManager.shared.password = password
                KeychainCredentialsManager.shared.host = siteURL.host
                self.cloneSessionCookies()
                SessionSingleton.sharedInstance()?.dataStore.clearMemoryCache()
                loginSuccess(result)
            }, failure: failure)
        }, failure:failure)
    }
    
    /**
     *  Logs in a user using saved credentials in the keychain
     *
     *  @param success  The handler for success - at this point the user is logged in
     *  @param userWasAlreadyLoggedIn     The handler called if a user was found to already be logged in
     *  @param failure     The handler for any errors
     */
    @objc public func loginWithSavedCredentials(success:@escaping WMFAccountLoginResultBlock, userAlreadyLoggedInHandler:@escaping WMFCurrentlyLoggedInUserBlock, failure:@escaping WMFErrorHandler){
        
        guard hasKeychainCredentials,
            let userName = KeychainCredentialsManager.shared.username,
            let password = KeychainCredentialsManager.shared.password
        else {
            failure(WMFCurrentlyLoggedInUserFetcherError.blankUsernameOrPassword)
            return
        }
        
        let siteURL = loginSiteURL
        currentlyLoggedInUserFetcher.fetch(siteURL: siteURL, success: { result in
            self.loggedInUsername = result.name
            userAlreadyLoggedInHandler(result)
        }, failure:{ error in
            guard !(error is URLError) else {
                self.loggedInUsername = userName
                success(WMFAccountLoginResult(status: WMFAccountLoginResult.Status.offline, username: userName, message: nil))
                return
            }
            self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, captchaID: nil, captchaWord: nil, success: success, failure: { error in
                guard !(error is URLError) else {
                    self.loggedInUsername = userName
                    success(WMFAccountLoginResult(status: WMFAccountLoginResult.Status.offline, username: userName, message: nil))
                    return
                }
                self.loggedInUsername = nil
                self.logout()
                failure(error)
            })
        })
    }
    
    fileprivate var logoutManager:AFHTTPSessionManager?
    
    fileprivate func resetLocalUserLoginSettings() {
        KeychainCredentialsManager.shared.username = nil
        KeychainCredentialsManager.shared.password = nil
        self.loggedInUsername = nil
        // Cookie reminders:
        //  - "HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)" does NOT seem to work.
        HTTPCookieStorage.shared.cookies?.forEach { cookie in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        SessionSingleton.sharedInstance()?.dataStore.clearMemoryCache()
        
        SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
        
        // Reset so can show for next logged in user.
        UserDefaults.wmf_userDefaults().wmf_setDidShowEnableReadingListSyncPanel(false)
        UserDefaults.wmf_userDefaults().wmf_setDidShowSyncEnabledPanel(false)
    }
    
    /**
     *  Logs out any authenticated user and clears out any associated cookies
     */
    @objc public func logout(completion: @escaping () -> Void = {}){
        logoutManager = AFHTTPSessionManager(baseURL: loginSiteURL)
        _ = logoutManager?.wmf_apiPOSTWithParameters(["action": "logout", "format": "json"], success: { (_, response) in
            DDLogDebug("Successfully logged out, deleted login tokens and other browser cookies")
            // It's best to call "action=logout" API *before* clearing local login settings...
            self.resetLocalUserLoginSettings()
            completion()
        }, failure: { (_, error) in
            // ...but if "action=logout" fails we *still* want to clear local login settings, which still effectively logs the user out.
            DDLogDebug("Failed to log out, delete login tokens and other browser cookies: \(error)")
            self.resetLocalUserLoginSettings()
            completion()
        })
    }
    
    fileprivate func cloneSessionCookies() {
        // Make the session cookies expire at same time user cookies. Just remember they still can't be
        // necessarily assumed to be valid as the server may expire them, but at least make them last as
        // long as we can to lessen number of server requests. Uses user tokens as templates for copying
        // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.
        guard let domain = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode else {
            return
        }
        let cookie1Name = "\(domain)wikiSession"
        let cookie2Name = "\(domain)wikiUserID"
        HTTPCookieStorage.shared.wmf_recreateCookie(cookie1Name, usingCookieAsTemplate: cookie2Name)
        HTTPCookieStorage.shared.wmf_recreateCookie("centralauth_Session", usingCookieAsTemplate: "centralauth_User")
    }
}

extension WMFAuthenticationManager: AuthenticationDelegate {
    public func isUserLoggedInLocally() -> Bool {
        return isLoggedIn
    }
    
    public func isUserLoggedInRemotely() -> Bool {
        let taskGroup = WMFTaskGroup()
        let sessionManager = AFHTTPSessionManager(baseURL: loginSiteURL)
        var errorCode: String? = nil
        taskGroup.enter()
        _ = sessionManager.wmf_apiPOSTWithParameters(["action": "query", "format": "json", "assert": "user", "assertuser": nil], success: { (_, response) in
            if let response = response as? [String: AnyObject], let error = response["error"] as? [String: Any], let code = error["code"] as? String {
                errorCode = code
            }
            taskGroup.leave()
        }, failure: { (_, error) in
            taskGroup.leave()
        })
        taskGroup.wait()
        return errorCode == nil
    }

}
