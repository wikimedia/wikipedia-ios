import Foundation

@objc(WMFBackgroundFetcher) public protocol BackgroundFetcher: NSObjectProtocol {
    // Completion is @Sendable: fetchers finish on their own queues.
    func performBackgroundFetch(_ completion: @escaping @Sendable (UIBackgroundFetchResult) -> Void)
}

@objc(WMFBackgroundFetcherController) public class BackgroundFetcherController: WorkerController {
    var fetchers = [BackgroundFetcher]()
    
    @objc public func add(_ worker: BackgroundFetcher) {
        fetchers.append(worker)
    }
    
    @objc public func performBackgroundFetch(_ completion: @escaping @Sendable (UIBackgroundFetchResult) -> Void) {
        let identifier = UUID().uuidString
        delegate?.workerControllerWillStart(self, workWithIdentifier: identifier)
        fetchers.asyncMap({ (fetcher, completion) in
            fetcher.performBackgroundFetch(completion)
        }) { [weak self] (results) in
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
            guard let strongSelf = self else {
                return
            }
            strongSelf.delegate?.workerControllerDidEnd(strongSelf, workWithIdentifier: identifier)
        }
    }
}
