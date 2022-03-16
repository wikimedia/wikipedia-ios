import Foundation

/// Retry executing a block a number of times waiting for a success or failure.
public class RetryBlockTask {

    private let queue = DispatchQueue(label: "org.wikimedia.wikipedia.RetryBlockTask")

    private var retryCount: Int
    private let retryInterval: TimeInterval
    private let block: () -> Bool
    private var completionHandler: ((Bool) -> Void)?

    /// Creates a task that will retry executing a block a number of times, completing early if the block return `true`.
    /// - Parameters:
    ///   - retryCount: Maximum number of times to execute the block. The task completes early if the block returns `true`.
    ///   - retryInterval: Time (in seconds) between block execution attempts.
    ///   - block: A block to execute, which returns `true` if completed successfully or `false` to retry. The task does not attempt to retry if `true` is returned.
    public init(retryCount: Int = 3, retryInterval: TimeInterval = 1.5, block: @escaping () -> Bool) {
        self.retryCount = retryCount
        self.retryInterval = retryInterval
        self.block = block
    }

    /// Start the task.
    /// - Parameter completionHandler: At the end of execution, returns `true` if the block has indicated it has completed successfully or `false` if not.
    public func start(completionHandler: @escaping (Bool) -> Void) {
        self.completionHandler = completionHandler
        tick()
    }

    private func tick() {
        queue.async { [weak self] in
            guard let self = self else { return }

            let success = self.block()
            if success || self.retryCount <= 1 {
                self.completionHandler?(success)
                return
            }

            self.retryCount -= 1
            self.queue.asyncAfter(deadline: .now() + self.retryInterval) { [weak self] in
                self?.tick()
            }
        }
    }

    deinit {
        completionHandler = nil
    }

}
