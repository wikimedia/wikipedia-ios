class WMFDispatchSourceTimer {
    private let source: DispatchSourceTimer
    private var delay: TimeInterval?
    private var isSet: Bool = false

    init(repeating repeatingTimeInSeconds: Int, afterDelay delay: TimeInterval? = nil) {
        self.source = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        self.source.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(repeatingTimeInSeconds))
    }

    public func start(_ handler: @escaping () -> Void) {
        assert(Thread.isMainThread, "Timer should be started on the main thread")
        guard !isSet else {
            return
        }
        isSet = true
        self.source.setEventHandler(handler: handler)
        self.source.resume()
    }

    public func suspend() {
        assert(Thread.isMainThread, "Timer should be suspended on the main thread")
        guard isSet else {
            return
        }
        isSet = false
        source.suspend()
    }
}
