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

    private func logEvent(measure: Double? = nil, completion: @escaping () -> Void) {
        let measureTime: Int?
        if let measure {
            measureTime = Int(round(measure))
        } else {
            measureTime = nil
        }

        let pageLatency = SessionData(page_load_latency_ms: Int(round(pageLoadAverage ?? Double())))

        let finalEvent = SessionsFunnel.Event(length_ms: measureTime, session_data: pageLatency)
        EventPlatformClient.shared.submit(stream: .sessions, event: finalEvent, completion: completion)
    }

    @objc public func appDidBecomeActive() {
        if EventPlatformClient.shared.needsReset() {
            logPreviousSessionEnd {
                DispatchQueue.main.async {
                    self.resetPageLoadMetrics()
                    EventPlatformClient.shared.reset()
                }
            }
            
        }
    }
    
    @objc public func appDidBackground() {
        EventPlatformClient.shared.appDidBackground()
    }
    
    @objc public func settingsLoggingToggledOn() {
        UserDefaults.standard.wmf_sendUsageReports = true
        EventPlatformClient.shared.generateSessionID()
    }
    
    @objc public func settingsLoggingToggledOff(completion: @escaping () -> Void) {
        
        logPreviousSessionEnd {
            DispatchQueue.main.async {
                self.resetPageLoadMetrics()
                EventPlatformClient.shared.reset()
                UserDefaults.standard.wmf_sendUsageReports = false
                completion()
            }
        }
    }

    /**
     * To match Android, we now log the previous Session when a new session starts
     */
    private func logPreviousSessionEnd(completion: @escaping () -> Void) {
        guard let sessionStartDate = EventPlatformClient.shared.sessionStartDate else {
            assertionFailure("Session start date cannot be nil")
            return
        }

        calculatePageLoadMetrics()
        
        // ignore time backgrounded from session time
        let compareDate = UserDefaults.standard.wmf_sessionBackgroundTimestamp ?? Date()
        let sessionSeconds = fabs(sessionStartDate.timeIntervalSince(compareDate))
        let sessionMilliseconds = sessionSeconds * 1000
        
        logEvent(measure: sessionMilliseconds) {
            UserHistoryFunnel.shared.logSnapshot()
            completion()
        }
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
