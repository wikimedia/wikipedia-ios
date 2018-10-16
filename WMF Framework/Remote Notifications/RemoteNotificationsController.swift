@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController

    @objc public required init(with session: Session) {
        operationsController = RemoteNotificationsOperationsController(with: session)
        super.init()
    }
}

extension RemoteNotificationsController: PeriodicWorker {
    public func doPeriodicWork(_ completion: @escaping () -> Void) {
        operationsController.doPeriodicWork(completion)
    }
}

extension RemoteNotificationsController: BackgroundFetcher {
    public func performBackgroundFetch(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        operationsController.performBackgroundFetch(completion)
    }
}
