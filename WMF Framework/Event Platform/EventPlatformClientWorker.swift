import Foundation

@objc(WMFEventPlatformClientWorker)
public class EventPlatformClientWorker: NSObject {
    
    let client = EventPlatformClient.shared
    
    @objc(sharedInstance) public static let shared: EventPlatformClientWorker = {
        return EventPlatformClientWorker()
    }()
}

// MARK: PeriodicWorker

extension EventPlatformClientWorker: PeriodicWorker {
    public func doPeriodicWork(_ completion: @escaping () -> Void) {
        guard let storageManager = self.client.storageManager else {
            return
        }
        storageManager.pruneStaleEvents(completion: {
            self.client.postAllScheduled(completion)
        })
    }
}

// MARK: BackgroundFetcher

extension EventPlatformClientWorker: BackgroundFetcher {
    public func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        doPeriodicWork {
            completion(.noData)
        }
    }
}


