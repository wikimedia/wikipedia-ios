public class RepeatingTimer {
    private let source: DispatchSourceTimer
    private let semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var isSet: Bool = true

    public init(_ repeatingTimeInSeconds: Int, afterDelay delayInSeconds: TimeInterval = 0, on queue: DispatchQueue = DispatchQueue.global(qos: .background), _ handler: @escaping () -> Void) {
        let delay = DispatchTimeInterval.milliseconds(Int(delayInSeconds*1000))
        self.source = DispatchSource.makeTimerSource(queue: queue)
        self.source.schedule(deadline: DispatchTime.now() + delay, repeating: DispatchTimeInterval.seconds(repeatingTimeInSeconds))
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
