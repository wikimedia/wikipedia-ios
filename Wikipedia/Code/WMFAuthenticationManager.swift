import CocoaLumberjackSwift
import WMFNativeLocalizations
import WMFTestKitchen

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
    @objc public static let autoLoginNeedsEmailToken = Notification.Name("WMFAuthenticationManagerAutoLoginNeedsEmailToken")
    @objc public static let autoLoginNeedsOathToken = Notification.Name("WMFAuthenticationManagerAutoLoginNeedsOathToken")
    
    @objc weak var delegate: WMFAuthenticationManagerDelegate?
    
    fileprivate let accountLoginLogoutFetcher: WMFAccountLoginLogoutFetcher
    fileprivate let currentUserFetcher: WMFCurrentUserFetcher
    
    private var currentUserCache: [SiteURLHost: WMFCurrentUser] = [:]
    /// The user fetch in flight for each host, with the `userCacheGeneration` it started in. Callers
    /// that ask while a fetch of the same generation runs wait for it.
    @MainActor private var userFetchTasks: [SiteURLHost: (generation: Int, task: Task<Void, Never>)] = [:]
    /// Changes on each reset, so a user fetch that started before a logout does not fill the cache
    /// after it. Like `currentUserCache`, it is written in `reset()`.
    private var userCacheGeneration = 0
    /// A caller that needs the user waits at most this long for the fetch. The fetch keeps going and
    /// fills the cache for later callers.
    private static let userFetchWaitTimeout: Duration = .seconds(5)
    
    @objc public var authStateTemporaryUsername: String? {
        if authStateIsTemporary {
            return session.getCentralAuthUserCookie()
        } else {
            return nil
        }
    }

    @objc public required convenience init(session: Session, configuration: Configuration) {
        self.init(session: session, configuration: configuration, currentUserFetcher: WMFCurrentUserFetcher(session: session, configuration: configuration))
    }

    /// Tests pass a stub `currentUserFetcher`.
    init(session: Session, configuration: Configuration, currentUserFetcher: WMFCurrentUserFetcher) {
        accountLoginLogoutFetcher = WMFAccountLoginLogoutFetcher(session: session, configuration: configuration)
        self.currentUserFetcher = currentUserFetcher
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(appLanguageDidChange(_:)), name: NSNotification.Name.WMFAppLanguageDidChange, object: nil)
    }
    
    private var backgroundAuthInstrument: InstrumentImpl?
    
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

    /// Stores the given user in the cache for the given site if the cache has no entry for that host. Use this when another API call already contains the user information, so the cache gets filled without an extra fetch.
    public func seedUserCacheIfNeeded(user: WMFCurrentUser, siteURL: URL) {
        guard let host = siteURL.host, currentUserCache[host] == nil else {
            return
        }
        currentUserCache[host] = user
    }

    /// Fetches and caches the current user for the given site if the cache has no entry for that host. This call does not block. Callers get the cached value on a later lookup.
    public func hydrateUserCacheIfNeeded(siteURL: URL) {
        guard let host = siteURL.host,
              currentUserCache[host] == nil else {
            return
        }
        Task { @MainActor [weak self] in
            await self?.fetchUserIntoCache(siteURL: siteURL, host: host)
        }
    }

    /// Fetches the user for the host and caches it. A caller that asks while a fetch for the host is
    /// in flight waits for that fetch instead of making another request. A reset during the fetch
    /// drops the result, so a user who logged out is not cached again. A caller after that reset
    /// does not wait for the old fetch, which would give it nothing: it starts a new one.
    @MainActor
    func fetchUserIntoCache(siteURL: URL, host: String) async {
        let generation = userCacheGeneration
        if let running = userFetchTasks[host], running.generation == generation {
            await running.task.value
            return
        }
        let fetcher = currentUserFetcher
        let task = Task { @MainActor [weak self] in
            let user = try? await fetcher.fetch(siteURL: siteURL)
            guard let self,
                  let user,
                  generation == self.userCacheGeneration,
                  self.currentUserCache[host] == nil else {
                return
            }
            self.currentUserCache[host] = user
        }
        userFetchTasks[host] = (generation, task)
        await task.value
        if userFetchTasks[host]?.task == task {
            userFetchTasks[host] = nil
        }
    }

    /// Returns the permanent user for the given site. If the cache has no entry for that host and the
    /// app has saved credentials, it fetches and caches the user first, so a caller that runs before
    /// anything else filled the cache still gets the user. It waits at most `userFetchWaitTimeout`, so
    /// a slow network does not hold the caller. Returns `nil` for a logged-out or temporary user, or
    /// when the fetch fails or does not finish in time.
    /// - Parameter didFetchAfterTimeout: Called when the wait timed out and the fetch then cached a
    ///   permanent user, so the caller can do again the work that ran without the user.
    @MainActor
    public func fetchPermanentUserIfNeeded(siteURL: URL, didFetchAfterTimeout: (@MainActor @Sendable () -> Void)? = nil) async -> WMFCurrentUser? {
        guard let host = siteURL.host else {
            return nil
        }
        guard currentUserCache[host] == nil,
              KeychainCredentialsManager.shared.username != nil else {
            return permanentUser(siteURL: siteURL)
        }

        let finishedInTime = await fetchUserIntoCache(siteURL: siteURL, host: host, timeout: Self.userFetchWaitTimeout) { [weak self] in
            guard self?.permanentUser(siteURL: siteURL) != nil else {
                return
            }
            DDLogInfo("The user fetch for \(host) finished after the timeout")
            didFetchAfterTimeout?()
        }
        if !finishedInTime {
            DDLogWarn("The user fetch for \(host) did not finish in \(Self.userFetchWaitTimeout). Continuing without the user.")
        }
        return permanentUser(siteURL: siteURL)
    }

    /// Fetches the user into the cache like `fetchUserIntoCache(siteURL:host:)`, but waits at most
    /// `timeout`. On a timeout the fetch keeps going and calls `didFinishLate` when it ends.
    /// - Returns: `true` if the fetch finished in time.
    @MainActor
    func fetchUserIntoCache(siteURL: URL, host: String, timeout: Duration, didFinishLate: @escaping @MainActor @Sendable () -> Void) async -> Bool {
        let fetch = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            await self.fetchUserIntoCache(siteURL: siteURL, host: host)
        }
        let finishedInTime = await Self.wait(for: fetch, timeout: timeout)
        if !finishedInTime {
            Task { @MainActor in
                await fetch.value
                didFinishLate()
            }
        }
        return finishedInTime
    }

    /// Returns when the task finishes or the timeout passes, whichever is first. The task is not cancelled.
    /// - Returns: `true` if the task finished first.
    @MainActor
    static func wait(for task: Task<Void, Never>, timeout: Duration) async -> Bool {
        let waiter = OnceContinuation()
        var timer: Task<Void, Never>?
        let finished = await withCheckedContinuation { continuation in
            waiter.continuation = continuation
            Task { @MainActor in
                await task.value
                waiter.resume(returning: true)
            }
            timer = Task { @MainActor in
                try? await Task.sleep(for: timeout)
                waiter.resume(returning: false)
            }
        }
        timer?.cancel()
        return finished
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
        guard let centralAuthUsername = session.getCentralAuthUserCookie(),
              WMFAuthenticationManager.isTemporaryAccountUsername(centralAuthUsername) else {
            return false
        }
        return KeychainCredentialsManager.shared.username == nil && KeychainCredentialsManager.shared.password == nil
    }

    /// Temporary account names on Wikimedia wikis always start with `~` (e.g. `~2026-12345-6`).
    /// A permanent username left in the cookie by an unfinished logout must not be treated as a temporary account.
    static func isTemporaryAccountUsername(_ username: String) -> Bool {
        return username.hasPrefix("~")
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
    ///   - hCaptchaToken: hCaptcha token if login requires an hCaptcha challenge to be solved
    ///   - reattemptOn401Response: Attempts login again if response http is 401.
    ///   - completion: Completion handler with current user object upon success
    public func login(username: String, password: String, retypePassword: String?, oathToken: String?, emailAuthCode: String?, captchaID: String?, captchaWord: String?, hCaptchaToken: String? = nil, reattemptOn401Response: Bool = false, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void) {
        guard let siteURL = loginSiteURL else {
            DispatchQueue.main.async {
                completion(.failure(LoginError.missingLoginURL))
            }
            return
        }
        accountLoginLogoutFetcher.login(username: username, password: password, retypePassword: retypePassword, oathToken: oathToken, emailAuthCode: emailAuthCode, captchaID: captchaID, captchaWord: captchaWord, hCaptchaToken: hCaptchaToken, siteURL: siteURL, reattemptOn401Response: reattemptOn401Response, success: {username in

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
    public func loginWithSavedCredentials(reattemptOn401Response: Bool = false, emailToken: String? = nil, oathToken: String? = nil, backgroundAuthInstrument: WMFTestKitchen.InstrumentImpl? = nil, completion: @escaping (Result<WMFCurrentUser, Error>) -> Void) {
        
        // Instrument a background login attempt
        self.backgroundAuthInstrument = backgroundAuthInstrument ?? TestKitchenAdapter.shared.client.getInstrument(name: "apps-authentication")
            .setDefaultActionSource("background_login")
            .startFunnel(name: "login_account")
        
        guard hasKeychainCredentials,
              let userName = KeychainCredentialsManager.shared.username,
              let password = KeychainCredentialsManager.shared.password
        else {
            let error = LoginError.blankUsernameOrPassword
            // This is legitimate for logged out users, so we won't log this error via authInstrument
            self.backgroundAuthInstrument = nil
            completion(.failure(error))
            return
        }
        
        backgroundAuthInstrument?.submitInteraction(action: "start")
        
        guard let siteURL = loginSiteURL else {
            let error = LoginError.missingLoginURL
            self.backgroundAuthInstrument?.submitInteraction(action: "error", actionContext: ["validation_error": error.logDescription])
            self.backgroundAuthInstrument = nil
            completion(.failure(error))
            return
        }
        
        let performLogin: () -> Void = {
            self.login(username: userName, password: password, retypePassword: nil, oathToken: oathToken, emailAuthCode: emailToken, captchaID: nil, captchaWord: nil, reattemptOn401Response: reattemptOn401Response, completion: { (loginResult) in
                DispatchQueue.main.async {
                    switch loginResult {
                    case .success(let user):
                        
                        self.backgroundAuthInstrument?.submitInteraction(action: "success")
                        self.backgroundAuthInstrument = nil
                        
                        completion(.success(user))
                        
                    case .failure(let error):
                        guard !(error is URLError) else {
                            // Connection error, assume login would have been successful
                            
                            let user = WMFCurrentUser(userID: 0, globalUserID: 0, name: userName, groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
                            
                            if let host = siteURL.host {
                                self.currentUserCache[host] = user
                            }
                            
                            NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                            completion(.success(user))
                            return
                        }
                        
                        if let recognizedError = error as? WMFAccountLoginError {
                            self.backgroundAuthInstrument?.submitInteraction(action: "error", actionContext: ["validation_error": recognizedError.testKitchenValidationError])
                            
                            switch recognizedError {
                            case .needsOathTokenFor2FA(let mediaWikiMessage):
                                
                                var userInfo: [AnyHashable : Any] = ["mediaWikiMessage": mediaWikiMessage?.text as Any]
                                if let backgroundAuthInstrument = self.backgroundAuthInstrument {
                                    userInfo["authInstrument"] = backgroundAuthInstrument
                                }
                                
                                NotificationCenter.default.post(name: WMFAuthenticationManager.autoLoginNeedsOathToken, object: nil, userInfo: userInfo)
                                completion(.failure(error))
                            case .needsEmailAuthToken(let mediaWikiMessage):
                                var userInfo: [AnyHashable : Any] = ["mediaWikiMessage": mediaWikiMessage?.text as Any]
                                
                                if let backgroundAuthInstrument = self.backgroundAuthInstrument {
                                    userInfo["authInstrument"] = backgroundAuthInstrument
                                }
                                
                                NotificationCenter.default.post(name: WMFAuthenticationManager.autoLoginNeedsEmailToken, object: nil, userInfo: userInfo)
                                completion(.failure(error))
                            default:
                                self.logout(initiatedBy: .app)
                                completion(.failure(error))
                            }
                        } else {
                            self.backgroundAuthInstrument?.submitInteraction(action: "error", actionContext: ["code": error.logDescription])
                            if !WMFAuthenticationManager.isTransientError(error) {
                                self.logout(initiatedBy: .app)
                            }
                            completion(.failure(error))
                        }
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
                    
                    self.backgroundAuthInstrument?.submitInteraction(action: "success")
                    self.backgroundAuthInstrument = nil
                    
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                    completion(.success(user))
                }
            }
        }, failure: { error in
            DispatchQueue.main.async {
                guard !(error is URLError) else {
                    // If connection error, assume login would have been successful
                    
                    let user = WMFCurrentUser(userID: 0, globalUserID: 0, name: userName, groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
                    
                    if let host = siteURL.host {
                        self.currentUserCache[host] = user
                    }
                    
                    NotificationCenter.default.post(name: WMFAuthenticationManager.didLogInNotification, object: nil)
                    
                    self.backgroundAuthInstrument?.submitInteraction(action: "error", actionContext: ["code": error.logDescription])
                    self.backgroundAuthInstrument = nil
                    
                    completion(.success(user))
                    return
                }
                
                self.backgroundAuthInstrument?.submitInteraction(action: "error", actionContext: ["code": error.logDescription])
                
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
                guard !WMFAuthenticationManager.isTransientError(error) else {
                    completion()
                    return
                }
                self.logout(initiatedBy: .server) {
                    completion()
                }
            default:
                completion()
                break
            }
        }
    }

    /// A network or server failure says nothing about the credentials. The session stays and the next attempt retries.
    static func isTransientError(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }
        if let requestError = error as? RequestError {
            switch requestError {
            case .serverBusy:
                return true
            case .http(let statusCode):
                return statusCode == 429 || statusCode >= 500
            default:
                return false
            }
        }
        return (error as NSError).domain == NSURLErrorDomain
    }

    // MARK: Logout
    
    /// Logs out any authenticated user via API call and clears out any associated cookies and cache
    /// - Parameters:
    ///   - logoutInitiator: Initiator of the logout
    ///   - completion: Completion handler once logout is done
    public func logout(initiatedBy logoutInitiator: LogoutInitiator, authInstrument: InstrumentImpl?, completion: @escaping () -> Void = {}) {
        delegate?.authenticationManagerWillLogOut {
            if logoutInitiator == .app || logoutInitiator == .server {
                self.isUserUnawareOfLogout = true
            }
            let postDidLogOutNotification = {
                NotificationCenter.default.post(name: WMFAuthenticationManager.didLogOutNotification, object: nil)
            }
            
            if self.isUserUnawareOfLogout && self.backgroundAuthInstrument == nil {
                // Instrument a background logout attempt
                self.backgroundAuthInstrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-authentication")
                    .setDefaultActionSource("background_logout")
                    .startFunnel(name: "logout_account")
                self.backgroundAuthInstrument?.submitInteraction(action: "start")
            } else if self.isUserUnawareOfLogout && self.backgroundAuthInstrument != nil {
                self.backgroundAuthInstrument?.setDefaultActionSource("background_logout")
            }
            
            guard let loginSiteURL = self.loginSiteURL else {
                
                if self.isUserUnawareOfLogout {
                    self.backgroundAuthInstrument?.submitInteraction(action: "error", actionContext: ["validation_error": "missing_loginSiteURL"])
                    self.backgroundAuthInstrument = nil
                } else {
                    authInstrument?.submitInteraction(action: "error", actionContext: ["validation_error": "missing_loginSiteURL"])
                }
                
                self.reset()
                completion()
                postDidLogOutNotification()
                return
            }
            
            self.accountLoginLogoutFetcher.logout(loginSiteURL: loginSiteURL, reattemptOn401Response: false) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        
                        if self.isUserUnawareOfLogout {
                            self.backgroundAuthInstrument?.submitInteraction(action: "error", actionContext: ["code": error.logDescription])
                            self.backgroundAuthInstrument = nil
                        } else {
                            authInstrument?.submitInteraction(action: "error", actionContext: ["code": error.logDescription])
                        }
                        
                        // ...but if "action=logout" fails we *still* want to clear local login settings, which still effectively logs the user out.
                        DDLogError("Failed to log out, delete login tokens and other browser cookies: \(error)")
                        self.reset()
                        completion()
                        postDidLogOutNotification()
                        return
                    }
                    
                    if self.isUserUnawareOfLogout {
                        self.backgroundAuthInstrument?.submitInteraction(action: "success")
                        self.backgroundAuthInstrument = nil
                    } else {
                        authInstrument?.submitInteraction(action: "success")
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
    
    // Use to call from Objective-C
    @objc(logoutInitiatedBy:completion:)
    public func logout(initiatedBy logoutInitiator: LogoutInitiator, completion: @escaping () -> Void = {}) {
        self.logout(initiatedBy: logoutInitiator, authInstrument: nil, completion: completion)
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
        
        guard let langController = notification.object as? MWKLanguageLinkController, langController.appLanguage != nil else {
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
        resetUserCache()

        session.removeAllCookies()
        
        delegate?.authenticationManagerDidReset()
        
        // Reset so can show for next logged in user.
        UserDefaults.standard.wmf_setDidShowEnableReadingListSyncPanel(false)
        UserDefaults.standard.wmf_setDidShowSyncEnabledPanel(false)
    }
}

extension WMFAuthenticationManager {
    /// Empties the user cache and starts a new generation. A user fetch in flight stays in
    /// `userFetchTasks`: its generation no longer matches, so it does not fill the cache and later
    /// callers do not wait for it.
    func resetUserCache() {
        currentUserCache = [:]
        userCacheGeneration += 1
    }
}

/// Resumes a continuation once, for the first of several tasks that finishes.
@MainActor
private final class OnceContinuation {
    var continuation: CheckedContinuation<Bool, Never>?

    func resume(returning value: Bool) {
        continuation?.resume(returning: value)
        continuation = nil
    }
}
