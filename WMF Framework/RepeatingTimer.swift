public class RepeatingTimer {
    private let source: DispatchSourceTimer
    private let semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var isSet: Bool = true

    public init(_ interval: TimeInterval, afterDelay delayInSeconds: TimeInterval = 0, on queue: DispatchQueue = DispatchQueue.global(qos: .background), _ handler: @escaping () -> Void) {
        let delay = DispatchTimeInterval.nanoseconds(Int(delayInSeconds * TimeInterval(NSEC_PER_SEC)))
        self.source = DispatchSource.makeTimerSource(queue: queue)
        self.source.schedule(deadline: DispatchTime.now() + delay, repeating: DispatchTimeInterval.nanoseconds(Int(interval * TimeInterval(NSEC_PER_SEC))))
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
