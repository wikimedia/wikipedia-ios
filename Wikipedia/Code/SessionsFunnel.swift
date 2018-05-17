// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSessions

@objc final class SessionsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = SessionsFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSSessions", version: 18050320)
    }
    
    private enum Action: String {
        case sessionStart = "session_start"
        case sessionEnd = "session_end"
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Double? = nil) -> Dictionary<String, Any> {
        let category = category.rawValue
        let action = action.rawValue
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let primaryLanguage = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode ?? "en"
        
        var event: [String: Any] = ["category": category, "action": action, "primary_language": primaryLanguage, "is_anon": isAnon]
        
        if let label = label {
            event["label"] = label.rawValue
        }
        if let measure = measure {
            event["measure"] = measure
        }
        
        return event
    }
    
    override func preprocessData(_ eventData: [AnyHashable: Any]) -> [AnyHashable: Any] {
        return wholeEvent(with: eventData)
    }
    
    @objc public func logSessionStart() {
        resetSession()
        log(event(category: .unknown, label: nil, action: .sessionStart))
    }
    
    private func resetSession() {
        KeychainCredentialsManager.shared.resetSessionID()
        UserDefaults.wmf_userDefaults().wmf_sessionStartDate = Date()
    }
    
    @objc public func logSessionEnd() {
        guard let sessionStartDate = UserDefaults.wmf_userDefaults().wmf_sessionStartDate else {
            assertionFailure("Session start date cannot be nil")
            return
        }
        log(event(category: .unknown, label: nil, action: .sessionEnd, measure: fabs(sessionStartDate.timeIntervalSinceNow)))
    }
    
}
