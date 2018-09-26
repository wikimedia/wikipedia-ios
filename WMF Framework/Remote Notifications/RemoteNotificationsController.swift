@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController

    @objc public required init(viewContext: NSManagedObjectContext) {
        operationsController = RemoteNotificationsOperationsController(with: viewContext)
        super.init()
    }

    @objc public func start() {
        operationsController.start()
    }

    @objc public func stop() {
        operationsController.stop()
    }
}
