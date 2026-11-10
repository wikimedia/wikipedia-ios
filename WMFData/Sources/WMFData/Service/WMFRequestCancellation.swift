import Foundation

/// Holds the task of one request, so that a cancelled Swift task can stop the request.
///
/// `withTaskCancellationHandler` calls its handler from another concurrency domain. The handler
/// must therefore be Sendable, but a `WMFURLSessionDataTask` is not. A lock protects the task,
/// thus the box is safe to share. This is the reason for `@unchecked Sendable`.
///
/// The box also records a cancellation that arrives before the request starts. In that case
/// `setTask` stops the new task at once.
final class WMFRequestCancellation: @unchecked Sendable {

    private let lock = NSLock()
    private var task: WMFURLSessionDataTask?
    private var isCancelled = false

    /// Keep the task of a started request. The box stops it if the caller cancelled already.
    func setTask(_ newTask: WMFURLSessionDataTask?) {
        lock.lock()
        if isCancelled {
            lock.unlock()
            newTask?.cancel()
            return
        }
        task = newTask
        lock.unlock()
    }

    /// Stop the request. A request that starts later stops at once.
    func cancel() {
        lock.lock()
        isCancelled = true
        let taskToCancel = task
        task = nil
        lock.unlock()
        taskToCancel?.cancel()
    }
}
