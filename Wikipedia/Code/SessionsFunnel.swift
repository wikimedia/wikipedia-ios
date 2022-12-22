// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSessions

@objc final class SessionsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = SessionsFunnel()
    
    // MARK: ArticleViewController Load Time Measurement Properties
    private var pageLoadStartTime: CFTimeInterval?
    private var pageLoadMin: Double?
    private var pageLoadMax: Double?
    private var pageLoadTimes: [Double] = []
    private var pageLoadAverage: Double?
    
    private override init() {
        super.init(schema: "MobileWikiAppiOSSessions", version: 24181799)
    }
    
    private enum Action: String {
        case sessionStart = "session_start"
        case sessionEnd = "session_end"
    }
    
    private func event(category: EventLoggingCategory, label: EventLoggingLabel?, action: Action, measure: Double? = nil) -> [String: Any] {
        let category = category.rawValue
        let action = action.rawValue
        
        var event: [String: Any] = ["category": category, "action": action, "primary_language": primaryLanguage(), "is_anon": isAnon]
        
        if let label = label?.rawValue {
            event["label"] = label
        }
        if let measure = measure {
            event["measure_time"] = Int(round(measure))
        }
        
        if let pageLoadMin {
            event["page_load_latency_min"] = Int(round(pageLoadMin))
        }
        
        if let pageLoadMax {
            event["page_load_latency_max"] = Int(round(pageLoadMax))
        }
        
        if let pageLoadAverage {
            event["page_load_latency_average"] = Int(round(pageLoadAverage))
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
        resetPageLoadMetrics()
        EventLoggingService.shared?.resetSession()
    }
    
    @objc public func logSessionEnd() {
        guard let sessionStartDate = EventLoggingService.shared?.sessionStartDate else {
            assertionFailure("Session start date cannot be nil")
            return
        }
        
        calculatePageLoadMetrics()
        
        log(event(category: .unknown, label: nil, action: .sessionEnd, measure: fabs(sessionStartDate.timeIntervalSinceNow)))
    }
    
    // MARK: ArticleViewController Load Time Measurement Helpers
    
    func setPageLoadStartTime() {
        assert(Thread.isMainThread)
        
        pageLoadStartTime = CACurrentMediaTime()
    }
    
    func clearPageLoadStartTime() {
        assert(Thread.isMainThread)
        
        pageLoadStartTime = nil
    }
    
    func endPageLoadStartTime() {
        assert(Thread.isMainThread)
        
        guard let pageLoadStartTime else {
            return
        }
        
        let milliseconds = (CACurrentMediaTime() - pageLoadStartTime) * 1000
        
        guard milliseconds > 0 else {
            return
        }
        
        pageLoadTimes.append(milliseconds)
    }
    
    private func calculatePageLoadMetrics() {
        assert(Thread.isMainThread)
        
        guard !pageLoadTimes.isEmpty else {
            return
        }
        
        pageLoadMax = pageLoadTimes.max()
        pageLoadMin = pageLoadTimes.min()
        
        let totalLoadTimes = pageLoadTimes.reduce(0, +)
        pageLoadAverage = totalLoadTimes / Double(pageLoadTimes.count)
    }
    
    private func resetPageLoadMetrics() {
        assert(Thread.isMainThread)
        
        pageLoadStartTime = nil
        pageLoadMin = nil
        pageLoadMax = nil
        pageLoadTimes.removeAll()
        pageLoadAverage = nil
    }
    
}
