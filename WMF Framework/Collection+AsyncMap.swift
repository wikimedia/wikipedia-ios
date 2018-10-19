import Foundation

extension Collection {
    func asyncMap<R>(_ block: (Element, @escaping (R) -> Void) -> Void, completion:  @escaping ([R]) -> Void) {
        let group = DispatchGroup()
        var results: [R] = []
        for object in self {
            group.enter()
            block(object, { result in
                results.append(result)
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            completion(results)
        }
    }

    func asyncCompactMap<R>(_ block: (Element, @escaping (R?) -> Void) -> Void, completion:  @escaping ([R]) -> Void) {
        let group = DispatchGroup()
        var results: [R] = []
        for object in self {
            group.enter()
            block(object, { result in
                guard let result = result else {
                    group.leave()
                    return
                }
                results.append(result)
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            completion(results)
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
