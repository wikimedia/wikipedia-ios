public class RepeatingTimer {
    private let source: DispatchSourceTimer
    private let semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var isSet: Bool = true

    public init(_ intervalInSeconds: TimeInterval, afterDelay delayInSeconds: TimeInterval? = nil, leeway leewayInSeconds: TimeInterval? = nil, on queue: DispatchQueue = DispatchQueue.global(qos: .background), _ handler: @escaping () -> Void) {
        
        let interval = DispatchTimeInterval.nanoseconds(Int(intervalInSeconds * TimeInterval(NSEC_PER_SEC)))
        
        let delay: DispatchTimeInterval
        if let delayInSeconds = delayInSeconds {
            delay = DispatchTimeInterval.nanoseconds(Int(delayInSeconds * TimeInterval(NSEC_PER_SEC)))
        } else {
            delay = interval
        }
        
        let leeway: DispatchTimeInterval
        if let leewayInSeconds = leewayInSeconds {
            leeway = DispatchTimeInterval.nanoseconds(Int(leewayInSeconds * TimeInterval(NSEC_PER_SEC)))
        } else {
            leeway = DispatchTimeInterval.nanoseconds(Int(0.1 * intervalInSeconds * TimeInterval(NSEC_PER_SEC)))
        }
        
        self.source = DispatchSource.makeTimerSource(queue: queue)
        self.source.schedule(deadline: DispatchTime.now() + delay, repeating: interval, leeway: leeway)
        self.source.setEventHandler(handler: handler)
        self.source.resume()
    }
    
    public func resume() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        guard !isSet else {
            return
        }
        isSet = true
        self.source.resume()
    }

    public func pause() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        guard isSet else {
            return
        }
        isSet = false
        source.suspend()
    }
}
