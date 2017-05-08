// via https://github.com/barbaramartina/swift-operation-queues/blob/master/operationqueues/MyAsynchronousOperation.swift

//
//  This is an implemenation of an asynchronous operation subclass.
//  BASED ON: ConcurrentOperation.swift: Created by Caleb Davenport on 7/7/14.
//  The original implementation has been completed with specific links to the documentation in order
//  to make sure all the guidelines for subclassing an async operation are followed and learn more about
//  how it should be correctly implemented, as well as having links available to help our memory to remember all
//  the requirements a subclass of NSOperation should fullfit when it runs asynchronously.
//
//  From Apple Docs:
//  If you are creating a concurrent operation, you need to override the following methods and properties at a minimum:
//  * start
//  * asynchronous
//  * executing
//  * finished
//
//  https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSOperation_class/#//apple_ref/occ/instp/NSOperation/ready
//
//  Notes from Apple Docs:
//  When you call the start method of an asynchronous operation, that method may return before the corresponding task is completed. An asynchronous operation object is responsible for scheduling its task on a separate thread. The operation could do that by starting a new thread directly, by calling an asynchronous method, or by submitting a block to a dispatch queue for execution. It does not actually matter if the operation is ongoing when control returns to the caller, only that it could be ongoing.
//
//  When you add an operation to an operation queue, the queue ignores the value of the asynchronous property and always calls the start method from a separate thread. Therefore, if you always run operations by adding them to an operation queue, there is no reason to make them asynchronous.
//
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

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

