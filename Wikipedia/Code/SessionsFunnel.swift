// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSessions

@objc final class SessionsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = SessionsFunnel()
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSSessions", version: 18121261)
    }
    
    private enum Action: String {
        case sessionStart = "session_start"
        case sessionEnd = "session_end"
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
    
    @objc public func logSessionStart() {
        resetSession()
        log(event(category: .unknown, label: nil, action: .sessionStart))
    }
    
    private func resetSession() {
        EventLoggingService.shared?.resetSession()
    }
    
    @objc public func logSessionEnd() {
        guard let sessionStartDate = EventLoggingService.shared?.sessionStartDate else {
            assertionFailure("Session start date cannot be nil")
            return
        }
        log(event(category: .unknown, label: nil, action: .sessionEnd, measure: fabs(sessionStartDate.timeIntervalSinceNow)))
    }
    
}
