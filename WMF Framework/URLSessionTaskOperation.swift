import Foundation

class URLSessionTaskOperation: AsyncOperation {
    private let task: URLSessionTask
    private var observation: NSKeyValueObservation?

    init(task: URLSessionTask) {
        self.task = task
        super.init()
        if task.priority == 0 {
            queuePriority = .veryLow
        } else if task.priority <= URLSessionTask.lowPriority {
            queuePriority = .low
        } else if task.priority <= URLSessionTask.defaultPriority {
            queuePriority = .normal
        } else if task.priority <= URLSessionTask.highPriority {
            queuePriority = .high
        } else {
            queuePriority = .veryHigh
        }
    }

    deinit {
        observation?.invalidate()
        observation = nil
    }
    
    override func execute() {
        observation = task.observe(\.state, changeHandler: { [weak self] (task, change) in
            switch task.state {
            case .completed:
                self?.observation?.invalidate()
                self?.observation = nil
                self?.finish()
            default:
                break
            }
        })
        task.resume()
    }
}
