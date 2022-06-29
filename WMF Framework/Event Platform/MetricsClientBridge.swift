import Foundation

@objc(WMFMetricsClientBridge)
public class MetricsClientBridge: NSObject {
    
    let client = EventPlatformClient.shared
    
    @objc(sharedInstance) public static let shared: MetricsClientBridge = {
        return MetricsClientBridge()
    }()
    
    @objc public func appInBackground() {
        client.appInBackground()
    }
    
    @objc public func appInForeground() {
        client.appInForeground()
    }
    
    @objc public func appWillClose() {
        client.appWillClose()
    }
    
    @objc public func reset() {
        client.reset()
    }
    
}

// MARK: PeriodicWorker

extension MetricsClientBridge: PeriodicWorker {
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

extension MetricsClientBridge: BackgroundFetcher {
    public func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        doPeriodicWork {
            completion(.noData)
        }
    }
}


