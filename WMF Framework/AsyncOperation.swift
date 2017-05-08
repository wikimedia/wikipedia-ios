// via https://github.com/barbaramartina/swift-operation-queues/blob/master/operationqueues/MyAsynchronousOperation.swift

@objc(WMFAsyncOperation) open class AsyncOperation: Operation {
    enum State {
        case ready, executing, finished
        func keyPath() -> String {
            switch self {
            case .ready:
                return "isReady"
            case .executing:
                return "isExecuting"
            case .finished:
                return "isFinished"
            }
        }
    }
    
    // MARK: - Properties
    
    var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath())
            willChangeValue(forKey: state.keyPath())
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath())
            didChangeValue(forKey: state.keyPath())
        }
    }
    
    // From Apple Docs:
    // At no time in your start method should you ever call super. When you define a concurrent operation, you take it upon yourself to provide the same behavior that the default start method provides, which includes starting the task and generating the appropriate KVO notifications. Your start method should also check to see if the operation itself was cancelled before actually starting the task. For more information about cancellation semantics, see Responding to the Cancel Command.
    //
    open override func start() {
        if (self.isCancelled) {
            self.state = .finished // not that here we also are saying that executing value is 'false'
            // Specifically, if you manage the values for the finished and executing properties yourself (perhaps because you are implementing a concurrent operation), you must update those properties accordingly. Specifically, you must change the value returned by finished to true and the value returned by executing to false. You must make these changes even if the operation was cancelled before it started executing.
            // https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSOperation_class/#//apple_ref/doc/uid/TP40004591-RH2-SW18 Read: Responding to the Cancel Command
            
        } else {
            // if operation is cancelled or finished after processing your logic you should update the state:
            // From Apple Docs: If you replace the start method or your operation object, you must also replace the finished property and generate KVO notifications when the operation finishes executing or is cancelled.
            
            self.state = .executing;
            
            // if operation is cancelled or finished after processing your logic you should update the state:
            // From Apple Docs: If you replace the start method or your operation object, you must also replace the finished property and generate KVO notifications when the operation finishes executing or is cancelled.
        }
    }
    
    
    // MARK: - NSOperation
    
    open override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    open override var isExecuting: Bool {
        return state == .executing
    }
    
    open override var isFinished: Bool {
        return state == .finished
    }
    
    open override var isAsynchronous: Bool {
        return true
    }
    
    func finish() {
        state = .finished
    }
}

@objc(WMFAsyncBlockOperation) open class AsyncBlockOperation: AsyncOperation {
    let asyncBlock: (AsyncBlockOperation) -> Void
    
    init(asyncBlock block: @escaping (AsyncBlockOperation) -> Void) {
       asyncBlock = block
    }
    
    open override func start() {
        super.start()
        asyncBlock(self)
    }
}

