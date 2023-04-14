import Foundation

@objc(WMFMetricsClientBridge)
public class MetricsClientBridge: NSObject {
    
    let client = EventPlatformClient.shared
    let session = UserSession.shared
    
    @objc(sharedInstance) public static let shared: MetricsClientBridge = {
        return MetricsClientBridge()
    }()
    
    @objc public func appInBackground() {
        session.logSessionEndTimestamp()
    }
    
    @objc public func appInForeground() {
        session.appInForeground()
    }
    
    @objc public func appWillClose() {
        session.appWillClose()
    }
    
    @objc public func reset() {
        session.reset()
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


