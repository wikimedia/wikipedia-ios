import Foundation

// Adapted from https://gist.github.com/calebd/93fa347397cec5f88233

@objc(WMFAsyncOperation) open class AsyncOperation: Operation {
    fileprivate enum State: Int {
        case ready
        case executing
        case finished
    }
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    private var _state = AsyncOperation.State.ready
    
    private var state: AsyncOperation.State {
        get {
            semaphore.wait()
            let state = _state
            defer {
                semaphore.signal()
            }
            return state
        }
        set {
            willChangeValue(forKey: "state")
            semaphore.wait()
            _state = newValue
            semaphore.signal()
            didChangeValue(forKey: "state")
        }
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }
    
    public final override var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    public final override var isExecuting: Bool {
        return state == .executing
    }
    
    public final override var isFinished: Bool {
        return state == .finished
    }
    
    public final override var isAsynchronous: Bool {
        return true
    }
    
    open override func start() {
        // From the docs for `start`:
        // "Your custom implementation must not call super at any time."
        
        if isCancelled {
            finish()
            return
        }
        
        state = .executing
        execute()
    }
    
    open func finish() {
        state = .finished
    }
    
    /// Subclasses must implement this to perform their work and they must not
    /// call `super`. The default implementation of this function throws an
    /// exception.
    open func execute() {
        fatalError("Subclasses must implement `execute`.")
    }
}



@objc(WMFAsyncBlockOperation) open class AsyncBlockOperation: AsyncOperation {
    let asyncBlock: (AsyncBlockOperation) -> Void
    
    init(asyncBlock block: @escaping (AsyncBlockOperation) -> Void) {
       asyncBlock = block
    }
    
    final override public func execute() {
        asyncBlock(self)
    }
}

