import Foundation

enum AsyncOperationError: Error {
    case cancelled
}

// Adapted from https://gist.github.com/calebd/93fa347397cec5f88233

@objc(WMFAsyncOperation) open class AsyncOperation: Operation {
    
    // MARK: - Operation State

    fileprivate let semaphore = DispatchSemaphore(value: 1) // Ensures `state` is thread-safe
    
    @objc public enum State: Int {
        case ready
        case executing
        case finished
        
        var affectedKeyPath: KeyPath<AsyncOperation, Bool> {
            switch self {
            case .ready:
                return \.isReady
            case .executing:
                return \.isExecuting
            case .finished:
                return \.isFinished
            }
        }
    }
    
    public var error: Error?
    
    fileprivate var _state = AsyncOperation.State.ready
    
    @objc public var state: AsyncOperation.State {
        get {
            semaphore.wait()
            let state = _state
            defer {
                semaphore.signal()
            }
            return state
        }
        set {
            willChangeValue(for: \.state)
            let affectedKeyPaths = [_state.affectedKeyPath, newValue.affectedKeyPath]
            for keyPath in affectedKeyPaths {
                willChangeValue(for: keyPath)
            }
            semaphore.wait()
            _state = newValue
            semaphore.signal()
            didChangeValue(for: \.state)
            for keyPath in affectedKeyPaths {
                didChangeValue(for: keyPath)
            }
        }
    }
    
    // MARK: - Operation subclass requirements
    
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
            finish(with: AsyncOperationError.cancelled)
            return
        }

        state = .executing
        execute()
    }
    
    // MARK: - Custom behavior
    
    @objc open func finish() {
        state = .finished
    }
    
    @objc open func finish(with error: Error) {
        self.error = error
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
    
    @objc init(asyncBlock block: @escaping (AsyncBlockOperation) -> Void) {
       asyncBlock = block
    }
    
    final override public func execute() {
        asyncBlock(self)
    }
}

