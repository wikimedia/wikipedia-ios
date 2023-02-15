@objc final class SessionsFunnel: NSObject {
    @objc public static let shared = SessionsFunnel()
    
    // MARK: ArticleViewController Load Time Measurement Properties
    private var pageLoadStartTime: CFTimeInterval?
    private var pageLoadMin: Double?
    private var pageLoadMax: Double?
    private var pageLoadTimes: [Double] = []
    private var pageLoadAverage: Double?

    private enum Action: String, Codable {
        case sessionStart = "session_start"
        case sessionEnd = "session_end"
    }

    public struct Event: EventInterface {
        public static let schema: EventPlatformClient.Schema = .sessions
        let category: EventCategoryMEP
        let label: EventLabelMEP?
        let measure_time: Int?
        let page_load_latency_min: Int?
        let page_load_latency_max: Int?
        let page_load_latency_average: Int?
    }

    private func logEvent(category: EventCategoryMEP, label: EventLabelMEP?, action: Action?, measure: Double? = nil) {
        let event1 = SessionsFunnel.Event(
            category: category,
            label: label, measure_time: Int(round(measure ?? Double())), page_load_latency_min: Int(round(pageLoadMin ?? Double())), page_load_latency_max: Int(round(pageLoadMax ?? Double())), page_load_latency_average: Int(round(pageLoadAverage ?? Double())) )

        EventPlatformClient.shared.submit(stream: .sessions, event: event1)
    }

    @objc public func logSessionStart() {
        resetSession()
        logEvent(category: .unknown, label: nil, action: .sessionStart)
    }
    
    private func resetSession() {
        resetPageLoadMetrics()
        EventPlatformClient.shared.resetSession()
    }
    
    @objc public func logSessionEnd() {
        guard let sessionStartDate = EventPlatformClient.shared.sessionStartDate else {
            assertionFailure("Session start date cannot be nil")
            return
        }
        
        calculatePageLoadMetrics()
        
        logEvent(category: .unknown, label: nil, action: .sessionEnd, measure: fabs(sessionStartDate.timeIntervalSinceNow))
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
