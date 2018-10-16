@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController

    @objc public required init(with session: Session) {
        operationsController = RemoteNotificationsOperationsController(with: session)
        super.init()
    }
}

extension RemoteNotificationsController: Worker {
    public func doPeriodicWork(_ completion: @escaping () -> Void) {
        operationsController.doPeriodicWork(completion)
    }
    
    public func doBackgroundWork(_ completion: @escaping (UIBackgroundFetchResult) -> Void) {
        operationsController.doBackgroundWork(completion)
    }
}
