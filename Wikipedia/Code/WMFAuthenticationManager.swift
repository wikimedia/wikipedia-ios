
import CocoaLumberjackSwift

@objc protocol WMFAuthenticationManagerDelegate: NSObjectProtocol {
    var loginSiteURL: URL? { get }
    func authenticationManagerDidLogin()
    func authenticationManagerDidReset()
}

/**
 *  This class provides a simple interface for performing authentication tasks.
 */
@objc public class WMFAuthenticationManager: Fetcher {
    @objc weak var delegate: WMFAuthenticationManagerDelegate?
    
    fileprivate let loginInfoFetcher: WMFAuthLoginInfoFetcher
    fileprivate let accountLogin: WMFAccountLogin
    fileprivate let currentlyLoggedInUserFetcher: WMFCurrentlyLoggedInUserFetcher

    public required init(session: Session, configuration: Configuration) {
        loginInfoFetcher = WMFAuthLoginInfoFetcher(session: session, configuration: configuration)
        accountLogin = WMFAccountLogin(session: session, configuration: configuration)
        currentlyLoggedInUserFetcher = WMFCurrentlyLoggedInUserFetcher(session: session, configuration: configuration)
        super.init(session: session, configuration: configuration)
    }
    
    public enum AuthenticationResult {
        case success(_: WMFAccountLoginResult)
        case alreadyLoggedIn(_: WMFCurrentlyLoggedInUser)
        case failure(_: Error)
    }
    
    public typealias AuthenticationResultHandler = (AuthenticationResult) -> Void
    
    public enum AuthenticationError: LocalizedError {
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
    
    /**
     *  The current logged in user. If nil, no user is logged in
     */
    @objc dynamic public private(set) var loggedInUsername: String? = nil {
        didSet {
            loggedInUserCache = [:]
            isAnonCache = [:]
        }
    }
    
    private var isAnonCache: [String: Bool] = [:]
    private var loggedInUserCache: [String: WMFCurrentlyLoggedInUser] = [:]
    
    /// Returns the currently logged in user for a given site. Useful to determine the user's groups for a given wiki
    public func getLoggedInUser(for siteURL: URL, completion: @escaping (Result<WMFCurrentlyLoggedInUser?, Error>) -> Void ) {
        assert(Thread.isMainThread)
        guard let host = siteURL.host else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        if isAnonCache[host] ?? false {
            completion(.success(nil))
            return
        }
        if let user = loggedInUserCache[host] {
            completion(.success(user))
            return
        }
        currentlyLoggedInUserFetcher.fetch(siteURL: siteURL, success: { (user) in
            DispatchQueue.main.async {
                self.loggedInUserCache[host] = user
                completion(.success(user))
            }
        }) { (error) in
            DispatchQueue.main.async {
                if error as? WMFCurrentlyLoggedInUserFetcherError == WMFCurrentlyLoggedInUserFetcherError.userIsAnonymous {
                    self.isAnonCache[host] = true
                    completion(.success(nil))
                } else {
                    completion(.failure(error))
                }
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
            !userName.isEmpty,
            let password = KeychainCredentialsManager.shared.password,
            !password.isEmpty
            else {
                return false
        }
        return true
    }
    

    var loginSiteURL: URL? {
        return delegate?.loginSiteURL ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
    }
    
    public func attemptLogin(reattemptOn401Response: Bool = false, completion: @escaping AuthenticationResultHandler) {
        self.loginWithSavedCredentials(reattemptOn401Response: reattemptOn401Response) { (loginResult) in
            switch loginResult {
            case .success(let result):
                DDLogDebug("Successfully logged in with saved credentials for user \(result.username).")
                self.session.cloneCentralAuthCookies()
            case .alreadyLoggedIn(let result):
                DDLogDebug("User \(result.name) is already logged in.")
                self.session.cloneCentralAuthCookies()
            case .failure(let error):
                DDLogDebug("loginWithSavedCredentials failed with error \(error).")
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
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, captchaID: String?, captchaWord: String?, reattemptOn401Response: Bool = false, completion: @escaping AuthenticationResultHandler) {
        guard let siteURL = loginSiteURL else {
            DispatchQueue.main.async {
                completion(.failure(AuthenticationError.missingLoginURL))
            }
            return
        }
        accountLogin.login(username: username, password: password, retypePassword: retypePassword, oathToken: oathToken, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL, reattemptOn401Response: reattemptOn401Response, success: {result in
            DispatchQueue.main.async {
                let normalizedUserName = result.username
                self.loggedInUsername = normalizedUserName
                KeychainCredentialsManager.shared.username = normalizedUserName
                KeychainCredentialsManager.shared.password = password
                self.session.cloneCentralAuthCookies()
                self.delegate?.authenticationManagerDidLogin()
                completion(.success(result))
            }
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
    public func loginWithSavedCredentials(reattemptOn401Response: Bool = false, completion: @escaping AuthenticationResultHandler) {
        
        guard hasKeychainCredentials,
            let userName = KeychainCredentialsManager.shared.username,
            let password = KeychainCredentialsManager.shared.password
            else {
                let error = WMFCurrentlyLoggedInUserFetcherError.blankUsernameOrPassword
                completion(.failure(error))
                return
        }
        
        guard let siteURL = loginSiteURL else {
            completion(.failure(AuthenticationError.missingLoginURL))
            return
        }
        
        currentlyLoggedInUserFetcher.fetch(siteURL: siteURL, success: { result in
            DispatchQueue.main.async {
                if let host = siteURL.host {
                    self.loggedInUserCache[host] = result
                }
                self.loggedInUsername = result.name
                completion(.alreadyLoggedIn(result))
            }
        }, failure:{ error in
            DispatchQueue.main.async {
                guard !(error is URLError) else {
                    self.loggedInUsername = userName
                    let loginResult = WMFAccountLoginResult(status: WMFAccountLoginResult.Status.offline, username: userName, message: nil)
                    completion(.success(loginResult))
                    return
                }
                self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, captchaID: nil, captchaWord: nil, reattemptOn401Response: reattemptOn401Response, completion: { (loginResult) in
                    DispatchQueue.main.async {
                        switch loginResult {
                        case .success(let result):
                            completion(.success(result))
                        case .failure(let error):
                            guard !(error is URLError) else {
                                self.loggedInUsername = userName
                                let loginResult = WMFAccountLoginResult(status: WMFAccountLoginResult.Status.offline, username: userName, message: nil)
                                completion(.success(loginResult))
                                return
                            }
                            self.loggedInUsername = nil
                            self.logout(initiatedBy: .app)
                            completion(.failure(error))
                        default:
                            break
                        }
                    }
                })
            }
        })
    }
    
    fileprivate func resetLocalUserLoginSettings() {
        KeychainCredentialsManager.shared.username = nil
        KeychainCredentialsManager.shared.password = nil
        self.loggedInUsername = nil

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
    public func logout(initiatedBy logoutInitiator: LogoutInitiator, completion: @escaping () -> Void = {}){
        if logoutInitiator == .app || logoutInitiator == .server {
            isUserUnawareOfLogout = true
        }
        let postDidLogOutNotification = {
            NotificationCenter.default.post(name: WMFAuthenticationManager.didLogOutNotification, object: nil)
        }
        performTokenizedMediaWikiAPIPOST(to: loginSiteURL, with: ["action": "logout", "format": "json"], reattemptLoginOn401Response: false) { (result, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    // ...but if "action=logout" fails we *still* want to clear local login settings, which still effectively logs the user out.
                    DDLogDebug("Failed to log out, delete login tokens and other browser cookies: \(error)")
                    self.resetLocalUserLoginSettings()
                    completion()
                    postDidLogOutNotification()
                    return
                }
                DDLogDebug("Successfully logged out, deleted login tokens and other browser cookies")
                // It's best to call "action=logout" API *before* clearing local login settings...
                self.resetLocalUserLoginSettings()
                completion()
                postDidLogOutNotification()
            }
        }
    }
}

// MARK: @objc login

extension WMFAuthenticationManager {
    @objc public func attemptLogin(completion: @escaping () -> Void = {}) {
        let completion: AuthenticationResultHandler = { result in
            completion()
        }
        attemptLogin(completion: completion)
    }
    
    @objc(attemptLoginWithLogoutOnFailureInitiatedBy:completion:)
    public func attemptLoginWithLogoutOnFailure(initiatedBy: LogoutInitiator, completion: @escaping () -> Void = {}) {
        let completion: AuthenticationResultHandler = { loginResult in
            switch loginResult {
            case .failure(let error):
                DDLogDebug("\n\nloginWithSavedCredentials failed with error \(error).\n\n")
                self.logout(initiatedBy: initiatedBy)
            default:
                break
            }
        }
        attemptLogin(completion: completion)
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
