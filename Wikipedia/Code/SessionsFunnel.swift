// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSessions

@objc class SessionsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = SessionsFunnel()
    
    override init() {
        super.init(schema: "MobileWikiAppiOSSessions", version: 18047432)
    }
    
    private enum Action: String {
        case sessionStart = "session_start"
        case sessionEnd = "session_end"
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Double? = nil) -> Dictionary<String, Any> {
        guard category != .undefined else {
            assertionFailure("category cannot be undefined")
            return [:]
        }
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
        log(event(category: .feed, label: nil, action: .sessionStart)) // TODO: change category to .unknown when schema is updated
    }
    
    private func resetSession() {
        UserDefaults.wmf_userDefaults().wmf_resetSessionID()
        UserDefaults.wmf_userDefaults().wmf_sessionStartDate = Date()
    }
    
    @objc public func logSessionEnd() {
        guard let sessionStartDate = UserDefaults.wmf_userDefaults().wmf_sessionStartDate else {
            assertionFailure("Session start date cannot be nil")
            return
        }
        log(event(category: .feed, label: nil, action: .sessionEnd, measure: fabs(sessionStartDate.timeIntervalSinceNow))) // TODO: change category to .unknown when schema is updated
    }
    
}
