// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSLoginAction

@objc final class LoginFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = LoginFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSLoginAction", version: 18121305)
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
        let category = category.rawValue
        let action = action.rawValue
        
        var event: [String: Any] = ["category": category, "action": action, "primary_language": primaryLanguage(), "is_anon": isAnon]
        if let label = label?.rawValue {
            event["label"] = label
        }
        if let measure = measure {
            event["measure_time"] = Int(round(measure))
        }
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
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
