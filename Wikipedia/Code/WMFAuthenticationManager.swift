
/**
 *  This class provides a simple interface for performing authentication tasks.
 */
class WMFAuthenticationManager: NSObject {    
    private var keychainCredentials:WMFKeychainCredentials
    
    /**
     *  The current logged in user. If nil, no user is logged in
     */
    dynamic private(set) var loggedInUsername: String? = nil
    
    /**
     *  Returns YES if a user is logged in, NO otherwise
     */
    public var isLoggedIn: Bool {
        return (loggedInUsername != nil)
    }

    private let loginInfoFetcher = WMFAuthLoginInfoFetcher()
    private let tokenFetcher = WMFAuthTokenFetcher()
    private let accountLogin = WMFAccountLogin()
    private let currentlyLoggedInUserFetcher = WMFCurrentlyLoggedInUserFetcher()
    
    /**
     *  Get the shared instance of this class
     *
     *  @return The shared Authentication Manager
     */
    public static let sharedInstance = WMFAuthenticationManager()    

    override private init() {
        keychainCredentials = WMFKeychainCredentials()
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
    public func login(username: String, password:String, retypePassword:String?, oathToken:String?, captchaID: String?, captchaWord: String?, success loginSuccess:@escaping WMFAccountLoginResultBlock, failure:@escaping WMFErrorHandler){
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL();
        self.tokenFetcher.fetchToken(ofType: .login, siteURL: siteURL!, success: { tokenBlock in
            self.accountLogin.login(username: username, password: password, retypePassword: retypePassword, loginToken: tokenBlock.token, oathToken: oathToken, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL!, success: {result in
                let normalizedUserName = result.username
                self.loggedInUsername = normalizedUserName
                self.keychainCredentials.userName = normalizedUserName
                self.keychainCredentials.password = password
                self.cloneSessionCookies()
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
    public func loginWithSavedCredentials(success:@escaping WMFAccountLoginResultBlock, userAlreadyLoggedInHandler:@escaping WMFCurrentlyLoggedInUserBlock, failure:@escaping WMFErrorHandler){
        
        guard
            let userName = keychainCredentials.userName,
            userName.characters.count > 0,
            let password = keychainCredentials.password,
            password.characters.count > 0
        else {
            failure(WMFCurrentlyLoggedInUserFetcherError.blankUsernameOrPassword)
            return
        }
        
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL();
        currentlyLoggedInUserFetcher.fetch(siteURL: siteURL!, success: { result in
            self.loggedInUsername = result.name
            userAlreadyLoggedInHandler(result)
        }, failure:{ error in
            self.loggedInUsername = nil
            
            self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, captchaID: nil, captchaWord: nil, success: success, failure: { error in
                if let error = error as? URLError {
                    if error.code != .notConnectedToInternet {
                        self.logout()
                    }
                }
                failure(error)
            })
        })
    }
    
    /**
     *  Logs out any authenticated user and clears out any associated cookies
     */
    public func logout(){
        keychainCredentials.userName = nil
        keychainCredentials.password = nil
        loggedInUsername = nil
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return
        }
        // Clear session cookies.
        cookies.forEach { cookie in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    
    func cloneSessionCookies() {
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
