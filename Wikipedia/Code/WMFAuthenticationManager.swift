import CocoaLumberjackSwift

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
    
    @objc weak var delegate: WMFAuthenticationManagerDelegate?
    
    fileprivate let accountLoginLogoutFetcher: WMFAccountLoginLogoutFetcher
    fileprivate let currentUserFetcher: WMFCurrentUserFetcher

    @objc public required init(session: Session, configuration: Configuration) {
        accountLoginLogoutFetcher = WMFAccountLoginLogoutFetcher(session: session, configuration: configuration)
        currentUserFetcher = WMFCurrentUserFetcher(session: session, configuration: configuration)
    }
    
    public enum LoginError: LocalizedError {
        case missingLoginURL
        
        public var errorDescription: String? {
            switch self {
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
    
    private var currentUserCache: [String: WMFCurrentUser] = [:]
    
    private func getCurrentUser(for siteURL: URL, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void ) {
        assert(Thread.isMainThread)
        guard let host = siteURL.host else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        if let user = currentUserCache[host] {
            completion(.success(user))
            return
        }
        currentUserFetcher.fetch(siteURL: siteURL, success: { (user) in
            DispatchQueue.main.async {
                self.currentUserCache[host] = user
                completion(.success(user))
            }
        }) { (error) in
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
    
    @objc dynamic public private(set) var permanentUsername: String? = nil {
        didSet {
            currentUserCache = [:]
        }
    }
    
    @objc public var isPermanent: Bool {
        return (permanentUsername != nil)
    }
    
    public func getCurrentPermanentUserCache(for siteURL: URL) -> WMFCurrentUser? {
        guard let host = siteURL.host else {
            return nil
        }
        guard let user = currentUserCache[host],
              !user.isIP && !user.isTemp else {
            return nil
        }
        
        return user
    }
    
    @objc func getCurrentPermanentUser(for siteURL: URL, completion: @escaping (WMFCurrentUser?) -> Void) {
        getCurrentPermanentUser(for: siteURL) { result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    completion(user)
                }
            default:
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    public func getCurrentPermanentUser(for siteURL: URL, completion: @escaping (Result<WMFCurrentUser?, Error>) -> Void ) {
        assert(Thread.isMainThread)
        getCurrentUser(for: siteURL) { result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if !user.isIP && !user.isTemp {
                        completion(.success(user))
                    } else {
                        completion(.success(nil))
                    }
                }
            case.failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    @objc public var hasKeychainCredentials: Bool {
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
    
    /**
     *  Login with the given username and password
     *
     *  @param username The username to authenticate
     *  @param password The password for the user
     *  @param retypePassword The password used for confirming password changes. Optional.
     *  @param oathToken Two factor password required if user's account has 2FA enabled. Optional.
     *  @param loginSuccess  The handler for success - at this point the user is logged in
     *  @param failure     The handler for any errors
     */
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, captchaID: String?, captchaWord: String?, reattemptOn401Response: Bool = false, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void) {
        guard let siteURL = loginSiteURL else {
            DispatchQueue.main.async {
                completion(.failure(LoginError.missingLoginURL))
            }
            return
        }
        accountLoginLogoutFetcher.login(username: username, password: password, retypePassword: retypePassword, oathToken: oathToken, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL, reattemptOn401Response: reattemptOn401Response, success: {username in
            
            // Upon successful login, try fetching userinfo to populate user cache
            self.currentUserFetcher.fetch(siteURL: siteURL, success: { result in
                DispatchQueue.main.async {
                    if let host = siteURL.host {
                        self.currentUserCache[host] = result
                    }
                    if !result.isIP && result.isTemp {
                        self.permanentUsername = result.name
                    }
                    
                    KeychainCredentialsManager.shared.username = username
                    KeychainCredentialsManager.shared.password = password
                    self.session.cloneCentralAuthCookies()
                    self.delegate?.authenticationManagerDidLogin()
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                    
                    completion(.success(result))
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
    
    /**
     *  Logs in a user using saved credentials in the keychain
     *
     *  @param success  The handler for success - at this point the user is logged in
     *  @param completion
     */
    public func loginWithSavedCredentials(reattemptOn401Response: Bool = false, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void) {
        
        guard hasKeychainCredentials,
            let userName = KeychainCredentialsManager.shared.username,
            let password = KeychainCredentialsManager.shared.password
            else {
                let error = WMFCurrentlyLoggedInUserFetcherError.blankUsernameOrPassword
                completion(.failure(error))
                return
        }
        
        guard let siteURL = loginSiteURL else {
            completion(.failure(LoginError.missingLoginURL))
            return
        }
        
        currentUserFetcher.fetch(siteURL: siteURL, success: { result in
            DispatchQueue.main.async {
                if let host = siteURL.host {
                    self.currentUserCache[host] = result
                }
                if !result.isIP && result.isTemp {
                    self.permanentUsername = result.name
                }
                NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                completion(.success(result))
            }
        }, failure: { error in
            DispatchQueue.main.async {
                guard !(error is URLError) else {
                    // Connection error, assume login would have been successful
                    
                    let user = WMFCurrentUser(userID: 0, name: userName, groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
                    
                    if let host = siteURL.host {
                        self.currentUserCache[host] = user
                    }
                    
                    self.permanentUsername = user.name
                    
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                    completion(.success(user))
                    return
                }
                
                self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, captchaID: nil, captchaWord: nil, reattemptOn401Response: reattemptOn401Response, completion: { (loginResult) in
                    DispatchQueue.main.async {
                        switch loginResult {
                        case .success(let result):
                            
                            completion(.success(result))
                            
                        case .failure(let error):
                            guard !(error is URLError) else {
                                // Connection error, assume login would have been successful
                                
                                let user = WMFCurrentUser(userID: 0, name: userName, groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
                                
                                if let host = siteURL.host {
                                    self.currentUserCache[host] = user
                                }
                                
                                self.permanentUsername = user.name
                                
                                NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                                completion(.success(user))
                                return
                            }
                            
                            self.permanentUsername = nil
                            self.logout(initiatedBy: .app)
                            completion(.failure(error))
                        }
                    }
                })
            }
        })
    }
    
    fileprivate func reset() {
        KeychainCredentialsManager.shared.username = nil
        KeychainCredentialsManager.shared.password = nil
        self.permanentUsername = nil

        session.removeAllCookies()
        
        delegate?.authenticationManagerDidReset()
        
        // Reset so can show for next logged in user.
        UserDefaults.standard.wmf_setDidShowEnableReadingListSyncPanel(false)
        UserDefaults.standard.wmf_setDidShowSyncEnabledPanel(false)
    }
    
    /**
     *  Logs out any authenticated user and clears out any associated cookies
     */
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
}

// MARK: @objc login

extension WMFAuthenticationManager {
    @objc public func attemptLogin(completion: @escaping () -> Void = {}) {
        attemptLogin { result in
            completion()
        }
    }
    
    @objc(attemptLoginWithLogoutOnFailureInitiatedBy:completion:)
    public func attemptLoginWithLogoutOnFailure(initiatedBy: LogoutInitiator, completion: @escaping () -> Void = {}) {
        attemptLogin { result in
            switch result {
            case .failure(let error):
                DDLogError("\n\nloginWithSavedCredentials failed with error \(error).\n\n")
                self.logout(initiatedBy: initiatedBy)
            default:
                break
            }
        }
    }
}

// MARK: @objc logout

extension WMFAuthenticationManager {
    @objc public enum LogoutInitiator: Int {
        case user
        case app
        case server
    }

    @objc public static let didLogOutNotification = Notification.Name("WMFAuthenticationManagerDidLogOut")
    @objc public static let didLogInNotification = Notification.Name("WMFAuthenticationManagerDidLogIn")

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
}
