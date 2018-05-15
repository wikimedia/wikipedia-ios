// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSessions

@objc(SessionsFunnel)
class SessionsFunnel: EventLoggingFunnel {
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
        let appInstallID = wmf_appInstallID()
        let category = category.rawValue
        let action = action.rawValue
        let isAnon = !WMFAuthenticationManager.sharedInstance.isLoggedIn
        let timestamp = DateFormatter.wmf_iso8601().string(from: Date())
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
    
    @objc public func logSessionStart() {
        log(event(category: .feed, label: nil, action: .sessionStart)) // TODO: can we know where (screen) we start a new session
    }
    
    @objc public func logSessionEnd(timeElapsed: Double) {
        log(event(category: .feed, label: nil, action: .sessionEnd, measure: timeElapsed)) // TODO: can we know where (screen) we end a new session
    }
    
}
