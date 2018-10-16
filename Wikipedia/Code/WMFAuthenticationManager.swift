
/**
 *  This class provides a simple interface for performing authentication tasks.
 */
public class WMFAuthenticationManager: NSObject {
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
                 return CommonStrings.genericErrorRecoverySuggestion
            }
        }
    }
    
    private let session: Session = {
        return Session.shared
    }()
    
    /**
     *  The current logged in user. If nil, no user is logged in
     */
    @objc dynamic private(set) var loggedInUsername: String? = nil {
        didSet {
            guard let dataStore = SessionSingleton.sharedInstance()?.dataStore else {
                return
            }
            dataStore.readingListsController.authenticationDelegate = self
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
    
    var loginSiteURL: URL? {
        var baseURL: URL?
        if let host = KeychainCredentialsManager.shared.host {
            var components = URLComponents()
            components.host = host
            components.scheme = "https"
            baseURL = components.url
        }
        
        if baseURL == nil {
            baseURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
        }
        
        if baseURL == nil {
            baseURL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
        }
        
        return baseURL
    }
    
    public func attemptLogin(completion: @escaping AuthenticationResultHandler) {
        self.loginWithSavedCredentials { (loginResult) in
            switch loginResult {
            case .success(let result):
                DDLogDebug("\n\nSuccessfully logged in with saved credentials for user \(result.username).\n\n")
                self.session.cloneCentralAuthCookies()
            case .alreadyLoggedIn(let result):
                DDLogDebug("\n\nUser \(result.name) is already logged in.\n\n")
                self.session.cloneCentralAuthCookies()
            case .failure(let error):
                DDLogDebug("\n\nloginWithSavedCredentials failed with error \(error).\n\n")
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
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, captchaID: String?, captchaWord: String?, completion: @escaping AuthenticationResultHandler) {
        guard let siteURL = loginSiteURL else {
            completion(.failure(AuthenticationError.missingLoginURL))
            return
        }
        self.tokenFetcher.fetchToken(ofType: .login, siteURL: siteURL, success: { (token) in
            self.accountLogin.login(username: username, password: password, retypePassword: retypePassword, loginToken: token.token, oathToken: oathToken, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL, success: {result in
                let normalizedUserName = result.username
                self.loggedInUsername = normalizedUserName
                KeychainCredentialsManager.shared.username = normalizedUserName
                KeychainCredentialsManager.shared.password = password
                KeychainCredentialsManager.shared.host = siteURL.host
                self.session.cloneCentralAuthCookies()
                SessionSingleton.sharedInstance()?.dataStore.clearMemoryCache()
                completion(.success(result))
            }, failure: { (error) in
                completion(.failure(error))
            })
        }) { (error) in
            completion(.failure(error))
        }
    }
    
    /**
     *  Logs in a user using saved credentials in the keychain
     *
     *  @param success  The handler for success - at this point the user is logged in
     *  @param completion
     */
    public func loginWithSavedCredentials(completion: @escaping AuthenticationResultHandler) {
        
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
            self.loggedInUsername = result.name
            completion(.alreadyLoggedIn(result))
        }, failure:{ error in
            guard !(error is URLError) else {
                self.loggedInUsername = userName
                let loginResult = WMFAccountLoginResult(status: WMFAccountLoginResult.Status.offline, username: userName, message: nil)
                completion(.success(loginResult))
                return
            }
            self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, captchaID: nil, captchaWord: nil, completion: { (loginResult) in
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
                    self.logout()
                    completion(.failure(error))
                default:
                    break
                }
            })
        })
    }
    
    fileprivate var logoutManager:AFHTTPSessionManager?
    
    fileprivate func resetLocalUserLoginSettings() {
        KeychainCredentialsManager.shared.username = nil
        KeychainCredentialsManager.shared.password = nil
        self.loggedInUsername = nil

        session.removeAllCookies()
        
        SessionSingleton.sharedInstance()?.dataStore.clearMemoryCache()
        
        SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
        
        // Reset so can show for next logged in user.
        UserDefaults.wmf.wmf_setDidShowEnableReadingListSyncPanel(false)
        UserDefaults.wmf.wmf_setDidShowSyncEnabledPanel(false)
    }
    
    /**
     *  Logs out any authenticated user and clears out any associated cookies
     */
    @objc public func logout(completion: @escaping () -> Void = {}){
        logoutManager = AFHTTPSessionManager(baseURL: loginSiteURL)
        
        _ = logoutManager?.wmf_apiPOST(with: ["action": "logout", "format": "json"], success: { (_, response) in
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
        _ = sessionManager.wmf_apiPOST(with: ["action": "query", "format": "json", "assert": "user", "assertuser": nil], success: { (_, response) in
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

// MARK: @objc Wikipedia login
extension WMFAuthenticationManager {
    @objc public func attemptLogin(completion: @escaping () -> Void = {}, failure: @escaping (_ error: Error) -> Void = {_ in }) {
        let completion: AuthenticationResultHandler = { result in
            completion()
        }
        attemptLogin(completion: completion)
    }
    
    @objc func loginWithSavedCredentials(success: @escaping WMFAccountLoginResultBlock, userAlreadyLoggedInHandler: @escaping WMFCurrentlyLoggedInUserBlock, failure: @escaping WMFErrorHandler) {
        let completion: AuthenticationResultHandler = { loginResult in
            switch loginResult {
            case .success(let result):
                success(result)
            case .alreadyLoggedIn(let result):
                userAlreadyLoggedInHandler(result)
            case .failure(let error):
                failure(error)
            }
        }
        loginWithSavedCredentials(completion: completion)
    }
}
