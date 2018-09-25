@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController

    @objc public required override init() {
        operationsController = RemoteNotificationsOperationsController()
        super.init()
    }

    @objc public func start() {
        operationsController.start()
    }

    @objc public func stop() {
        operationsController.stop()
    }
}
