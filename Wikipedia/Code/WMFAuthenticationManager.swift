import CocoaLumberjackSwift

// MARK: WMFAuthenticationManagerDelegate
@objc protocol WMFAuthenticationManagerDelegate: NSObjectProtocol {
    var loginSiteURL: URL? { get }
    func authenticationManagerWillLogOut(completionHandler: @escaping () -> Void) // allows interested objects to perform authenticated clean up actions before log out
    func authenticationManagerDidLogin()
    func authenticationManagerDidReset()
}

/**
 *  This class provides a simple interface for performing authentication tasks.
 */
@objc public class WMFAuthenticationManager: NSObject {
    
    // MARK: Typealiases
    
    private typealias SiteURLHost = String
    
    // MARK: Nested Types
    
    public enum LoginError: LocalizedError {
        case missingLoginURL
        case blankUsernameOrPassword
        
        public var errorDescription: String? {
            switch self {
            case .blankUsernameOrPassword:
                return "Blank username or password"
            default:
                return CommonStrings.genericErrorDescription
            }
        }
        
        public var recoverySuggestion: String? {
            switch self {
            default:
                 return WMFLocalizedString("error-generic-recovery-suggestion", value: "Please try again later", comment: "Generic recovery suggestion for when the error isn't recoverable by the user.")
            }
        }
    }
    
    @objc public enum LogoutInitiator: Int {
        case user
        case app
        case server
    }
    
    // MARK: Properties
    
    @objc public static let didLogOutNotification = Notification.Name("WMFAuthenticationManagerDidLogOut")
    @objc public static let didLogInNotification = Notification.Name("WMFAuthenticationManagerDidLogIn")
    @objc public static let didHandlePrimaryLanguageChange = Notification.Name("WMFAuthenticationManagerDidHandlePrimaryLanguageChange")
    
    @objc weak var delegate: WMFAuthenticationManagerDelegate?
    
    fileprivate let accountLoginLogoutFetcher: WMFAccountLoginLogoutFetcher
    fileprivate let currentUserFetcher: WMFCurrentUserFetcher
    
    private var currentUserCache: [SiteURLHost: WMFCurrentUser] = [:]

    @objc public required init(session: Session, configuration: Configuration) {
        accountLoginLogoutFetcher = WMFAccountLoginLogoutFetcher(session: session, configuration: configuration)
        currentUserFetcher = WMFCurrentUserFetcher(session: session, configuration: configuration)
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(appLanguageDidChange(_:)), name: NSNotification.Name.WMFAppLanguageDidChange, object: nil)
    }
    
    // MARK: Public
    
    /// Pulls a current user from cache, according to the siteURL we want to check against.
    /// Current user cache is populated via a call to https://www.mediawiki.org/wiki/API:Userinfo.
    /// - Parameter siteURL: The siteURL (i.e. en.wikipedia.org) of the current user
    /// - Returns: User object that contains auth states and additional info
    @objc public func user(siteURL: URL) -> WMFCurrentUser? {
        guard let host = siteURL.host else {
            return nil
        }
        guard let user = currentUserCache[host] else {
            return nil
        }
        
        return user
    }
    
    
    /// Pulls a permanent current user from cache, according to the siteURL we want to check against. If current user authState != .permanent, method returns nil.
    /// Current user cache is populated via a call to https://www.mediawiki.org/wiki/API:Userinfo.
    /// - Parameter siteURL: The siteURL of the current user
    /// - Returns: User object if authState == .permanent, else nil
    public func permanentUser(siteURL: URL) -> WMFCurrentUser? {
        guard let host = siteURL.host else {
            return nil
        }
        guard let user = currentUserCache[host] else {
            return nil
        }
        
        guard user.authState == .permanent else {
            return nil
        }
        
        return user
    }
    
    /// Loops through all current user objects across the various siteURLs we have cached, and returns the username of the first username with authState == .permanent
    @objc public var authStatePermanentUsername: String? {
        
        for (_, user) in currentUserCache {
            guard user.authState == .permanent else {
                continue
            }
            
            return user.name
        }
        
        return nil
    }
    
    /// Loops through all current user objects across the various siteURLs we have cached, and returns true if one contains authState == .permanent
    @objc public var authStateIsPermanent: Bool {
        for (_, user) in currentUserCache {
            guard user.authState == .permanent else {
                continue
            }
            
            return true
        }
        
        return false
    }
    
    @objc public var authStateIsTemporary: Bool {
        // To match Android, is_temp = existence of central auth username cookie, but missing an entry in the local credential store
        return session.hasCentralAuthUserCookie() && KeychainCredentialsManager.shared.username == nil && KeychainCredentialsManager.shared.password == nil
    }
    
    // MARK: Login
    
    /// Attempt login with saved credentials in the keychain.
    /// - Parameters:
    ///   - reattemptOn401Response: Attempts login again if response http is 401.
    ///   - completion: Completion handler with current user object upon success
    public func attemptLogin(reattemptOn401Response: Bool = false, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void) {
        self.loginWithSavedCredentials(reattemptOn401Response: reattemptOn401Response) { (loginResult) in
            switch loginResult {
            case .success(let user):
                DDLogDebug("Successfully logged in with saved credentials for user \(user.name).")
                self.session.cloneCentralAuthCookies()
            case .failure(let error):
                DDLogError("loginWithSavedCredentials failed with error \(error).")
            }
            DispatchQueue.main.async {
                completion(loginResult)
            }
        }
    }
    
    /// Login with the given username and password
    /// - Parameters:
    ///   - username: The username to authenticate
    ///   - password: The password for the user
    ///   - retypePassword: The password used for confirming password changes. Optional.
    ///   - oathToken: Two factor password required if user's account has 2FA enabled. Optional.
    ///   - captchaID: CaptchaID if login requiers captcha information
    ///   - captchaWord: CaptchaWord if login requiers captcha information
    ///   - reattemptOn401Response: Attempts login again if response http is 401.
    ///   - completion: Completion handler with current user object upon success
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, captchaID: String?, captchaWord: String?, reattemptOn401Response: Bool = false, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void) {
        guard let siteURL = loginSiteURL else {
            DispatchQueue.main.async {
                completion(.failure(LoginError.missingLoginURL))
            }
            return
        }
        accountLoginLogoutFetcher.login(username: username, password: password, retypePassword: retypePassword, oathToken: oathToken, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL, reattemptOn401Response: reattemptOn401Response, success: {username in
            
            // Upon successful login, try fetching userinfo to populate user cache
            self.currentUserFetcher.fetch(siteURL: siteURL, success: { user in
                DispatchQueue.main.async {
                    if let host = siteURL.host {
                        self.currentUserCache[host] = user
                    }
                    
                    KeychainCredentialsManager.shared.username = username
                    KeychainCredentialsManager.shared.password = password
                    self.session.cloneCentralAuthCookies()
                    self.delegate?.authenticationManagerDidLogin()
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                    
                    completion(.success(user))
                }
            }, failure: { error in
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            })
            
        }, failure: { (error) in
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        })
    }
    
    /// Logs in a user using saved credentials in the keychain
    /// - Parameters:
    ///   - reattemptOn401Response: Attempts login again if response http is 401.
    ///   - completion: Completion handler with current user object upon success
    public func loginWithSavedCredentials(reattemptOn401Response: Bool = false, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void) {
        
        guard hasKeychainCredentials,
              let userName = KeychainCredentialsManager.shared.username,
              let password = KeychainCredentialsManager.shared.password
        else {
            let error = LoginError.blankUsernameOrPassword
            completion(.failure(error))
            return
        }
        
        guard let siteURL = loginSiteURL else {
            completion(.failure(LoginError.missingLoginURL))
            return
        }
        
        let performLogin: () -> Void = {
            self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, captchaID: nil, captchaWord: nil, reattemptOn401Response: reattemptOn401Response, completion: { (loginResult) in
                DispatchQueue.main.async {
                    switch loginResult {
                    case .success(let user):
                        
                        completion(.success(user))
                        
                    case .failure(let error):
                        guard !(error is URLError) else {
                            // Connection error, assume login would have been successful
                            
                            let user = WMFCurrentUser(userID: 0, name: userName, groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
                            
                            if let host = siteURL.host {
                                self.currentUserCache[host] = user
                            }
                            
                            NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                            completion(.success(user))
                            return
                        }
                        
                        self.logout(initiatedBy: .app)
                        completion(.failure(error))
                    }
                }
            })
        }
        
        // First see if we really need to make the login call by fetching current user info. If it indicates a permanent account is already logged in, return early.
        currentUserFetcher.fetch(siteURL: siteURL, success: { user in
            DispatchQueue.main.async {
                if let host = siteURL.host {
                    self.currentUserCache[host] = user
                }
                
                // If fetch indicates nonPermanent, we need to actually log in
                if user.authState == .ip || user.authState == .temporary {
                    performLogin()
                } else {
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                    completion(.success(user))
                }
            }
        }, failure: { error in
            DispatchQueue.main.async {
                guard !(error is URLError) else {
                    // If connection error, assume login would have been successful
                    
                    let user = WMFCurrentUser(userID: 0, name: userName, groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
                    
                    if let host = siteURL.host {
                        self.currentUserCache[host] = user
                    }
                    
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                    completion(.success(user))
                    return
                }
                
                performLogin()
            }
        })
    }
    
    
    /// Objective-C wrapper method for attempting login with saved credentials
    /// - Parameter completion: Completion handler once login attempt is done.
    @objc public func attemptLogin(completion: @escaping () -> Void = {}) {
        attemptLogin { result in
            completion()
        }
    }
    
    
    /// Attempts to log in user with saved credentials. Makes logout API call and resets auth manager state upon failure.
    /// - Parameters:
    ///   - completion: Completion handler once login attempt (and subsequent logout call if needed) is done.
    ///
    @objc(attemptLoginWithLogoutOnFailureWithCompletion:)
    public func attemptLoginWithLogoutOnFailure(completion: @escaping () -> Void = {}) {
        attemptLogin { result in
            switch result {
            case .failure(let error):
                DDLogError("\n\nloginWithSavedCredentials failed with error \(error).\n\n")
                self.logout(initiatedBy: .server) {
                    completion()
                }
            default:
                completion()
                break
            }
        }
    }

    // MARK: Logout

    /// Logs out any authenticated user via API call and clears out any associated cookies and cache
    /// - Parameters:
    ///   - logoutInitiator: Initiator of the logout
    ///   - completion: Completion handler once logout is done
    @objc(logoutInitiatedBy:completion:)
    public func logout(initiatedBy logoutInitiator: LogoutInitiator, completion: @escaping () -> Void = {}) {
        delegate?.authenticationManagerWillLogOut {
            if logoutInitiator == .app || logoutInitiator == .server {
                self.isUserUnawareOfLogout = true
            }
            let postDidLogOutNotification = {
                NotificationCenter.default.post(name: WMFAuthenticationManager.didLogOutNotification, object: nil)
            }
            
            guard let loginSiteURL = self.loginSiteURL else {
                self.reset()
                completion()
                postDidLogOutNotification()
                return
            }
            
            self.accountLoginLogoutFetcher.logout(loginSiteURL: loginSiteURL, reattemptOn401Response: false) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        // ...but if "action=logout" fails we *still* want to clear local login settings, which still effectively logs the user out.
                        DDLogError("Failed to log out, delete login tokens and other browser cookies: \(error)")
                        self.reset()
                        completion()
                        postDidLogOutNotification()
                        return
                    }
                    
                    DDLogDebug("Successfully logged out, deleted login tokens and other browser cookies")
                    // It's best to call "action=logout" API *before* resetting...
                    self.reset()
                    completion()
                    postDidLogOutNotification()
                }
            }
        }
    }

    @objc public func userDidAcknowledgeUnintentionalLogout() {
        isUserUnawareOfLogout = false
    }

    @objc public var isUserUnawareOfLogout: Bool {
        get {
            return UserDefaults.standard.isUserUnawareOfLogout
        }
        set {
            UserDefaults.standard.isUserUnawareOfLogout = newValue
        }
    }
    
    // MARK: NSNotifications
    
    @objc private func appLanguageDidChange(_ notification: Notification) {
        guard let siteURL = loginSiteURL else {
            return
        }
        
        // App Language has changed. Fetch current user again to refresh currentUserCache.
        
        guard let langController = notification.object, let appLanguage = (langController as AnyObject).appLanguage else {
            assertionFailure("Could not extract app language from WMFAppLanguageDidChangeNotification")
            return
        }
        
        self.currentUserFetcher.fetch(siteURL: siteURL, success: { user in
            DispatchQueue.main.async {
                if let host = siteURL.host {
                    self.currentUserCache[host] = user
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didHandlePrimaryLanguageChange, object: nil)
                }
            }
        }, failure: { error in
            DDLogError("Failure refreshing currentUserCache after app language change: \(error)")
        })
    }
    
    // MARK: Private
    
    private var hasKeychainCredentials: Bool {
        guard
            let userName = KeychainCredentialsManager.shared.username,
            !userName.isEmpty,
            let password = KeychainCredentialsManager.shared.password,
            !password.isEmpty
            else {
                return false
        }
        return true
    }

    private var loginSiteURL: URL? {
        return delegate?.loginSiteURL ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
    }
    
    private var session: Session {
        return self.accountLoginLogoutFetcher.session
    }
    
    
    /// Resets WMFAuthenticationManager back to fresh state. Removes persisted login credentials, removes user cache, removes cookies, removes persisted user defaults settings.
    private func reset() {
        KeychainCredentialsManager.shared.username = nil
        KeychainCredentialsManager.shared.password = nil
        currentUserCache = [:]

        session.removeAllCookies()
        
        delegate?.authenticationManagerDidReset()
        
        // Reset so can show for next logged in user.
        UserDefaults.standard.wmf_setDidShowEnableReadingListSyncPanel(false)
        UserDefaults.standard.wmf_setDidShowSyncEnabledPanel(false)
    }
}
