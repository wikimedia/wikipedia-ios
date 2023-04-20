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
        let length_ms: Int?
        let session_data: SessionData?
    }

    public struct SessionData: Codable {
        let page_load_latency_ms: Int?
    }

    private func logEvent(measure: Double? = nil) {
        let measureTime: Int?
        if let measure {
            measureTime = Int(round(measure))
        } else {
            measureTime = nil
        }

        let pageLatency = SessionData(page_load_latency_ms: Int(round(pageLoadAverage ?? Double())))

        let finalEvent = SessionsFunnel.Event(length_ms: measureTime, session_data: pageLatency)
        EventPlatformClient.shared.submit(stream: .sessions, event: finalEvent)
    }

    @objc public func setSessionStart() {
        if UserSession.shared.hasSessionTimedOut {
            defer {
                resetSession()
            }
            logPreviousSessionEnd()
        }
    }
    
    private func resetSession() {
        resetPageLoadMetrics()
        UserSession.shared.resetSession()
        EventPlatformClient.shared.resetCaching()
    }

    @objc public func logSessionLastActivity() {
        UserSession.shared.logSessionEndTimestamp()
    }

    /**
     * To match Android, we now log the previous Session when a new session starts
     */
    @objc public func logPreviousSessionEnd() {
        guard let sessionStartDate = UserSession.shared.sessionStartDate else {
            assertionFailure("Session start date cannot be nil")
            return
        }
        
        calculatePageLoadMetrics()
        logEvent(measure: fabs(sessionStartDate.timeIntervalSinceNow))
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
