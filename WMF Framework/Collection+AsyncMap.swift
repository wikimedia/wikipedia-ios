import Foundation

public extension Sequence {
    func asyncMapToDictionary<K,V>( block: (Element, @escaping (K?, V?) -> Void) -> Void, queue: DispatchQueue = DispatchQueue.global(qos: .default), completion:  @escaping ([K: V]) -> Void) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        var results = [K: V](minimumCapacity: underestimatedCount)
        for object in self {
            group.enter()
            block(object, { (key, value) in
                defer {
                    group.leave()
                }
                guard let key = key, let value = value else {
                    return
                }
                semaphore.wait()
                results[key] = value
                semaphore.signal()
            })
        }
        group.notify(queue: queue) {
            completion(results)
        }
    }
}

public extension Collection {
    func asyncMap<R>(_ block: (Element, @escaping (R) -> Void) -> Void, completion:  @escaping ([R]) -> Void) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        var results = [R?](repeating: nil, count: count)
        for (index, object) in self.enumerated() {
            group.enter()
            block(object, { result in
                semaphore.wait()
                results[index] = result
                semaphore.signal()
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            completion(results as! [R])
        }
    }

    func asyncCompactMap<R>(_ block: (Element, @escaping (R?) -> Void) -> Void, completion:  @escaping ([R]) -> Void) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        var results = [R?](repeating: nil, count: count)
        for (index, object) in self.enumerated() {
            group.enter()
            block(object, { result in
                guard let result = result else {
                    group.leave()
                    return
                }
                semaphore.wait()
                results[index] = result
                semaphore.signal()
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            completion(results.compactMap {$0})
        }
    }
    
    func asyncForEach(_ block: (Element, @escaping () -> Void) -> Void, completion:  @escaping () -> Void) {
        let group = DispatchGroup()
        for object in self {
            group.enter()
            block(object, {
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            completion()
        }
    }
}
