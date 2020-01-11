
import Foundation

struct IdentifiedTask {
    let untrackKey: String
    let task: URLSessionTask
}

protocol CacheTaskTracking: class {
    
    var groupedTasks: [String: [IdentifiedTask]] { get set }
    
    func cancelTasks(for groupKey: String)
    func untrackTask(untrackKey: String, from groupKey: String)
    func trackTask(untrackKey: String, task: URLSessionTask, to groupKey: String)
}

extension CacheTaskTracking {
    func cancelTasks(for groupKey: String) {
        if let identifiedTasks = groupedTasks[groupKey] {
            for identifiedTask in identifiedTasks {
                identifiedTask.task.cancel()
            }
        }
    }
    
    func untrackTask(untrackKey: String, from groupKey: String) {

        if let identifiedTasks = groupedTasks[groupKey] {
            groupedTasks[groupKey] = identifiedTasks.filter { $0.untrackKey == untrackKey }
        }
    }
    
    func trackTask(untrackKey: String, task: URLSessionTask, to groupKey: String) {
        let identifiedTask = IdentifiedTask(untrackKey: untrackKey, task: task)
        groupedTasks[groupKey]?.append(identifiedTask)
    }
}
