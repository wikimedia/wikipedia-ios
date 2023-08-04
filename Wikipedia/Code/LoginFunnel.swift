@objc final class LoginFunnel: NSObject {
    @objc public static let shared = LoginFunnel()
    
    private enum Action: String, Codable {
        case impression
        case loginStart = "login_start"
        case logout
        case loginSuccess = "login_success"
        case createAccountStart = "createaccount_start"
        case createAccountSuccess = "createaccount_success"
    }

    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .login
        let measure_time: Int?
        let action: Action?
        let label: EventLabelMEP?
        let category: EventCategoryMEP?
    }

    private func logEvent(category: EventCategoryMEP, label: EventLabelMEP?, action: Action, measure: Double? = nil) {
        let measureTime: Int?
        if let measure {
            measureTime = Int(round(measure))
        } else {
            measureTime = nil
        }
        let event = LoginFunnel.Event(measure_time: measureTime, action: action, label: label, category: category)
        EventPlatformClient.shared.submit(stream: .login, event: event)
    }

    // MARK: - Feed
    
    @objc public func logLoginImpressionInFeed() {
        logEvent(category: .feed, label: .syncEducation, action: .impression)
    }
    
    @objc public func logLoginStartInFeed() {
        logEvent(category: .feed, label: .syncEducation, action: .loginStart)
    }
    
    // MARK: - Login screen
    
    public func logSuccess(category: EventCategoryMEP?, timeElapsed: Double?) {
        logEvent(category: category ?? .login, label: nil, action: .loginSuccess, measure: timeElapsed)
    }
    
    public func logCreateAccountAttempt(category: EventCategoryMEP?) {
        logEvent(category: category ?? .login, label: nil, action: .createAccountStart)
    }
    
    public func logCreateAccountSuccess(category: EventCategoryMEP?, timeElapsed: Double?) {
        logEvent(category: category ?? .login, label: nil, action: .createAccountSuccess, measure: timeElapsed)
    }
    
    // MARK: - Diff
    
    public func logLoginStartFromDiff() {
        logEvent(category: .diff, label: nil, action: .loginStart)
    }
    
    // MARK: - Settings
    
    @objc public func logLoginStartInSettings() {
        logEvent(category: .setting, label: .login, action: .loginStart)
    }
    
    @objc public func logLogoutInSettings() {
        logEvent(category: .setting, label: .login, action: .logout)
    }
    
    // MARK: - Sync popovers
    
    public func logLoginImpressionInSyncPopover() {
        logEvent(category: .loginToSyncPopover, label: nil, action: .impression)
    }
    
    public func logLoginStartInSyncPopover() {
        logEvent(category: .loginToSyncPopover, label: nil, action: .loginStart)
    }
    
}
