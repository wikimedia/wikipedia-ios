import Foundation

@objc(WMFEventPlatformClientWorker)
// @unchecked Sendable: NSObject subclass whose only stored state is two immutable
// references to Sendable singletons.
public final class EventPlatformClientWorker: NSObject, @unchecked Sendable {
    
    let client = EventPlatformClient.shared
    
    @objc(sharedInstance) public static let shared: EventPlatformClientWorker = {
        return EventPlatformClientWorker()
    }()
}

// MARK: PeriodicWorker

extension EventPlatformClientWorker: PeriodicWorker {
    public func doPeriodicWork(_ completion: @escaping @Sendable () -> Void) {
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
    public func performBackgroundFetch(_ completion: @escaping @Sendable (UIBackgroundFetchResult) -> Void) {
        doPeriodicWork {
            completion(.noData)
        }
    }
}


