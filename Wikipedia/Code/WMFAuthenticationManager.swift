
/**
 *  This class provides a simple interface for performing authentication tasks.
 */
class WMFAuthenticationManager: NSObject {    
    private let keychainCredentials:KeychainCredentials
    
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
    fileprivate static let _sharedInstance = WMFAuthenticationManager()
    open class func sharedInstance() -> WMFAuthenticationManager {
        return _sharedInstance
    }

    override private init() {
        keychainCredentials = KeychainCredentials()
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
    public func login(username: String, password:String, retypePassword:String?, oathToken:String?, success:@escaping WMFAccountLoginResultBlock, failure:@escaping WMFErrorHandler){
        let outerSuccess = success
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL();
        loginInfoFetcher.fetchLoginInfoForSiteURL(siteURL!, success: {
            (info: WMFAuthLoginInfo) in
            self.tokenFetcher.fetchToken(ofType: .login, siteURL: siteURL!, success: {
                (token: WMFAuthToken) in
                self.accountLogin.login(username: username, password: password, retypePassword: retypePassword, loginToken: token.token, oathToken: oathToken, siteURL: siteURL!, success: {result in
                    let normalizedUserName = result.username
                    self.loggedInUsername = normalizedUserName
                    self.keychainCredentials.userName = normalizedUserName
                    self.keychainCredentials.password = password
                    self.cloneSessionCookies()
                    outerSuccess(result)
                }, failure: failure)
            }, failure:failure)
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
            failure(WMFCurrentlyLoggedInUserFetcherError.init(type:.blankUsernameOrPassword, localizedDescription: "Zero length username or password"))
            return
        }
        
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL();
        currentlyLoggedInUserFetcher.fetch(siteURL: siteURL!, success: { result in
            self.loggedInUsername = result.name
            userAlreadyLoggedInHandler(result)
        }, failure:{ error in
            self.loggedInUsername = nil
            
            self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, success: success, failure: { error in
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
        // Clear session cookies.
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
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
