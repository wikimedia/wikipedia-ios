import Foundation

public extension Collection {
    func asyncMap<R>(_ block: (Element, @escaping (R) -> Void) -> Void, completion:  @escaping ([R]) -> Void) {
        let group = DispatchGroup()
        var results = [R?](repeating: nil, count: count)
        for (index, object) in self.enumerated() {
            group.enter()
            block(object, { result in
                results[index] = result
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            completion(results as! [R])
        }
    }

    func asyncCompactMap<R>(_ block: (Element, @escaping (R?) -> Void) -> Void, completion:  @escaping ([R]) -> Void) {
        let group = DispatchGroup()
        var results = [R?](repeating: nil, count: count)
        for (index, object) in self.enumerated() {
            group.enter()
            block(object, { result in
                guard let result = result else {
                    group.leave()
                    return
                }
                results[index] = result
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            completion(results.compactMap{$0})
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
