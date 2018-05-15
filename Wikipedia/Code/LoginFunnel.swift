// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSLoginAction

@objc class LoginFunnel: EventLoggingFunnel {
    override init() {
        super.init(schema: "MobileWikiAppiOSLoginAction", version: 17990227)
    }
    
    private enum Action: String {
        case impression
        case loginStart = "login_start"
        case logout
        case loginSuccess = "login_success"
        case createAccountStart = "createaccount_start"
        case createAccountSuccess = "createaccount_success"
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Double? = nil) -> Dictionary<String, Any> {
        guard category != .undefined else {
            assertionFailure("category cannot be undefined")
            return [:]
        }
        let appInstallID = wmf_appInstallID()
        let category = category.rawValue
        let action = action.rawValue
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let timestamp = String(describing: NSDate()).wmf_iso8601Date
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        let sessionID = wmf_sessionID()
        
        var event: [String: Any] = ["app_install_id": appInstallID, "category": category, "action": action, "primary_language": primaryLanguage, "is_anon": isAnon, "event_dt": timestamp, "session_id": sessionID]
        
        if let label = label {
            event["label"] = label.rawValue
        }
        
        if let measure = measure {
            event["measure"] = measure
        }
        
        return event
    }
    
    // MARK: - Feed
    
    @objc public func logLoginImpressionInFeed() {
        log(event(category: .feed, label: .syncEducation, action: .impression))
    }
    
    @objc public func logLoginStartInFeed() {
        log(event(category: .feed, label: .syncEducation, action: .loginStart))
    }
    
    // MARK: - Login screen
    
    public func logSuccess(timeElapsed: Double?) {
        log(event(category: .login, label: nil, action: .loginSuccess, measure: timeElapsed))
    }
    
    @objc public func logCreateAccountAttempt() {
        log(event(category: .login, label: nil, action: .createAccountStart))
    }
    
    public func logCreateAccountSuccess(timeElapsed: Double?) {
        log(event(category: .login, label: nil, action: .createAccountSuccess, measure: timeElapsed))
    }
    
    // MARK: - Settings
    
    @objc public func logLoginStartInSettings() {
        log(event(category: .setting, label: .login, action: .loginStart))
    }
    
    @objc public func logLogoutInSettings() {
        log(event(category: .setting, label: .login, action: .logout))
    }
    
    // MARK: - Sync popovers
    
    public func logLoginImpressionInSyncPopover() {
        log(event(category: .loginToSyncPopover, label: nil, action: .impression))
    }
    
    public func logLoginStartInSyncPopover() {
        log(event(category: .loginToSyncPopover, label: nil, action: .loginStart))
    }
    
}
