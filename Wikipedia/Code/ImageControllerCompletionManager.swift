import Foundation

internal struct ImageControllerPermanentCacheCompletion {
    let success: () -> Void
    let failure: (Error) -> Void
}

internal struct ImageControllerDataCompletion {
    let success: (Data, URLResponse) -> Void
    let failure: (Error) -> Void
}

internal class ImageControllerCompletionManager<T> {
    var completions: [String: [String: T]] = [:]
    var tasks: [String: [String:URLSessionTask]] = [:]
    let queue = DispatchQueue(label: "ImageControllerCompletionManager-" + UUID().uuidString)
    
    func add(_ completion: T, priority: Float, forGroup group: String, identifier: String, token: String, isFirstCompletion:@escaping (Bool) -> Void) {
        queue.async {
            var completionsForKey = self.completions[identifier] ?? [:]
            let isFirst = completionsForKey.isEmpty
            if !isFirst {
                self.tasks[group]?[identifier]?.priority = priority
            }
            completionsForKey[token] = completion
            self.completions[identifier] = completionsForKey
            isFirstCompletion(isFirst)
        }
    }
    
    func add(_ completion: T, priority: Float, forIdentifier identifier: String, token: String, isFirstCompletion:@escaping (Bool) -> Void) {
        return add(completion, priority: priority, forGroup: "", identifier: identifier, token: token, isFirstCompletion: isFirstCompletion)
    }
    
    func add(_ task: URLSessionTask, forGroup group: String, identifier: String) {
        queue.async {
            var groupTasks = self.tasks[group] ?? [:]
            groupTasks[identifier] = task
            self.tasks[group] = groupTasks
        }
    }
    
    func add(_ task: URLSessionTask, forIdentifier identifier: String) {
        add(task, forGroup: "", identifier: identifier)
    }
    
    
    func cancel(group: String, identifier: String, token: String) {
        queue.async {
            guard var tasks = self.tasks[group], let task = tasks[identifier], var completions = self.completions[identifier] else {
                return
            }
            completions.removeValue(forKey: token)
            if completions.isEmpty {
                self.completions.removeValue(forKey: identifier)
                task.cancel()
                tasks.removeValue(forKey: identifier)
                self.tasks[group] = tasks
            } else {
                self.completions[identifier] = completions
            }
        }
    }
    
    func cancel(group: String, identifier: String) {
        queue.async {
            guard var tasks = self.tasks[group], let task = tasks[identifier] else {
                return
            }
            self.completions.removeValue(forKey: identifier)
            task.cancel()
            tasks.removeValue(forKey: identifier)
            self.tasks[group] = tasks
        }
    }
    
    func cancel(_ identifier: String) {
        cancel(group: "", identifier: identifier)
    }
    
    func cancel(_ identifier: String, token: String) {
        cancel(group: "", identifier: identifier, token: token)
    }
    
    func cancel(group: String) {
        queue.async {
            guard let tasks = self.tasks[group] else {
                return
            }
            for (identifier, task) in tasks {
                self.completions.removeValue(forKey: identifier)
                task.cancel()
            }
        }
    }
    
    func cancelAll() {
        queue.async {
            for group in self.tasks.keys {
                self.cancel(group: group)
            }
        }
    }
    
    func complete(_ group: String, identifier: String, enumerator: @escaping (T) -> Void) {
        queue.async {
            guard let completionsForKey = self.completions[identifier] else {
                return
            }
            for (_, completion) in completionsForKey {
                enumerator(completion)
            }
            self.completions.removeValue(forKey: identifier)
            self.tasks[group]?.removeValue(forKey: identifier)
        }
    }
    
    func complete(_ identifier: String, enumerator: @escaping (T) -> Void) {
        complete("", identifier: identifier, enumerator: enumerator)
    }
}
