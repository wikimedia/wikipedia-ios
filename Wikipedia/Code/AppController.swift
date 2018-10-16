import Foundation
import WMF

@objc(WMFAppController) public class AppController: NSObject {
    lazy var workTimer: RepeatingTimer = {
        assert(Thread.isMainThread)
        return RepeatingTimer(30, { [weak self] in
            self?.doPeriodicWork()
        })
    }()
    
    let workerSemaphore = DispatchSemaphore(value: 1)
    let workTaskGroup = WMFTaskGroup()
    let workers = NSPointerArray.weakObjects()
    
    @objc public func start() {
        assert(Thread.isMainThread)
        workTimer.resume()
    }

    @objc public func stop() {
        assert(Thread.isMainThread)
        workTimer.pause()
    }
    
    @objc public func addWorker(_ worker: Worker) {
        workerSemaphore.wait()
        defer {
            workerSemaphore.signal()
        }
        let pointer = Unmanaged.passUnretained(worker).toOpaque()
        workers.addPointer(pointer)
    }
    
    private func enumerateWorkers<T>(_ block: (Worker, @escaping (T) -> Void) -> Void, completion:  @escaping ([T]) -> Void) {
        workerSemaphore.wait()
        defer {
            workerSemaphore.signal()
        }
        workers.compact()
        var results: [T] = []
        for object in workers.allObjects {
            guard let worker = object as? Worker else {
                continue
            }
            workTaskGroup.enter()
            block(worker, { result in
                results.append(result)
                self.workTaskGroup.leave()
            })
        }
        workTaskGroup.waitInBackgroundAndNotify(on: DispatchQueue.global(qos: .background)) {
            completion(results)
        }
    }
    
    
    @objc public func doPeriodicWork(_ completion: (() -> Void)? = nil) {
        enumerateWorkers({ (worker, completion) in
            worker.doPeriodicWork(completion)
        }) { (_) in
            completion?()
        }
    }
    
    @objc public func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        enumerateWorkers({ (worker, completion) in
            worker.doBackgroundWork(completion)
        }) { (results) in
            var combinedResult = UIBackgroundFetchResult.noData
            resultLoop: for result in results {
                switch result {
                case .failed:
                    combinedResult = .failed
                    break resultLoop
                case .newData:
                    combinedResult = .newData
                default:
                    break
                }
            }
            completion(combinedResult)
        }
    }
}
